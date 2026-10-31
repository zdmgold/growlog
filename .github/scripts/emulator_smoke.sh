#!/usr/bin/env bash
# Runs inside the Android emulator: installs the debug APK, walks the main screens, collects screenshots and logs.
set -u
PKG=com.zdmgold.growlog
OUT=/tmp/emu; mkdir -p "$OUT"
APK=build/app/outputs/flutter-apk/app-debug.apk
LOG="$OUT/steps.txt"; : > "$LOG"
say(){ echo "$*" | tee -a "$LOG"; }

adb install -r -g "$APK" >"$OUT/install.txt" 2>&1; say "install: $(tail -1 "$OUT/install.txt")"
adb shell pm grant "$PKG" android.permission.POST_NOTIFICATIONS 2>/dev/null
adb logcat -c
adb shell am start -W -n "$PKG/.MainActivity" > "$OUT/start.txt" 2>&1
say "cold start (debug build): $(grep -E 'TotalTime|WaitTime' "$OUT/start.txt" | tr '\n' ' ')"
sleep 25

shot(){ adb exec-out screencap -p > "$OUT/$1.png"; say "shot $1 $(stat -c %s "$OUT/$1.png" 2>/dev/null)B"; }
dump(){ for i in 1 2 3; do adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 && break; sleep 2; done; adb pull /sdcard/ui.xml "$OUT/$1.xml" >/dev/null 2>&1; }
tap(){ # tap LABEL... ; returns 0 if tapped
  dump cur
  XY=$(python3 .github/scripts/ui_tap.py "$OUT/cur.xml" "$@") || { say "NOT FOUND: $*"; return 1; }
  set -- $XY; adb shell input tap "$1" "$2"; say "tapped ($1,$2)"; sleep 4; return 0; }

shot 01_home
dump home; cp "$OUT/home.xml" "$OUT/home_ui.xml" 2>/dev/null
say "labels on home: $(python3 - <<'PY'
import re,sys
try:
    s=open('/tmp/emu/home.xml',encoding='utf8').read()
    v=re.findall(r'(?:text|content-desc)="([^"]+)"',s)
    print(' | '.join(dict.fromkeys(x for x in v if x.strip()))[:900])
except Exception as e: print('no ui dump',e)
PY
)"
tap "Garden" && shot 02_garden
tap "Schedule" && shot 03_schedule
tap "Scans" && shot 04_scans
tap "Home" && shot 05_home_again
tap "Change language" && shot 06_language && adb shell input keyevent 4 && sleep 2
tap "Settings" && shot 07_settings && adb shell input keyevent 4 && sleep 2
tap "Add your API key" "Connect AI" && shot 08_connect_ai && adb shell input keyevent 4 && sleep 2
tap "Open camera" "Scan a plant" && sleep 6 && shot 09_camera && adb shell input keyevent 4 && sleep 2
tap "Garden" && tap "Add Plant" "Add new plant" && shot 10_add_plant && adb shell input keyevent 4 && sleep 2

PID=$(adb shell pidof "$PKG" | tr -d '\r'); say "process alive: ${PID:-NO}"
adb shell dumpsys meminfo "$PKG" 2>/dev/null | grep -E "TOTAL PSS|TOTAL:|Java Heap|Native Heap|Graphics" | head -6 > "$OUT/meminfo.txt"; cat "$OUT/meminfo.txt" | tee -a "$LOG"
adb logcat -d > "$OUT/logcat_full.txt" 2>&1
grep -E "FATAL EXCEPTION|AndroidRuntime|Unhandled Exception|RenderFlex overflowed|EXCEPTION CAUGHT|E/flutter" "$OUT/logcat_full.txt" | head -40 > "$OUT/errors.txt"
say "error lines: $(wc -l < "$OUT/errors.txt")"
grep -i -E "Ads|GADMobile|AdMob|MobileAds" "$OUT/logcat_full.txt" | head -25 > "$OUT/ads.txt"; say "ads log lines: $(wc -l < "$OUT/ads.txt")"
grep -E "flutter" "$OUT/logcat_full.txt" | tail -60 > "$OUT/flutter_tail.txt"
exit 0
