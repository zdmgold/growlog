#!/usr/bin/env python3
"""Language checks for the emulator test.

  lang_check.py text  <lang> <key>          print the string from the language file
  lang_check.py check <xml> <lang> <rtl 0|1>  check the screen shows that language
"""
import html, json, re, sys, xml.etree.ElementTree as ET

KEYS = ["navHome", "navGarden", "navSchedule", "scanAPlant"]

def arb(lang):
    return json.load(open(f"lib/l10n/app_{lang}.arb", encoding="utf8"))

def centres(xml_path):
    out = []
    for n in ET.parse(xml_path).getroot().iter("node"):
        label = (n.get("text") or "") + " " + (n.get("content-desc") or "")
        m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", n.get("bounds", ""))
        if m and label.strip():
            l, t, r, b = map(int, m.groups())
            out.append((label, (l + r) // 2, (t + b) // 2))
    return out

def find_x(nodes, text):
    # Several nodes can carry the same word (a page title and the dock label). The dock is
    # the lowest one on screen, so prefer the match with the largest y.
    hits = [(y, x) for label, x, y in nodes if text in label]
    return max(hits)[1] if hits else None

def main():
    if sys.argv[1] == "text":
        print(arb(sys.argv[2])[sys.argv[3]])
        return 0
    xml_path, lang, rtl = sys.argv[2], sys.argv[3], sys.argv[4] == "1"
    nodes = centres(xml_path)
    want, en = arb(lang), arb("en")
    bad = 0
    for k in KEYS:
        text = html.unescape(want[k])
        x = find_x(nodes, text)
        if x is None:
            print(f"  MISSING {k}: {text!r}")
            bad += 1
    if lang != "en":
        for k in KEYS:
            e = en[k]
            if want[k] != e and find_x(nodes, e) is not None:
                print(f"  ENGLISH LEAK {k}: {e!r}")
                bad += 1
    # dock direction
    h = find_x(nodes, html.unescape(want["navHome"]))
    s = find_x(nodes, html.unescape(want["navSchedule"]))
    if h is not None and s is not None:
        ok = (h > s) if rtl else (h < s)
        print(f"  dock order {'right-to-left' if rtl else 'left-to-right'}: {'ok' if ok else 'WRONG'}")
        if not ok:
            bad += 1
    print("RESULT", "FAIL" if bad else "PASS")
    return 1 if bad else 0

sys.exit(main())
