#!/usr/bin/env python3
"""Build the offline model pack: text embeddings (raw fp16), thresholds, manifest with checksums.
Usage: make_pack.py EXP_DIR DATA_MANIFEST.json OUT_DIR RELEASE_BASE_URL"""
import hashlib
import json
import os
import shutil
import sys

import numpy as np

exp, man_path, out, base = sys.argv[1:5]
os.makedirs(out, exist_ok=True)
text = np.load(f"{exp}/text_embeddings_fp16.npy").astype(np.float16)
species = json.load(open(f"{exp}/species.json"))
n, dim = text.shape
assert n == len(species), (n, len(species))
text.astype("<f2").tofile(f"{out}/text_embeddings_fp16.bin")
json.dump(species, open(f"{out}/species.json", "w"), ensure_ascii=False)
shutil.copy(f"{exp}/bioclip2_image_int8.onnx", f"{out}/bioclip2_image_int8.onnx")

# thresholds from the bake-off embeddings of the compressed model
z = np.load(f"{exp}/emb-bioclip2_int8.npz")
idx = {int(i): k for k, i in enumerate(z["ids"])}
X = z["feat"].astype(np.float32)
T = text.astype(np.float32)
entries = json.load(open(man_path))
inl = [e for e in entries if e["group"] == "species" and e["core20"] and e["id"] in idx and e["species"] in species]
ood = [e for e in entries if e["group"] != "species" and e["id"] in idx]
S = X[[idx[e["id"]] for e in inl]] @ T.T
So = X[[idx[e["id"]] for e in ood]] @ T.T
mx = S.max(1)
accept = float(np.percentile(mx, 10))
ood_acc = float((So.max(1) >= accept).mean())
P = np.exp(100 * (S - S.max(1, keepdims=True)))
P /= P.sum(1, keepdims=True)
top1 = P.argmax(1)
correct = np.array([species[t] == e["species"] for t, e in zip(top1, inl)])
pmax = P.max(1)
conf_p, conf_prec, conf_cov = 0.5, None, None
for p in np.linspace(0.3, 0.95, 66):
    m = (pmax >= p) & (mx >= accept)
    if m.sum() >= 30 and correct[m].mean() >= 0.9:
        conf_p, conf_prec, conf_cov = float(p), float(correct[m].mean()), float(m.mean())
        break
files = []
for name in ("bioclip2_image_int8.onnx", "text_embeddings_fp16.bin", "species.json"):
    path = f"{out}/{name}"
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    files.append({"name": name, "url": f"{base}/{name}", "bytes": os.path.getsize(path), "sha256": h.hexdigest()})
manifest = {
    "version": 1, "model_id": "bioclip2-int8-v1", "license": "MIT (BioCLIP 2, Imageomics Institute)",
    "input": "image", "output": "emb", "input_size": 224, "embedding_dim": int(dim), "species_count": int(n),
    "mean": [0.48145466, 0.4578275, 0.40821073], "std": [0.26862954, 0.26130258, 0.27577711],
    "logit_scale": 100.0, "accept_cosine": round(accept, 4), "confident_prob": round(conf_p, 3),
    "files": files,
    "bakeoff": {"in_list_images": len(inl), "ood_images": len(ood), "ood_accepted_at_threshold": round(ood_acc, 3),
                "confident_precision": conf_prec, "confident_coverage": conf_cov,
                "top1": round(float(correct.mean()), 3)},
}
json.dump(manifest, open(f"{out}/model_manifest.json", "w"), indent=1)
print(json.dumps({k: v for k, v in manifest.items() if k != "files"}, indent=1))
for f in files:
    print(f["name"], f["bytes"], f["sha256"][:12])
