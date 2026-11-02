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
adb shell dumpsys meminfo "$PKG" 2>/dev/null | grep -E "TOTAL PSS|TOTAL RSS|Native Heap" | head -4 | tee -a "$LOG"
adb logcat -d > "$OUT/logcat_full.txt" 2>&1
grep -E " E (flutter|MethodChannel|AndroidRuntime|OrtJNI|onnx)|FATAL EXCEPTION|Unhandled Exception|PlatformException|OfflineModel|OfflineIdentify" "$OUT/logcat_full.txt" | cut -c1-300 | head -40 > "$OUT/errors.txt"
say "error lines: $(wc -l < "$OUT/errors.txt")"
exit 0
