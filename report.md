# GrowLog on-device identifier bake-off

## Data

Images downloaded: 7777 of 7777 requested. Source: Wikimedia Commons categories, permissive = CC0/PD/CC BY, sa = CC BY-SA. NC/ND dropped.
Unresolved categories: Ctenanthe

## Universe `core20`

Species evaluated: 106 (excluded for < 12 images: 1). Test images: 528. Median training pool per species: 7 permissive-only, 15 with share-alike. Species with fewer than 3 permissive training images: 5.

| model | classifier | train licences | shots | species trained | test imgs | top-1 | top-3 | top-5 | OOD AUROC | OOD accepted @90% in-list |
|---|---|---|---|---|---|---|---|---|---|---|
| bioclip | zeroshot | - | - | - | 528 | 67.8% | 79.0% | 84.1% | 0.953 | 14.9% |
| bioclip | proto | perm | 5 | 106 | 528 | 53.6% | 71.6% | 78.6% | 0.889 | 41.7% |
| bioclip | proto | perm | 10 | 106 | 528 | 57.6% | 73.1% | 80.1% | 0.895 | 37.2% |
| bioclip | proto | perm | all | 106 | 528 | 57.2% | 73.5% | 80.3% | 0.895 | 37.5% |
| bioclip | proto | all | 5 | 106 | 528 | 62.7% | 76.5% | 83.1% | 0.897 | 39.0% |
| bioclip | proto | all | 10 | 106 | 528 | 63.8% | 81.8% | 86.0% | 0.903 | 35.1% |
| bioclip | proto | all | all | 106 | 528 | 67.4% | 82.8% | 87.7% | 0.906 | 33.3% |
| bioclip | lr | perm | 5 | 106 | 528 | 55.9% | 71.0% | 79.2% | 0.775 | 70.5% |
| bioclip | lr | perm | 10 | 106 | 528 | 54.4% | 72.5% | 80.3% | 0.796 | 70.5% |
| bioclip | lr | perm | all | 106 | 528 | 54.9% | 72.7% | 80.3% | 0.792 | 70.8% |
| bioclip | lr | all | 5 | 106 | 528 | 64.2% | 78.2% | 85.8% | 0.792 | 68.5% |
| bioclip | lr | all | 10 | 106 | 528 | 66.3% | 82.2% | 87.5% | 0.799 | 68.2% |
| bioclip | lr | all | all | 106 | 528 | 67.6% | 83.1% | 88.6% | 0.819 | 62.8% |
| bioclip2 | zeroshot | - | - | - | 528 | 76.3% | 88.4% | 91.7% | 0.983 | 3.6% |
| bioclip2 | proto | perm | 5 | 106 | 528 | 67.4% | 79.4% | 84.8% | 0.925 | 32.4% |
| bioclip2 | proto | perm | 10 | 106 | 528 | 68.6% | 82.0% | 85.8% | 0.933 | 25.0% |
| bioclip2 | proto | perm | all | 106 | 528 | 68.9% | 81.8% | 85.8% | 0.934 | 24.7% |
| bioclip2 | proto | all | 5 | 106 | 528 | 71.0% | 85.2% | 89.0% | 0.933 | 25.6% |
| bioclip2 | proto | all | 10 | 106 | 528 | 75.2% | 88.6% | 92.0% | 0.933 | 25.9% |
| bioclip2 | proto | all | all | 106 | 528 | 75.6% | 89.2% | 92.6% | 0.936 | 25.9% |
| bioclip2 | lr | perm | 5 | 106 | 528 | 67.6% | 80.3% | 86.2% | 0.881 | 42.3% |
| bioclip2 | lr | perm | 10 | 106 | 528 | 68.2% | 82.4% | 85.8% | 0.871 | 44.3% |
| bioclip2 | lr | perm | all | 106 | 528 | 67.8% | 82.4% | 85.8% | 0.871 | 44.9% |
| bioclip2 | lr | all | 5 | 106 | 528 | 72.2% | 86.6% | 90.5% | 0.904 | 33.9% |
| bioclip2 | lr | all | 10 | 106 | 528 | 75.2% | 89.2% | 91.7% | 0.892 | 39.3% |
| bioclip2 | lr | all | all | 106 | 528 | 77.5% | 89.4% | 92.4% | 0.900 | 37.5% |
| bioclip2_int8 | zeroshot | - | - | - | 528 | 74.8% | 87.5% | 90.5% | 0.981 | 3.6% |
| bioclip_fp32 | zeroshot | - | - | - | 528 | 67.8% | 79.0% | 84.1% | 0.953 | 14.9% |
| bioclip_int8 | zeroshot | - | - | - | 528 | 59.3% | 73.3% | 79.4% | 0.955 | 12.2% |
| clip | zeroshot | - | - | - | 528 | 28.0% | 47.2% | 54.0% | 0.891 | 35.1% |
| clip | proto | perm | 5 | 106 | 528 | 23.5% | 42.4% | 51.9% | 0.823 | 50.6% |
| clip | proto | perm | 10 | 106 | 528 | 25.9% | 43.8% | 53.8% | 0.822 | 50.6% |
| clip | proto | perm | all | 106 | 528 | 26.3% | 44.3% | 54.0% | 0.821 | 50.6% |
| clip | proto | all | 5 | 106 | 528 | 29.4% | 48.1% | 54.7% | 0.833 | 53.9% |
| clip | proto | all | 10 | 106 | 528 | 34.1% | 51.5% | 59.8% | 0.825 | 53.9% |
| clip | proto | all | all | 106 | 528 | 36.4% | 55.5% | 63.8% | 0.822 | 52.4% |
| clip | lr | perm | 5 | 106 | 528 | 27.5% | 44.9% | 54.4% | 0.477 | 92.0% |
| clip | lr | perm | 10 | 106 | 528 | 26.7% | 45.8% | 57.4% | 0.520 | 89.0% |
| clip | lr | perm | all | 106 | 528 | 27.1% | 45.5% | 57.6% | 0.521 | 88.7% |
| clip | lr | all | 5 | 106 | 528 | 33.9% | 52.3% | 60.2% | 0.562 | 86.0% |
| clip | lr | all | 10 | 106 | 528 | 39.4% | 59.1% | 66.1% | 0.543 | 87.2% |
| clip | lr | all | all | 106 | 528 | 42.2% | 64.0% | 70.8% | 0.561 | 85.4% |
| dino | proto | perm | 5 | 106 | 528 | 48.7% | 65.0% | 71.8% | 0.912 | 30.7% |
| dino | proto | perm | 10 | 106 | 528 | 53.2% | 69.5% | 75.2% | 0.912 | 32.7% |
| dino | proto | perm | all | 106 | 528 | 53.4% | 69.1% | 75.4% | 0.911 | 32.4% |
| dino | proto | all | 5 | 106 | 528 | 54.0% | 69.5% | 76.5% | 0.918 | 28.9% |
| dino | proto | all | 10 | 106 | 528 | 59.1% | 74.8% | 80.3% | 0.921 | 33.6% |
| dino | proto | all | all | 106 | 528 | 63.1% | 77.5% | 82.6% | 0.921 | 29.2% |
| dino | lr | perm | 5 | 106 | 528 | 52.8% | 67.6% | 74.4% | 0.767 | 57.1% |
| dino | lr | perm | 10 | 106 | 528 | 54.9% | 71.6% | 75.8% | 0.753 | 64.6% |
| dino | lr | perm | all | 106 | 528 | 54.9% | 71.6% | 75.4% | 0.754 | 66.4% |
| dino | lr | all | 5 | 106 | 528 | 56.6% | 73.9% | 79.2% | 0.814 | 50.0% |
| dino | lr | all | 10 | 106 | 528 | 64.6% | 79.2% | 83.7% | 0.808 | 48.8% |
| dino | lr | all | all | 106 | 528 | 67.0% | 82.4% | 86.2% | 0.796 | 52.4% |

Gate used: top-3 >= 85% and out-of-list accepted <= 30% at the threshold that accepts 90% of in-list photos.

## Universe `all`

Species evaluated: 106 (excluded for < 12 images: 1). Test images: 1034. Median training pool per species: 34 permissive-only, 70 with share-alike. Species with fewer than 3 permissive training images: 2.

| model | classifier | train licences | shots | species trained | test imgs | top-1 | top-3 | top-5 | OOD AUROC | OOD accepted @90% in-list |
|---|---|---|---|---|---|---|---|---|---|---|
| bioclip | zeroshot | - | - | - | 321 | 62.9% | 78.8% | 85.4% | 0.959 | 13.4% |
| bioclip2 | zeroshot | - | - | - | 321 | 74.8% | 87.9% | 92.8% | 0.986 | 2.4% |
| bioclip2_int8 | zeroshot | - | - | - | 321 | 73.5% | 88.8% | 91.9% | 0.986 | 1.8% |
| bioclip_fp32 | zeroshot | - | - | - | 321 | 62.9% | 78.8% | 85.4% | 0.959 | 13.4% |
| bioclip_int8 | zeroshot | - | - | - | 321 | 56.1% | 73.5% | 80.4% | 0.956 | 11.9% |
| clip | zeroshot | - | - | - | 1034 | 28.5% | 45.8% | 54.5% | 0.893 | 34.2% |
| clip | proto | perm | 10 | 106 | 1034 | 30.7% | 48.6% | 56.5% | 0.818 | 52.1% |
| clip | proto | perm | 20 | 106 | 1034 | 32.3% | 53.1% | 61.3% | 0.814 | 52.7% |
| clip | proto | perm | all | 106 | 1034 | 35.2% | 53.7% | 61.6% | 0.811 | 52.1% |
| clip | proto | all | 10 | 106 | 1034 | 33.8% | 54.0% | 62.7% | 0.820 | 51.8% |
| clip | proto | all | 20 | 106 | 1034 | 37.9% | 57.7% | 65.2% | 0.821 | 50.9% |
| clip | proto | all | all | 106 | 1034 | 42.9% | 62.1% | 69.3% | 0.817 | 53.3% |
| clip | lr | perm | 10 | 106 | 1034 | 36.2% | 55.2% | 63.0% | 0.527 | 89.3% |
| clip | lr | perm | 20 | 106 | 1034 | 41.3% | 60.3% | 68.4% | 0.567 | 87.5% |
| clip | lr | perm | all | 106 | 1034 | 43.9% | 62.7% | 69.6% | 0.582 | 85.7% |
| clip | lr | all | 10 | 106 | 1034 | 39.6% | 59.9% | 68.1% | 0.578 | 84.8% |
| clip | lr | all | 20 | 106 | 1034 | 46.4% | 65.1% | 73.3% | 0.576 | 86.0% |
| clip | lr | all | all | 106 | 1034 | 54.6% | 73.9% | 81.1% | 0.626 | 79.2% |
| dino | proto | perm | 10 | 106 | 1034 | 54.3% | 72.5% | 79.2% | 0.909 | 34.8% |
| dino | proto | perm | 20 | 106 | 1034 | 58.1% | 75.6% | 81.2% | 0.912 | 35.1% |
| dino | proto | perm | all | 106 | 1034 | 59.5% | 75.6% | 81.8% | 0.911 | 33.3% |
| dino | proto | all | 10 | 106 | 1034 | 58.2% | 74.6% | 79.3% | 0.914 | 30.4% |
| dino | proto | all | 20 | 106 | 1034 | 60.4% | 77.3% | 82.4% | 0.913 | 30.4% |
| dino | proto | all | all | 106 | 1034 | 62.3% | 79.1% | 83.8% | 0.914 | 31.2% |
| dino | lr | perm | 10 | 106 | 1034 | 61.1% | 76.3% | 81.4% | 0.776 | 63.7% |
| dino | lr | perm | 20 | 106 | 1034 | 63.5% | 79.8% | 83.7% | 0.774 | 60.4% |
| dino | lr | perm | all | 106 | 1034 | 65.1% | 80.2% | 84.5% | 0.762 | 63.1% |
| dino | lr | all | 10 | 106 | 1034 | 63.1% | 78.8% | 83.9% | 0.808 | 52.4% |
| dino | lr | all | 20 | 106 | 1034 | 67.5% | 83.4% | 87.2% | 0.803 | 52.7% |
| dino | lr | all | all | 106 | 1034 | 71.2% | 86.1% | 90.4% | 0.785 | 62.2% |

## Best supervised config (core20): bioclip2 / lr / all / shots=all, top-3 89.4%

Weakest species (top-1): Calathea lancifolia 0%; Philodendron erubescens 0%; Schefflera actinophylla 20%; Senecio rowleyanus 20%; Calathea makoyana 40%; Dieffenbachia seguine 40%; Dracaena reflexa 40%; Ficus microcarpa 40%; Mentha spicata 40%; Monstera adansonii 40%; Philodendron bipinnatifidum 40%; Radermachera 40%; Saintpaulia ionantha 40%; Aglaonema commutatum 60%; Aloe vera 60%

Most common confusions (true -> predicted): Dieffenbachia seguine -> Aglaonema commutatum (3); Philodendron erubescens -> Epipremnum aureum (3); Saintpaulia ionantha -> Streptocarpus (3); Schefflera actinophylla -> Schefflera arboricola (3); Calathea lancifolia -> Calathea makoyana (2); Ficus benjamina -> Ficus microcarpa (2); Howea forsteriana -> Dypsis lutescens (2); Monstera adansonii -> Monstera deliciosa (2); Aglaonema commutatum -> Dieffenbachia seguine (1); Aglaonema commutatum -> Hypoestes phyllostachya (1); Alocasia zebrina -> Dracaena trifasciata (1); Aloe vera -> Haworthia fasciata (1)

## Caveats

- Photos come from Commons categories, so labels can be noisy and many are cleaner than real phone photos. Treat every figure as an optimistic estimate.
- Splits are grouped by uploader where possible, but near-duplicate photo series can still leak between train and test.
- Embedding time on the 2-core runner (seconds): bioclip 500, bioclip2 2584, bioclip2_int8 2559, bioclip_fp32 1068, bioclip_int8 585, clip 423, dino 572. This is not phone speed.
- The out-of-list set is 20 wild/garden plant species and 8 non-plant categories, about 12 photos each.

## Export report: expdl/exp-bioclip/export_report.json
```
{
 "model": "bioclip",
 "preprocess": [
  "Resize(size=224, interpolation=bicubic, max_size=None, antialias=True)",
  "CenterCrop(size=(224, 224))",
  "MaybeConvertMode()",
  "MaybeToTensor()",
  "Normalize(mean=[0.48145466, 0.4578275, 0.40821073], std=[0.26862954, 0.26130258, 0.27577711])"
 ],
 "image_params_M": 86.2,
 "embedding_dim": 512,
 "text_embeddings_bytes": 109696,
 "export_seconds": 2,
 "fp32_MB": 345.1,
 "int8_MB": 89.3,
 "fp16_MB": 172.9,
 "fp16_load_error": "Fail('[ONNXRuntimeError] : 1 : FAIL : Load model from exp/bioclip/bioclip_image_fp16.onnx failed:Type Error: Type (tensor(float16)) of output arg (/v/Cast_output_0) of node (/v/Cast) does not match expected type (tensor(float)).')",
 "fp32_parity": {
  "cos_mean": 1.0,
  "cos_min": 1.0,
  "top1_same_as_torch": 1.0,
  "latency_ms_1thread_median": 406
 },
 "int8_parity": {
  "cos_mean": 0.96221,
  "cos_min": 0.92838,
  "top1_same_as_torch": 0.75,
  "latency_ms_1thread_median": 228
 },
 "fp32_full_embed_seconds": 1068,
 "int8_full_embed_seconds": 585
}```

## Export report: expdl/exp-bioclip2/export_report.json
```
{
 "model": "bioclip2",
 "preprocess": [
  "Resize(size=224, interpolation=bicubic, max_size=None, antialias=True)",
  "CenterCrop(size=(224, 224))",
  "MaybeConvertMode()",
  "MaybeToTensor()",
  "Normalize(mean=[0.48145466, 0.4578275, 0.40821073], std=[0.26862954, 0.26130258, 0.27577711])"
 ],
 "image_params_M": 304.0,
 "embedding_dim": 768,
 "text_embeddings_bytes": 164480,
 "export_seconds": 7,
 "fp32_MB": 1216.6,
 "int8_MB": 308.6,
 "fp16_MB": 608.9,
 "fp16_load_error": "Fail('[ONNXRuntimeError] : 1 : FAIL : Load model from exp/bioclip2/bioclip2_image_fp16.onnx failed:Type Error: Type (tensor(float16)) of output arg (/v/Cast_output_0) of node (/v/Cast) does not match expected type (tensor(float)).')",
 "fp32_parity": {
  "cos_mean": 1.0,
  "cos_min": 1.0,
  "top1_same_as_torch": 1.0,
  "latency_ms_1thread_median": 1812
 },
 "int8_parity": {
  "cos_mean": 0.98963,
  "cos_min": 0.96638,
  "top1_same_as_torch": 0.875,
  "latency_ms_1thread_median": 993
 },
 "int8_full_embed_seconds": 2559
}```
expdl/exp-bioclip/:
total 429160
drwxr-xr-x 2 runner runner      4096 Nov  1 00:54 .
drwxr-xr-x 4 runner runner      4096 Nov  1 00:54 ..
-rw-r--r-- 1 runner runner 345124167 Nov  1 00:54 bioclip_image_fp32.onnx
-rw-r--r-- 1 runner runner  89341523 Nov  1 00:54 bioclip_image_int8.onnx
-rw-r--r-- 1 runner runner   2427417 Nov  1 00:54 emb-bioclip_fp32.npz
-rw-r--r-- 1 runner runner   2429227 Nov  1 00:54 emb-bioclip_int8.npz
-rw-r--r-- 1 runner runner      1032 Nov  1 00:54 export_report.json
-rw-r--r-- 1 runner runner      2296 Nov  1 00:54 species.json
-rw-r--r-- 1 runner runner    109696 Nov  1 00:54 text_embeddings_fp16.npy

expdl/exp-bioclip2/:
total 1493204
drwxr-xr-x 2 runner runner       4096 Nov  1 00:54 .
drwxr-xr-x 4 runner runner       4096 Nov  1 00:54 ..
-rw-r--r-- 1 runner runner 1216572678 Nov  1 00:54 bioclip2_image_fp32.onnx
-rw-r--r-- 1 runner runner  308645666 Nov  1 00:54 bioclip2_image_int8.onnx
-rw-r--r-- 1 runner runner    3625661 Nov  1 00:54 emb-bioclip2_int8.npz
-rw-r--r-- 1 runner runner       1007 Nov  1 00:54 export_report.json
-rw-r--r-- 1 runner runner       2296 Nov  1 00:54 species.json
-rw-r--r-- 1 runner runner     164480 Nov  1 00:54 text_embeddings_fp16.npy
