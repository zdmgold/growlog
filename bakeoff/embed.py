#!/usr/bin/env python3
"""Embed bake-off images with one model. Usage: embed.py MODEL DATA_DIR OUT.npz SUBSET
MODEL: dino | clip | bioclip | bioclip2     SUBSET: all | core20 | core8"""
import json
import sys
import time

import numpy as np
import torch
from PIL import Image

model_name, data, out, subset = sys.argv[1:5]
torch.set_num_threads(2)
entries = json.load(open(f"{data}/manifest.json"))
sel = [e for e in entries if e["group"] != "species" or subset == "all" or e.get(subset)]
sel.sort(key=lambda e: e["id"])
species = sorted({e["species"] for e in entries if e["group"] == "species"})
print(model_name, subset, "images:", len(sel), "species:", len(species), flush=True)


def load(path):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    s = min(w, h)
    l, t = (w - s) // 2, (h - s) // 2
    return im.crop((l, t, l + s, t + s)).resize((224, 224), Image.BICUBIC)


text = None
if model_name == "dino":
    from transformers import AutoModel
    m = AutoModel.from_pretrained("facebook/dinov2-small").eval()
    mean = np.array([0.485, 0.456, 0.406], np.float32)
    std = np.array([0.229, 0.224, 0.225], np.float32)

    def enc(imgs):
        a = (np.stack([np.asarray(i, np.float32) / 255.0 for i in imgs]) - mean) / std
        o = m(pixel_values=torch.from_numpy(a.transpose(0, 3, 1, 2))).last_hidden_state
        return torch.cat([o[:, 0], o[:, 1:].mean(1)], 1)
else:
    import open_clip
    spec = {"clip": ("ViT-B-32", "openai", "a photo of {}, a type of plant."),
            "bioclip": ("hf-hub:imageomics/bioclip", None, "a photo of {}."),
            "bioclip2": ("hf-hub:imageomics/bioclip-2", None, "a photo of {}.")}
    name, pre, tmpl = spec[model_name]
    if pre:
        m, _, pp = open_clip.create_model_and_transforms(name, pretrained=pre)
    else:
        m, _, pp = open_clip.create_model_and_transforms(name)
    m.eval()
    tok = open_clip.get_tokenizer(name)
    with torch.inference_mode():
        t = m.encode_text(tok([tmpl.format(s) for s in species]))
        text = torch.nn.functional.normalize(t.float(), dim=-1).numpy().astype(np.float16)

    def enc(imgs):
        return m.encode_image(torch.stack([pp(i) for i in imgs]))

feats, ids, t0 = [], [], time.time()
bs = 16
with torch.inference_mode():
    for i in range(0, len(sel), bs):
        chunk = sel[i:i + bs]
        imgs, good = [], []
        for e in chunk:
            try:
                imgs.append(load(e["path"]))
                good.append(e["id"])
            except Exception as ex:  # unreadable image
                print("skip", e["id"], ex, flush=True)
        if not imgs:
            continue
        f = torch.nn.functional.normalize(enc(imgs).float(), dim=-1).numpy()
        feats.append(f.astype(np.float16))
        ids += good
        if (i // bs) % 20 == 0:
            print(f"{i}/{len(sel)} {time.time() - t0:.0f}s", flush=True)
np.savez_compressed(out, ids=np.array(ids), feat=np.concatenate(feats), species=np.array(species),
                    text=text if text is not None else np.zeros((0,), np.float16),
                    seconds=time.time() - t0)
print("saved", out, "images", len(ids), "seconds", int(time.time() - t0))
