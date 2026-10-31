#!/usr/bin/env python3
"""Export a BioCLIP image tower to ONNX, compress it, check parity against PyTorch, time it, and embed the
bake-off images with each variant so evaluate.py can score the compressed model.
Usage: export_onnx.py MODEL DATA_DIR OUT_DIR FULL_VARIANTS   (MODEL: bioclip|bioclip2; FULL_VARIANTS e.g. fp32,int8)"""
import json
import os
import sys
import time

import numpy as np
import onnx
import onnxruntime as ort
import open_clip
import torch
from onnxruntime.quantization import QuantType, quantize_dynamic
from PIL import Image

key, data, out, full = sys.argv[1], sys.argv[2], sys.argv[3], [v for v in sys.argv[4].split(",") if v]
hub = {"bioclip": "hf-hub:imageomics/bioclip", "bioclip2": "hf-hub:imageomics/bioclip-2"}[key]
os.makedirs(out, exist_ok=True)
torch.set_num_threads(2)
rep = {"model": key}
m, _, pp = open_clip.create_model_and_transforms(hub)
m.eval()
tok = open_clip.get_tokenizer(hub)
entries = json.load(open(f"{data}/manifest.json"))
species = sorted({e["species"] for e in entries if e["group"] == "species"})
sel = sorted([e for e in entries if e["group"] != "species" or e["core20"]], key=lambda e: e["id"])


def load(path):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    s = min(w, h)
    l, t = (w - s) // 2, (h - s) // 2
    return im.crop((l, t, l + s, t + s)).resize((224, 224), Image.BICUBIC)


with torch.inference_mode():
    text = torch.nn.functional.normalize(m.encode_text(tok(["a photo of %s." % s for s in species])).float(), dim=-1)
text16 = text.numpy().astype(np.float16)
np.save(f"{out}/text_embeddings_fp16.npy", text16)
json.dump(species, open(f"{out}/species.json", "w"))
tr = [str(t) for t in pp.transforms]
rep["preprocess"] = tr
rep["image_params_M"] = round(sum(p.numel() for p in m.visual.parameters()) / 1e6, 1)
rep["embedding_dim"] = int(text.shape[1])
rep["text_embeddings_bytes"] = os.path.getsize(f"{out}/text_embeddings_fp16.npy")


class Img(torch.nn.Module):
    def __init__(self, v):
        super().__init__()
        self.v = v

    def forward(self, x):
        return self.v(x)


fp32 = f"{out}/{key}_image_fp32.onnx"
dummy = torch.randn(1, 3, 224, 224)
t0 = time.time()
try:
    torch.onnx.export(Img(m.visual).eval(), dummy, fp32, opset_version=17, input_names=["image"],
                      output_names=["emb"], dynamic_axes={"image": {0: "b"}, "emb": {0: "b"}}, dynamo=False)
except TypeError:
    torch.onnx.export(Img(m.visual).eval(), dummy, fp32, opset_version=17, input_names=["image"],
                      output_names=["emb"], dynamic_axes={"image": {0: "b"}, "emb": {0: "b"}})
rep["export_seconds"] = round(time.time() - t0)
onnx.checker.check_model(fp32)
variants = {"fp32": fp32}
try:
    int8 = f"{out}/{key}_image_int8.onnx"
    quantize_dynamic(fp32, int8, weight_type=QuantType.QInt8, op_types_to_quantize=["MatMul", "Gemm"])
    variants["int8"] = int8
except Exception as ex:
    rep["int8_error"] = repr(ex)[:300]
try:
    from onnxconverter_common import float16
    f16 = f"{out}/{key}_image_fp16.onnx"
    onnx.save(float16.convert_float_to_float16(onnx.load(fp32), keep_io_types=True), f16)
    variants["fp16"] = f16
except Exception as ex:
    rep["fp16_error"] = repr(ex)[:300]
for v, p in variants.items():
    rep[f"{v}_MB"] = round((os.path.getsize(p) + (os.path.getsize(p + ".data") if os.path.exists(p + ".data") else 0)) / 1e6, 1)

# parity + timing on 48 species photos
probe = [e for e in sel if e["group"] == "species"][:48]
X = torch.stack([pp(load(e["path"])) for e in probe])
with torch.inference_mode():
    ref = torch.nn.functional.normalize(m.visual(X).float(), dim=-1).numpy()
ref_top3 = np.argsort(-(ref @ text.numpy().T), 1)[:, :3]
sess = {}
for v, p in variants.items():
    so = ort.SessionOptions()
    so.intra_op_num_threads = 1
    try:
        sess[v] = ort.InferenceSession(p, so, providers=["CPUExecutionProvider"])
    except Exception as ex:
        rep[f"{v}_load_error"] = repr(ex)[:300]
for v, s in sess.items():
    outs = []
    lat = []
    for i in range(len(probe)):
        x = X[i:i + 1].numpy()
        t0 = time.time()
        o = s.run(None, {"image": x})[0]
        lat.append(time.time() - t0)
        outs.append(o[0])
    o = np.array(outs, np.float32)
    o /= np.linalg.norm(o, axis=1, keepdims=True)
    cos = (o * ref).sum(1)
    top3 = np.argsort(-(o @ text.numpy().T), 1)[:, :3]
    rep[f"{v}_parity"] = {"cos_mean": round(float(cos.mean()), 5), "cos_min": round(float(cos.min()), 5),
                           "top1_same_as_torch": round(float(np.mean(top3[:, 0] == ref_top3[:, 0])), 3),
                           "latency_ms_1thread_median": round(1000 * float(np.median(lat[3:])))}
print(json.dumps(rep, indent=1), flush=True)

# full embeddings for evaluate.py
for v in full:
    if v not in sess:
        continue
    ids, feats, t0 = [], [], time.time()
    for i in range(0, len(sel), 16):
        chunk = sel[i:i + 16]
        imgs, good = [], []
        for e in chunk:
            try:
                imgs.append(pp(load(e["path"])))
                good.append(e["id"])
            except Exception:
                pass
        if not imgs:
            continue
        o = sess[v].run(None, {"image": torch.stack(imgs).numpy()})[0].astype(np.float32)
        o /= np.linalg.norm(o, axis=1, keepdims=True)
        feats.append(o.astype(np.float16))
        ids += good
    np.savez_compressed(f"{out}/emb-{key}_{v}.npz", ids=np.array(ids), feat=np.concatenate(feats),
                        species=np.array(species), text=text16, seconds=time.time() - t0)
    rep[f"{v}_full_embed_seconds"] = round(time.time() - t0)
json.dump(rep, open(f"{out}/export_report.json", "w"), indent=1)
# keep the pack small: drop fp32/fp16 files from the artifact when int8 exists (sizes are in the report)
for v in ("fp16",):
    if v in variants and os.path.exists(variants[v]):
        os.remove(variants[v])
