#!/usr/bin/env python3
"""Evaluate bake-off embeddings. Usage: evaluate.py DATA_DIR EMB_DIR OUT.md"""
import glob
import json
import os
import random
import sys

import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import roc_auc_score

DATA, EMB, OUT = sys.argv[1:4]
GATE_TOP3, GATE_OOD = 0.85, 0.30
entries = json.load(open(f"{DATA}/manifest.json"))
E = {e["id"]: e for e in entries}
models = {}
for p in sorted(glob.glob(f"{EMB}/emb-*.npz")):
    z = np.load(p, allow_pickle=False)
    nm = os.path.basename(p)[4:-4]
    models[nm] = {"idx": {int(i): k for k, i in enumerate(z["ids"])}, "X": z["feat"].astype(np.float32),
                  "species": [str(s) for s in z["species"]], "T": z["text"].astype(np.float32),
                  "secs": float(z["seconds"])}


def make_split(universe, seed=11):
    rng = random.Random(seed)
    by = {}
    for e in entries:
        if e["group"] != "species" or (universe == "core20" and not e["core20"]):
            continue
        by.setdefault(e["species"], []).append(e)
    test, train, excluded = {}, {}, []
    for sp, items in sorted(by.items()):
        n = len(items)
        if n < 12:
            excluded.append((sp, n))
            continue
        T = min(10, max(3, round(0.25 * n)))
        groups = {}
        for e in items:
            groups.setdefault(e["artist"] or "id%d" % e["id"], []).append(e)
        gl = list(groups.values())
        rng.shuffle(gl)
        t = []
        for g in gl:
            if len(t) + len(g) <= T:
                t += g
            if len(t) >= T:
                break
        if len(t) < 3:
            ids = {e["id"] for e in t}
            rest = [e for e in items if e["id"] not in ids]
            rng.shuffle(rest)
            t += rest[:3 - len(t)]
        tid = {e["id"] for e in t}
        test[sp], train[sp] = t, [e for e in items if e["id"] not in tid]
    return test, train, excluded


def topk_hits(scores, classes, truths, ks=(1, 3, 5)):
    """scores: n x C. classes: list of class names for columns. truths: list of species names."""
    order = np.argsort(-scores, axis=1)[:, :max(ks)]
    hits = {k: np.zeros(len(truths), bool) for k in ks}
    for i, tr in enumerate(truths):
        pred = [classes[j] for j in order[i]]
        for k in ks:
            hits[k][i] = tr in pred[:k]
    return hits


def summarize(hits, truths):
    r = {}
    sp = sorted(set(truths))
    for k, h in hits.items():
        r["top%d" % k] = float(h.mean())
        r["macro%d" % k] = float(np.mean([h[[t == s for t in truths]].mean() for s in sp]))
    return r


def ood_stats(in_scores, ood_scores):
    if len(in_scores) == 0 or len(ood_scores) == 0:
        return None, None
    y = np.r_[np.ones(len(in_scores)), np.zeros(len(ood_scores))]
    auc = float(roc_auc_score(y, np.r_[in_scores, ood_scores]))
    thr = np.percentile(in_scores, 10)
    return auc, float((ood_scores >= thr).mean())


def run(nm, universe, test, train, policy, k, clf):
    M = models[nm]
    def feats(items):
        pairs = [(e, M["idx"][e["id"]]) for e in items if e["id"] in M["idx"]]
        return [e for e, _ in pairs], (M["X"][[i for _, i in pairs]] if pairs else np.zeros((0, M["X"].shape[1]), np.float32))
    te_items = [e for sp in test for e in test[sp]]
    te, Xte = feats(te_items)
    if len(te) == 0:
        return None
    truths = [e["species"] for e in te]
    ood_items = [E[i] for i in M["idx"] if E[i]["group"] != "species"]
    Xood = M["X"][[M["idx"][e["id"]] for e in ood_items]] if ood_items else np.zeros((0, M["X"].shape[1]), np.float32)
    if clf == "zeroshot":
        if M["T"].shape[0] == 0:
            return None
        sps = sorted(test)
        col = [M["species"].index(s) for s in sps]
        Tm = M["T"][col]
        S = Xte @ Tm.T
        classes, S_ood = sps, Xood @ Tm.T
        ins, oods = S.max(1), S_ood.max(1)
        nsp_train = None
    else:
        Xs, ys = [], []
        for sp in test:
            pool = [e for e in train[sp] if policy == "all" or e["lic"] == "perm"]
            pool = pool[:k] if k else pool
            f, X = feats(pool)
            for x in X:
                Xs.append(x)
                ys.append(sp)
        classes = sorted(set(ys))
        nsp_train = len(classes)
        if len(classes) < 2:
            return None
        Xs, ys = np.array(Xs), np.array(ys)
        if clf == "proto":
            P = np.stack([Xs[ys == c].mean(0) for c in classes])
            P /= np.linalg.norm(P, axis=1, keepdims=True)
            S, S_ood = Xte @ P.T, Xood @ P.T
        else:
            lr = LogisticRegression(C=20, max_iter=400).fit(Xs, ys)
            classes = list(lr.classes_)
            S, S_ood = lr.predict_proba(Xte), (lr.predict_proba(Xood) if len(Xood) else np.zeros((0, len(classes))))
        ins, oods = S.max(1), (S_ood.max(1) if len(S_ood) else np.array([]))
    res = summarize(topk_hits(S, classes, truths), truths)
    res["n_test"] = len(te)
    res["n_species_trained"] = nsp_train
    res["ood_auc"], res["ood_accept90"] = ood_stats(ins, oods)
    res["S"], res["classes"], res["truths"] = S, classes, truths
    return res


def pct(x):
    return "n/a" if x is None else "%.1f%%" % (100 * x)


lines = ["# GrowLog on-device identifier bake-off", ""]
try:
    st = json.load(open(f"{DATA}/fetch_stats.json"))
    sp = [s for s in st["per_species"] if "perm" in s or s.get("category") is None]
    unresolved = [s["species"] for s in st["per_species"] if s.get("category") is None]
    lines += ["## Data", "",
              "Images downloaded: %d of %d requested. Source: Wikimedia Commons categories, permissive = CC0/PD/CC BY, sa = CC BY-SA. NC/ND dropped." % (st["downloaded"], st["entries_requested"]),
              "Unresolved categories: %s" % (", ".join(unresolved) or "none"), ""]
except Exception as ex:
    lines += ["(no fetch stats: %s)" % ex, ""]

best = None
for universe in ("core20", "all"):
    test, train, excluded = make_split(universe)
    nperm = np.array([sum(e["lic"] == "perm" for e in train[s]) for s in train])
    nall = np.array([len(train[s]) for s in train])
    lines += ["## Universe `%s`" % universe, "",
              "Species evaluated: %d (excluded for < 12 images: %d). Test images: %d. Median training pool per species: %d permissive-only, %d with share-alike. Species with fewer than 3 permissive training images: %d." % (
                  len(test), len(excluded), sum(len(v) for v in test.values()), np.median(nperm), np.median(nall), int((nperm < 3).sum())), "",
              "| model | classifier | train licences | shots | species trained | test imgs | top-1 | top-3 | top-5 | OOD AUROC | OOD accepted @90% in-list |",
              "|---|---|---|---|---|---|---|---|---|---|---|"]
    for nm in sorted(models):
        configs = [("zeroshot", "-", None)]
        if universe == "core20":
            configs += [(c, pol, k) for c in ("proto", "lr") for pol in ("perm", "all") for k in (5, 10, None)]
        else:
            configs += [(c, pol, k) for c in ("proto", "lr") for pol in ("perm", "all") for k in (10, 20, None)]
        for clf, pol, k in configs:
            if clf != "zeroshot" and ("_" in nm or (universe == "all" and nm in ("bioclip", "bioclip2"))):
                continue
            r = run(nm, universe, test, train, pol, k, clf)
            if not r:
                continue
            lines.append("| %s | %s | %s | %s | %s | %d | %s | %s | %s | %s | %s |" % (
                nm, clf, pol, "all" if (k is None and clf != "zeroshot") else (k or "-"), r["n_species_trained"] or "-",
                r["n_test"], pct(r["top1"]), pct(r["top3"]), pct(r["top5"]),
                "n/a" if r["ood_auc"] is None else "%.3f" % r["ood_auc"], pct(r["ood_accept90"])))
            if universe == "core20" and clf != "zeroshot" and (best is None or r["top3"] > best[0]["top3"]):
                best = (r, nm, clf, pol, k)
            r.pop("S", None) if not (best and best[0] is r) else None
    lines.append("")
    if universe == "core20":
        lines += ["Gate used: top-3 >= 85% and out-of-list accepted <= 30% at the threshold that accepts 90% of in-list photos.", ""]

if best:
    r, nm, clf, pol, k = best
    S, classes, truths = r["S"], r["classes"], r["truths"]
    order = np.argsort(-S, axis=1)
    sp = sorted(set(truths))
    acc = {s: np.mean([classes[order[i, 0]] == s for i, t in enumerate(truths) if t == s]) for s in sp}
    worst = sorted(acc.items(), key=lambda x: x[1])[:15]
    conf = {}
    for i, t in enumerate(truths):
        p = classes[order[i, 0]]
        if p != t:
            conf[(t, p)] = conf.get((t, p), 0) + 1
    lines += ["## Best supervised config (core20): %s / %s / %s / shots=%s, top-3 %s" % (nm, clf, pol, k or "all", pct(r["top3"])), "",
              "Weakest species (top-1): " + "; ".join("%s %.0f%%" % (w[0], 100 * w[1]) for w in worst), "",
              "Most common confusions (true -> predicted): " + "; ".join("%s -> %s (%d)" % (a, b, n) for (a, b), n in sorted(conf.items(), key=lambda x: -x[1])[:12]), ""]
lines += ["## Caveats", "",
          "- Photos come from Commons categories, so labels can be noisy and many are cleaner than real phone photos. Treat every figure as an optimistic estimate.",
          "- Splits are grouped by uploader where possible, but near-duplicate photo series can still leak between train and test.",
          "- Embedding time on the 2-core runner (seconds): " + ", ".join("%s %.0f" % (n, m["secs"]) for n, m in sorted(models.items())) + ". This is not phone speed.",
          "- The out-of-list set is 20 wild/garden plant species and 8 non-plant categories, about 12 photos each.", ""]
open(OUT, "w").write("\n".join(lines))
print("\n".join(lines))
