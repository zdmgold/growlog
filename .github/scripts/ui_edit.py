#!/usr/bin/env python3
"""Prints the centre of the nth (0-based) EditText on screen."""
import re, sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot(); n = int(sys.argv[2]); found = []
for e in root.iter('node'):
    if e.get('class') == 'android.widget.EditText':
        m = re.match(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', e.get('bounds', ''))
        if m:
            l, t, r, b = map(int, m.groups()); found.append(((l + r) // 2, (t + b) // 2))
if n >= len(found): sys.exit(1)
print(found[n][0], found[n][1])
