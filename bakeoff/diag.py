#!/usr/bin/env python3
import importlib.util, random
spec = importlib.util.spec_from_file_location("fc", "bakeoff/fetch_commons.py")
fc = importlib.util.module_from_spec(spec); spec.loader.exec_module(fc)
MISSING = ["Philodendron bipinnatifidum", "Alocasia amazonica", "Rhaphidophora tetrasperma", "Calathea orbifolia",
           "Calathea lancifolia", "Calathea makoyana", "Dracaena marginata", "Yucca elephantipes",
           "Schefflera actinophylla", "Haworthia fasciata", "Senecio rowleyanus", "Echinocactus grusonii",
           "Phalaenopsis", "Saintpaulia ionantha", "Cissus rhombifolia", "Rosmarinus officinalis"]
lines = {l.split("|")[0]: l.strip() for l in open("bakeoff/species.txt") if l.strip()}
for n in MISSING:
    st, kept = fc.collect_species(lines[n], random.Random(1))
    print(n, "->", {k: st.get(k) for k in ("category", "raw_files", "usable", "perm", "sa")}, flush=True)
