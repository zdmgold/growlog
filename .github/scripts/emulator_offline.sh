#!/usr/bin/env bash
# End-to-end test of the offline identifier on an emulator: gate sheet, real model download, photo, result.
set -u
PKG=com.zdmgold.growlog
OUT=/tmp/emu; mkdir -p "$OUT"
APK=build/app/outputs/flutter-apk/app-debug.apk
LOG="$OUT/steps.txt"; : > "$LOG"
say(){ echo "$*" | tee -a "$LOG"; }
shot(){ adb exec-out screencap -p > "$OUT/$1.png"; say "shot $1"; }
dump(){ for i in 1 2 3; do adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 && break; sleep 2; done; adb pull /sdcard/ui.xml "$OUT/cur.xml" >/dev/null 2>&1; }
tap(){ dump; XY=$(python3 .github/scripts/ui_tap.py "$OUT/cur.xml" "$@") || { say "NOT FOUND: $*"; return 1; }; set -- $XY; adb shell input tap "$1" "$2"; say "tapped ($1,$2)"; sleep 3; return 0; }

adb install -r -g "$APK" >"$OUT/install.txt" 2>&1; say "install: $(tail -1 "$OUT/install.txt")"
adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS 2>/dev/null
adb logcat -c
adb shell am start -n "$PKG/.MainActivity" >/dev/null 2>&1; sleep 25
shot 01_home
tap "Open camera" "Scan a plant"; sleep 2; shot 02_gate
tap "Use the offline model"; shot 03_network_choice
tap "Use mobile data"; sleep 6; shot 04_downloading
T0=$(date +%s)
for i in $(seq 1 120); do
  if adb shell run-as "$PKG" ls files/offline_model_v1/installed.json >/dev/null 2>&1; then say "model installed after $(( $(date +%s) - T0 ))s"; break; fi
  if [ $((i % 6)) -eq 0 ]; then dump; say "progress: $(grep -o '[0-9]* MB of [0-9]* MB[^"]*' "$OUT/cur.xml" | head -1)"; fi
  sleep 10
done
adb shell run-as "$PKG" ls -la files/offline_model_v1 2>&1 | tee -a "$LOG"
sleep 6; shot 05_after_download
# in-app camera should be open now: press the shutter (bottom centre)
T1=$(date +%s); adb shell input tap 540 2162; sleep 4; shot 06_analyzing
RESULT="timeout"
for i in $(seq 1 60); do
  sleep 4; dump
  if grep -q -E "Save to garden" "$OUT/cur.xml"; then RESULT="guesses shown"; break; fi
  if grep -q -E "not sure what this is" "$OUT/cur.xml"; then RESULT="not sure"; break; fi
  if grep -q -E "Something went wrong" "$OUT/cur.xml"; then RESULT="error screen"; break; fi
done
say "result: $RESULT after $(( $(date +%s) - T1 ))s (emulator CPU, debug build)"
shot 07_result
python3 - <<'PY' | tee -a "$LOG"
import re
try:
    s=open('/tmp/emu/cur.xml',encoding='utf8').read()
    v=re.findall(r'(?:text|content-desc)="([^"]+)"',s)
    print('screen text:',' | '.join(dict.fromkeys(x for x in v if x.strip()))[:700])
except Exception as e: print('no dump',e)
PY

# ---- real plant photos through the Gallery picker ----
pick_first_thumb(){ python3 - "$1" <<'PYX'
import re, sys
import xml.etree.ElementTree as ET
best = None
for n in ET.parse(sys.argv[1]).getroot().iter("node"):
    rid = n.get("resource-id", "")
    desc = (n.get("content-desc") or "")
    if "icon_thumbnail" in rid or desc.lower().startswith("photo"):
        b = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", n.get("bounds", ""))
        if b:
            l, t, r, bt = map(int, b.groups())
            if r > l and bt > t and (best is None or (t, l) < best[0]):
                best = ((t, l), ((l + r) // 2, (t + bt) // 2))
if best:
    print(best[1][0], best[1][1])
else:
    sys.exit(1)
PYX
}
i=0
for f in $(ls /tmp/photos/*.jpg 2>/dev/null | sort); do
  base=$(basename "$f" .jpg); say "== photo $base =="
  adb push "$f" "/sdcard/Pictures/$base.jpg" >/dev/null 2>&1
  adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d "file:///sdcard/Pictures/$base.jpg" >/dev/null 2>&1; sleep 3
  adb shell am force-stop "$PKG"; sleep 2
  adb shell am start -n "$PKG/.MainActivity" >/dev/null 2>&1; sleep 14
  tap "Gallery" || { i=$((i+1)); continue; }
  sleep 5; shot "p${i}_picker"; dump
  XY=$(pick_first_thumb "$OUT/cur.xml") || XY="200 900"
  set -- $XY; adb shell input tap "$1" "$2"; say "picked thumbnail at ($1,$2)"
  T2=$(date +%s); R2="timeout"
  for k in $(seq 1 45); do
    sleep 4; dump
    if grep -q "Save to garden" "$OUT/cur.xml"; then R2="guesses shown"; break; fi
    if grep -q "not sure what this is" "$OUT/cur.xml"; then R2="not sure"; break; fi
    if grep -q "Something went wrong" "$OUT/cur.xml"; then R2="error screen"; break; fi
  done
  say "photo $base -> $R2 after $(( $(date +%s) - T2 ))s"
  shot "p${i}_result"
  python3 - <<'PYX' | tee -a "$LOG"
import re
try:
    s=open('/tmp/emu/cur.xml',encoding='utf8').read()
    v=re.findall(r'(?:text|content-desc)="([^"]+)"',s)
    print('  screen:',' | '.join(dict.fromkeys(x for x in v if x.strip()))[:420])
except Exception as e: print('  no dump',e)
PYX
  adb shell input keyevent 4; sleep 2
  i=$((i+1))
done

adb shell dumpsys meminfo "$PKG" 2>/dev/null | grep -E "TOTAL PSS|TOTAL RSS|Native Heap" | head -4 | tee -a "$LOG"
adb logcat -d > "$OUT/logcat_full.txt" 2>&1
grep -E " E (flutter|MethodChannel|AndroidRuntime|OrtJNI|onnx)|FATAL EXCEPTION|Unhandled Exception|PlatformException|OfflineModel|OfflineIdentify" "$OUT/logcat_full.txt" | cut -c1-300 | head -40 > "$OUT/errors.txt"
say "error lines: $(wc -l < "$OUT/errors.txt")"
exit 0
