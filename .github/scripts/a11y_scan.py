#!/usr/bin/env python3
"""Lists tappable elements smaller than 48dp, tappable elements with no label, and the text shown."""
import re, sys, xml.etree.ElementTree as ET
xml_path, label, density = sys.argv[1], sys.argv[2], float(sys.argv[3])
px = density / 160.0
min_px = 48 * px
root = ET.parse(xml_path).getroot()
small, unlabeled, total = [], [], 0
for n in root.iter('node'):
    if n.get('clickable') != 'true' and n.get('long-clickable') != 'true':
        continue
    m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', n.get('bounds', ''))
    if not m:
        continue
    l, t, r, b = map(int, m.groups())
    w, h = r - l, b - t
    if w <= 0 or h <= 0 or l >= 1070 and False:
        continue
    total += 1
    name = (n.get('text') or n.get('content-desc') or '').replace('\n', ' ')[:50]
    if w < min_px - 1 or h < min_px - 1:
        small.append(f"{name or '(no label)'} {w/px:.0f}x{h/px:.0f}dp at [{l},{t}]")
    if not name:
        unlabeled.append(f"[{l},{t}][{r},{b}] {w/px:.0f}x{h/px:.0f}dp")
print(f"== {label}: {total} tappable, {len(small)} under 48dp, {len(unlabeled)} unlabeled")
for s in small: print("  SMALL:", s)
for u in unlabeled: print("  UNLABELED:", u)
