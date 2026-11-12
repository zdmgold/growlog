#!/usr/bin/env bash
# Proves the file clean-up on a real emulator: startup sweep and Clear All Data.
set -u
PKG=com.zdmgold.growlog
OUT=/tmp/emu; mkdir -p "$OUT"
APK=build/app/outputs/flutter-apk/app-debug.apk
LOG="$OUT/steps.txt"; : > "$LOG"
say(){ echo "$*" | tee -a "$LOG"; }
adb install -r -g "$APK" >/dev/null 2>&1
adb shell settings put global hide_error_dialogs 1
shot(){ adb exec-out screencap -p > "$OUT/$1.png"; }
dump(){ for i in 1 2 3; do adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 && break; sleep 2; done; adb pull /sdcard/ui.xml "$OUT/$1.xml" >/dev/null 2>&1; }
tap(){ dump cur; XY=$(python3 .github/scripts/ui_tap.py "$OUT/cur.xml" "$@") || { say "NOT FOUND: $*"; return 1; }; set -- $XY; adb shell input tap "$1" "$2"; sleep 2; return 0; }
ls_docs(){ adb shell "run-as $PKG sh -c 'ls -1 app_flutter 2>/dev/null'" | tr -d '\r'; }
U1=aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa; U2=bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb
U3=cccccccc-cccc-4ccc-8ccc-cccccccccccc; U4=dddddddd-dddd-4ddd-8ddd-dddddddddddd
make(){ adb shell "run-as $PKG sh -c 'mkdir -p app_flutter; echo x > app_flutter/$1; touch -d \"$2\" app_flutter/$1'"; }

# first launch creates the app folders and database
adb shell am start -W -n "$PKG/.MainActivity" >/dev/null 2>&1; sleep 20
adb shell am force-stop "$PKG"; sleep 2
make "plant_$U1.jpg" "2026-11-01 10:00:00"      # old orphan: must be swept
make "scan_$U2.jpg"  "2026-11-01 10:00:00"      # old orphan: must be swept
make "plant_$U3.jpg" "$(date -u '+%Y-%m-%d %H:%M:%S')"   # fresh orphan: must stay (Undo window)
make "notes_keep.txt" "2026-11-01 10:00:00"      # not an app photo name: must stay
say "before start:"; ls_docs | sed 's/^/  /' | tee -a "$LOG"
adb shell am start -W -n "$PKG/.MainActivity" >/dev/null 2>&1; sleep 25
say "after start:"; ls_docs | sed 's/^/  /' | tee -a "$LOG"
A=$(ls_docs)
echo "$A" | grep -q "plant_$U1.jpg" && say "FAIL: old orphan plant photo was kept" || say "PASS: old orphan plant photo swept"
echo "$A" | grep -q "scan_$U2.jpg"  && say "FAIL: old orphan scan photo was kept"  || say "PASS: old orphan scan photo swept"
echo "$A" | grep -q "plant_$U3.jpg" && say "PASS: fresh orphan kept (Undo window)" || say "FAIL: fresh orphan was deleted"
echo "$A" | grep -q "notes_keep.txt" && say "PASS: non-photo file untouched" || say "FAIL: non-photo file deleted"

# Clear All Data removes every app photo regardless of age
make "plant_$U4.jpg" "$(date -u '+%Y-%m-%d %H:%M:%S')"
shot 01_before_clear
dump cur; XY=$(python3 .github/scripts/ui_tap.py "$OUT/cur.xml" "Settings" "settings") && { set -- $XY; adb shell input tap "$1" "$2"; sleep 2; }
adb shell input swipe 540 1700 540 600 300; sleep 1
tap "Clear All Data" ; sleep 2; shot 02_confirm
tap "Delete" "Clear" ; sleep 4; shot 03_after_clear
say "after Clear All Data:"; ls_docs | sed 's/^/  /' | tee -a "$LOG"
B=$(ls_docs)
echo "$B" | grep -Eq "^(plant|scan)_" && say "FAIL: app photo files remain after Clear All Data" || say "PASS: no app photo files after Clear All Data"
echo "$B" | grep -q "notes_keep.txt" && say "PASS: non-photo file still untouched" || say "FAIL: non-photo file deleted by Clear All"
adb logcat -d -s AndroidRuntime:E flutter:E > "$OUT/errors.txt" 2>&1; say "error lines: $(grep -c . "$OUT/errors.txt")"
