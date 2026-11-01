#!/usr/bin/env python3
"""Time and memory of an ONNX image encoder on this CPU. Usage: bench_ort.py MODEL.onnx [threads,...]"""
import json
import os
import platform
import resource
import subprocess
import sys
import time

import numpy as np
import onnxruntime as ort

path = sys.argv[1]
threads = [int(t) for t in (sys.argv[2] if len(sys.argv) > 2 else "1,2,4").split(",")]
rss = lambda: resource.getrusage(resource.RUSAGE_SELF).ru_maxrss / 1024.0  # MB on Linux
cpu = subprocess.run("lscpu | grep -E 'Model name|Flags|Features|^CPU\\(s\\)'", shell=True, capture_output=True, text=True).stdout
res = {"model": os.path.basename(path), "size_MB": round(os.path.getsize(path) / 1e6, 1), "machine": platform.machine(),
       "ort": ort.__version__, "lscpu": [l[:160] for l in cpu.splitlines() if "Flags" not in l and "Features" not in l],
       "has_dotprod": "asimddp" in cpu or "avx512_vnni" in cpu or "avx_vnni" in cpu, "has_i8mm": "i8mm" in cpu}
x = np.random.default_rng(0).normal(size=(1, 3, 224, 224)).astype(np.float32)
rows = []
for n in threads:
    so = ort.SessionOptions()
    so.intra_op_num_threads = n
    t0 = time.time()
    s = ort.InferenceSession(path, so, providers=["CPUExecutionProvider"])
    load = time.time() - t0
    rss_loaded = rss()
    for _ in range(3):
        s.run(None, {"image": x})
    lat = []
    for _ in range(20):
        t = time.time()
        s.run(None, {"image": x})
        lat.append(1000 * (time.time() - t))
    lat.sort()
    rows.append({"threads": n, "load_s": round(load, 2), "median_ms": round(lat[len(lat) // 2]), "p90_ms": round(lat[int(len(lat) * 0.9)]),
                 "peak_rss_after_load_MB": round(rss_loaded), "peak_rss_after_runs_MB": round(rss())})
    del s
res["runs"] = rows
print(json.dumps(res, indent=1))
