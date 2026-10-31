#!/usr/bin/env python3
"""ui_tap.py UI.xml LABEL [LABEL...] -> prints 'x y' for the first node whose text/content-desc matches
(exact first, then substring, case-insensitive). Exit 1 if none."""
import re
import sys
import xml.etree.ElementTree as ET

xml, labels = sys.argv[1], sys.argv[2:]
try:
    root = ET.parse(xml).getroot()
except Exception:
    sys.exit(1)
nodes = []
for n in root.iter("node"):
    b = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", n.get("bounds", ""))
    if not b:
        continue
    l, t, r, bt = map(int, b.groups())
    if r <= l or bt <= t:
        continue
    for key in ("text", "content-desc"):
        v = (n.get(key) or "").strip()
        if v:
            nodes.append((v.lower(), (l + r) // 2, (t + bt) // 2, t))
for lab in labels:
    lab = lab.lower()
    for mode in ("exact", "sub"):
        c = [x for x in nodes if (x[0] == lab if mode == "exact" else lab in x[0])]
        if c:
            c.sort(key=lambda x: -x[3])  # prefer the lowest on screen (dock before page content)
            print(c[0][1], c[0][2])
            sys.exit(0)
sys.exit(1)
