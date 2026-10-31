#!/usr/bin/env python3
"""Why did these species return no usable photos? Prints where each one loses files."""
import collections
import importlib.util
import re
import sys

spec = importlib.util.spec_from_file_location("fc", "bakeoff/fetch_commons.py")
fc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fc)

NAMES = ["Philodendron bipinnatifidum", "Alocasia amazonica", "Rhaphidophora tetrasperma", "Calathea orbifolia",
         "Calathea lancifolia", "Calathea makoyana", "Dracaena marginata", "Yucca elephantipes",
         "Schefflera actinophylla", "Haworthia fasciata", "Senecio rowleyanus", "Echinocactus grusonii",
         "Phalaenopsis", "Saintpaulia ionantha", "Cissus rhombifolia", "Rosmarinus officinalis"]
for name in NAMES:
    cat = fc.resolve_category(name)
    print("=" * 70)
    print(name, "->", cat)
    if not cat:
        continue
    files = fc.members(cat, "file", 600)
    subs = fc.members(cat, "subcat", 60)
    print("direct files:", len(files), "| subcats:", len(subs))
    print("subcats:", subs[:14])
    kept_subs = [s for s in subs if not fc.EXCL_CAT.search(s)]
    print("subcats surviving EXCL_CAT:", len(kept_subs), "| dropped:", [s for s in subs if fc.EXCL_CAT.search(s)][:6])
    allf = list(files)
    for s in kept_subs[:10]:
        allf += fc.members(s, "file", 200)
    exf = [f for f in allf if fc.EXCL_FILE.search(f)]
    print("files before filters:", len(allf), "| dropped by EXCL_FILE:", len(exf), exf[:3])
    recs = fc.info([f for f in dict.fromkeys(allf) if not fc.EXCL_FILE.search(f)][:200])
    why = collections.Counter()
    for r in recs:
        if r["mime"] not in ("image/jpeg", "image/png") or not r["thumb"]:
            why["mime/thumb:" + str(r["mime"])] += 1
        elif min(r["w"], r["h"]) < 300:
            why["small"] += 1
        elif not fc.lic_class(r["licence"]):
            why["licence:" + (r["licence"] or "none")[:20]] += 1
        else:
            why["USABLE"] += 1
    print("info records:", len(recs), dict(why))
    sys.stdout.flush()
