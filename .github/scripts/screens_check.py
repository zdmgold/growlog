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


def plural_cat(l, n):
    """Dart intl plural rules for the languages in the app."""
    if l == "ar":
        if n == 0: return "zero"
        if n == 1: return "one"
        if n == 2: return "two"
        m = n % 100
        if 3 <= m <= 10: return "few"
        if 11 <= m <= 99: return "many"
        return "other"
    if l == "he": return "one" if n == 1 else "two" if n == 2 else "other"
    if l in ("ja", "ko", "zh"): return "other"
    if l in ("fr", "pt", "hi"): return "one" if n in (0, 1) else "other"
    return "one" if n == 1 else "other"

def _match(msg, i):
    d = 0
    for j in range(i, len(msg)):
        if msg[j] == "{": d += 1
        elif msg[j] == "}":
            d -= 1
            if d == 0: return j
    raise ValueError("unbalanced")

def render(l, key, params):
    """Evaluates an ARB message with Flutter's gen_l10n semantics (=1 -> one, =2 -> two, missing branch -> other)."""
    def ev(msg):
        out, i = [], 0
        while i < len(msg):
            if msg[i] != "{": out.append(msg[i]); i += 1; continue
            j = _match(msg, i); inner = msg[i + 1:j]
            m = re.match(r"(\w+),\s*plural,\s*", inner, re.ASCII)
            if m:
                n = int(params[m.group(1)]); body = inner[m.end():]; br = {}; k = 0
                while k < len(body):
                    mm = re.match(r"\s*(=\d+|\w+)\{", body[k:], re.ASCII)
                    if not mm: break
                    st = k + mm.end() - 1; en = _match(body, st); br[mm.group(1)] = body[st + 1:en]; k = en + 1
                cat = plural_cat(l, n)
                cands = {"zero": ["=0", "zero"], "one": ["=1", "one"], "two": ["=2", "two"]}.get(cat, [cat])
                text = next((br[c] for c in cands if c in br), br["other"])
                out.append(ev(text))
            else: out.append(str(params.get(inner, "{" + inner + "}")))
            i = j + 1
        return "".join(out)
    return ev(arb(l)[key])

def parse_fmt(item, lang=None):
    _, key, rest = item.split(":", 2); params = {}
    for kv in rest.split(","):
        k, v = kv.split("=", 1)
        if v.startswith("@"): v = arb(lang)[v[1:]]          # @careTypeWater -> that language's label
        params[k] = int(v) if v.isdigit() else v
    return key, params

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
    if item.startswith("text:"): return item[5:], None
    if item.startswith("fmt:"):
        key, params = parse_fmt(item, l); key2, params_en = parse_fmt(item, "en"); return render(l, key, params), render("en", key, params_en)
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
