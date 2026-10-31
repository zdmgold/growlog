#!/usr/bin/env python3
"""Fetch licence-tagged plant photos from Wikimedia Commons (evaluation data for the GrowLog bake-off).
Writes data/manifest.json, data/fetch_stats.json and data/images/<id>.img"""
import concurrent.futures as cf
import json
import os
import random
import re
import sys
import threading
import time

import requests

API = "https://commons.wikimedia.org/w/api.php"
HEADERS = {"User-Agent": "GrowLogBakeoff/0.1 (https://github.com/zdmgold/growlog; evaluation only)"}
OUT = sys.argv[1] if len(sys.argv) > 1 else "data"
PER_LIC = int(os.environ.get("PER_LIC", "40"))   # max photos per species for each licence class
OOD_PER = int(os.environ.get("OOD_PER", "12"))

EXCL_CAT = re.compile(
    r"herbari|illustrat|drawing|painting|\bmaps?\b|diagram|chemi|\bdna\b|microscop|\bsem\b|pollen|"
    r"fossil|stamp|\bcoins?\b|logo|flag|cuisine|\bfood\b|recipe|\bdish|extract|\boil\b|\btea\b|"
    r"herbal|poster|print|engraving|lithograph|cartoon|botanical art|\bart\b|in art|names?\b", re.I)
EXCL_FILE = re.compile(
    r"herbari|illustrat|drawing|painting|\bmap\b|diagram|\bplate\b|lithograph|engraving|sketch|"
    r"\bscan\b|logo|\bicon\b|flag|poster|postcard|stamp|\bbook\b|\bpage\b|\bcooked\b|\bdish\b|"
    r"\bfood\b|\btea\b|\.svg|\.pdf|\.tif", re.I)

_lock = threading.Lock()
_last = [0.0]


def api(params, tries=6):
    p = dict(params)
    p.update({"format": "json", "formatversion": "2"})
    for t in range(tries):
        with _lock:
            wait = 0.12 - (time.time() - _last[0])
            if wait > 0:
                time.sleep(wait)
            _last[0] = time.time()
        try:
            r = requests.get(API, params=p, headers=HEADERS, timeout=40)
            if r.status_code in (429, 500, 502, 503, 504):
                time.sleep(2 * (t + 1))
                continue
            r.raise_for_status()
            return r.json()
        except (requests.RequestException, ValueError):
            time.sleep(2 * (t + 1))
    return None


def members(cat_title, cmtype, cap):
    out, cont = [], None
    while len(out) < cap:
        p = {"action": "query", "list": "categorymembers", "cmtitle": cat_title,
             "cmtype": cmtype, "cmlimit": "500"}
        if cont:
            p.update(cont)
        d = api(p)
        if not d:
            break
        out += [m["title"] for m in d.get("query", {}).get("categorymembers", [])]
        cont = d.get("continue")
        if not cont:
            break
    return out[:cap]


def resolve_category(name):
    t = f"Category:{name}"
    d = api({"action": "query", "titles": t, "prop": "categoryinfo"})
    pg = (d or {}).get("query", {}).get("pages", [])
    if pg and not pg[0].get("missing") and pg[0].get("categoryinfo", {}).get("size", 0) > 0:
        return t
    d = api({"action": "query", "list": "search", "srsearch": name, "srnamespace": "14", "srlimit": "5"})
    first = name.split()[0].lower()
    for h in (d or {}).get("query", {}).get("search", []):
        if first in h["title"].lower():
            return h["title"]
    return None


def category_files(name, cap=600):
    cat = resolve_category(name)
    if not cat:
        return None, []
    files = members(cat, "file", cap)
    subs = [s for s in members(cat, "subcat", 40) if not EXCL_CAT.search(s)][:10]
    for s in subs:
        files += members(s, "file", 200)
    seen, uniq = set(), []
    for f in files:
        if f not in seen and not EXCL_FILE.search(f):
            seen.add(f)
            uniq.append(f)
    return cat, uniq


def info(titles):
    out = []
    for i in range(0, len(titles), 40):
        d = api({"action": "query", "titles": "|".join(titles[i:i + 40]), "prop": "imageinfo",
                 "iiprop": "url|size|mime|extmetadata", "iiurlwidth": "320",
                 "iiextmetadatafilter": "LicenseShortName|Artist"})
        for pg in (d or {}).get("query", {}).get("pages", []):
            ii = pg.get("imageinfo")
            if not ii:
                continue
            ii = ii[0]
            md = ii.get("extmetadata", {})
            out.append({
                "title": pg["title"], "mime": ii.get("mime"), "w": ii.get("width") or 0,
                "h": ii.get("height") or 0, "thumb": ii.get("thumburl"), "page": ii.get("descriptionurl"),
                "licence": (md.get("LicenseShortName") or {}).get("value", ""),
                "artist": re.sub(r"<[^>]+>", "", (md.get("Artist") or {}).get("value", "")).strip()[:80],
            })
    return out


def lic_class(s):
    s = (s or "").strip()
    if re.search(r"\bNC\b|\bND\b|non-?commercial", s, re.I):
        return None
    if re.match(r"(CC0|Public domain|PD\b)", s, re.I):
        return "perm"
    if re.match(r"CC BY-SA", s, re.I):
        return "sa"
    if re.match(r"CC BY\b", s, re.I):
        return "perm"
    return None


def usable(recs):
    keep = []
    for r in recs:
        if r["mime"] not in ("image/jpeg", "image/png") or not r["thumb"]:
            continue
        if min(r["w"], r["h"]) < 300:
            continue
        lc = lic_class(r["licence"])
        if lc:
            r["lic"] = lc
            keep.append(r)
    return keep


def collect_species(name, rng):
    cat, files = category_files(name)
    if not cat:
        return {"species": name, "category": None, "raw_files": 0}, []
    recs = usable(info(files))
    rng.shuffle(recs)
    perm = [r for r in recs if r["lic"] == "perm"][:PER_LIC]
    sa = [r for r in recs if r["lic"] == "sa"][:PER_LIC]
    kept = perm + sa
    rng.shuffle(kept)
    return {"species": name, "category": cat, "raw_files": len(files), "usable": len(recs),
            "perm": len(perm), "sa": len(sa)}, kept


def collect_ood(kind, name, rng):
    cat, files = category_files(name, cap=300)
    if not cat:
        return {"species": name, "category": None}, []
    recs = usable(info(files[:200]))
    rng.shuffle(recs)
    return {"species": name, "category": cat, "kind": kind, "usable": len(recs)}, recs[:OOD_PER]


def download(entry):
    for t in range(4):
        try:
            r = requests.get(entry["thumb"], headers=HEADERS, timeout=40)
            if r.status_code == 200 and len(r.content) > 1000:
                with open(entry["path"], "wb") as fh:
                    fh.write(r.content)
                return True
            if r.status_code == 429:
                time.sleep(3 * (t + 1))
        except requests.RequestException:
            time.sleep(2)
    return False


def main():
    os.makedirs(os.path.join(OUT, "images"), exist_ok=True)
    species = [l.strip() for l in open("bakeoff/species.txt") if l.strip()]
    ood = [l.strip().split("|", 1) for l in open("bakeoff/ood.txt") if l.strip()]
    stats, entries = [], []
    t0 = time.time()
    with cf.ThreadPoolExecutor(3) as ex:
        futs = {ex.submit(collect_species, s, random.Random(i)): ("species", s) for i, s in enumerate(species)}
        futs.update({ex.submit(collect_ood, k, n, random.Random(1000 + i)): ("ood_" + k, n) for i, (k, n) in enumerate(ood)})
        res = {}
        for f in cf.as_completed(futs):
            res[futs[f]] = f.result()
    print("listing done in %.0fs" % (time.time() - t0), flush=True)
    nid = 0
    for s in species:
        st, kept = res[("species", s)]
        stats.append(st)
        for rank, r in enumerate(kept):
            entries.append({"id": nid, "species": s, "group": "species", "lic": r["lic"], "artist": r["artist"],
                            "title": r["title"], "page": r["page"], "licence": r["licence"], "thumb": r["thumb"],
                            "core20": rank < 20, "core8": rank < 8})
            nid += 1
    for k, n in ood:
        st, kept = res[("ood_" + k, n)]
        stats.append(st)
        for r in kept:
            entries.append({"id": nid, "species": n, "group": "ood_" + k, "lic": r["lic"], "artist": r["artist"],
                            "title": r["title"], "page": r["page"], "licence": r["licence"], "thumb": r["thumb"],
                            "core20": True, "core8": True})
            nid += 1
    for e in entries:
        e["path"] = os.path.join(OUT, "images", "%d.img" % e["id"])
    print("downloading %d images" % len(entries), flush=True)
    with cf.ThreadPoolExecutor(6) as ex:
        ok = list(ex.map(download, entries))
    kept_entries = [e for e, good in zip(entries, ok) if good]
    for e in kept_entries:
        e.pop("thumb", None)
    json.dump(kept_entries, open(os.path.join(OUT, "manifest.json"), "w"))
    json.dump({"entries_requested": len(entries), "downloaded": len(kept_entries), "per_species": stats},
              open(os.path.join(OUT, "fetch_stats.json"), "w"), indent=1)
    print("done: %d/%d images in %.0fs" % (len(kept_entries), len(entries), time.time() - t0))


if __name__ == "__main__":
    main()
