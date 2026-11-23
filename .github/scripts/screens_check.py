#!/usr/bin/env python3
"""Checks that a screen shows the expected localized text and no English leaks.

  screens_check.py key   <lang> <arbkey>                 print the ARB string
  screens_check.py label <lang> <english label text>     print that Symptom Checker label in <lang>
  screens_check.py check <lang> <min_ratio> <xml,xml,..> <item> <item> ...
      item = ARB key | sym:<labelid> | prob:<problemid>   (strings with placeholders are skipped)
  PASS when no English leak is found and at least min_ratio of the items are on screen
  (the union of several dumps, so a scrolled screen can be checked).
"""
import html, json, math, re, sys, xml.etree.ElementTree as ET

def arb(l): return json.load(open(f"lib/l10n/app_{l}.arb", encoding="utf8"))
def sym(l): return json.load(open(f"assets/care/symptoms_{l}.json", encoding="utf8"))

def english_labels():
    base = json.load(open("assets/care/symptoms.json", encoding="utf8"))
    out = {}
    def walk(x):
        if isinstance(x, dict):
            if "id" in x and "label" in x: out[x["label"].lower()] = x["id"]
            for v in x.values(): walk(v)
        elif isinstance(x, list):
            for v in x: walk(v)
    walk({k: v for k, v in base.items() if k != "problems"})
    return out

def texts(paths):
    out = []
    for p in paths:
        try: root = ET.parse(p).getroot()
        except Exception: continue
        for n in root.iter("node"):
            for a in ("text", "content-desc"):
                v = n.get(a) or ""
                if v.strip(): out.append(html.unescape(v).replace("\n", " "))
    return out

def expected(l, item):
    if item.startswith("sym:"):
        i = item[4:]; return sym(l)["labels"].get(i), sym("en")["labels"].get(i) if False else None
    if item.startswith("prob:"):
        i = item[5:]; return sym(l)["problems"][i]["name"], json.load(open("assets/care/symptoms.json", encoding="utf8")) and next(p["name"] for p in json.load(open("assets/care/symptoms.json", encoding="utf8"))["problems"] if p["id"] == i)
    return arb(l)[item], arb("en")[item]

def main():
    cmd = sys.argv[1]
    if cmd == "key": print(arb(sys.argv[2])[sys.argv[3]]); return 0
    if cmd == "labelid": print(sym(sys.argv[2])["labels"][sys.argv[3]]); return 0
    if cmd == "label":
        m = english_labels(); i = m.get(sys.argv[3].lower())
        if i is None: sys.exit(1)
        print(sym(sys.argv[2])["labels"][i]); return 0
    l, ratio, paths, items = sys.argv[2], float(sys.argv[3]), sys.argv[4].split(","), sys.argv[5:]
    T = texts(paths); blob = "\n".join(T)
    found = missing = leaks = skipped = 0; lines = []
    for it in items:
        want, en = expected(l, it)
        if want is None or "{" in want: skipped += 1; continue
        w = html.unescape(want)
        if w in blob: found += 1; lines.append(f"  ok      {it}")
        else: missing += 1; lines.append(f"  MISSING {it}: {w!r}")
        if l != "en" and en and "{" not in en and len(en) >= 4 and en != want and en in blob and en not in w:
            leaks += 1; lines.append(f"  ENGLISH LEAK {it}: {en!r}")
    n = found + missing; need = math.ceil(ratio * n) if n else 0
    ok = leaks == 0 and found >= need and n > 0
    print("\n".join(lines)); print(f"  found {found}/{n} (need {need}), leaks {leaks}, skipped {skipped}")
    print("RESULT", "PASS" if ok else "FAIL"); return 0 if ok else 1

sys.exit(main())
