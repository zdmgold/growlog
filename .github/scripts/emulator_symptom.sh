#!/usr/bin/env bash
# Runs inside the Android emulator: walks the Symptom Checker and the Add Plant species search.
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
sleep 25

shot(){ adb exec-out screencap -p > "$OUT/$1.png"; say "shot $1"; }
dump(){ for i in 1 2 3; do adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 && break; sleep 2; done; adb pull /sdcard/ui.xml "$OUT/${1:-cur}.xml" >/dev/null 2>&1; }
tap(){ dump cur; XY=$(python3 .github/scripts/ui_tap.py "$OUT/cur.xml" "$@") || { say "NOT FOUND: $*"; return 1; }; set -- $XY; adb shell input tap "$1" "$2"; say "tapped ($1,$2)"; sleep 2; return 0; }
has(){ dump cur; if grep -qi -- "$1" "$OUT/cur.xml"; then say "PASS: $2"; else say "FAIL: $2"; fi; }
back(){ adb shell input keyevent 4; sleep 2; }

# ---- Symptom checker
tap "Scans" && shot 01_scans
tap "Symptom checker" && shot 02_step1_where && has "Where is the problem" "step 1 shows"
tap "Leaves"; tap "Next"; shot 03_step2_what && has "What do you see" "step 2 shows"
tap "Yellowing leaves"; tap "Wilting or drooping"; shot 04_step2_selected; tap "Next"
shot 05_step3_pattern && has "How does it look" "step 3 shows"
tap "Older leaves first"; tap "Next"
shot 06_step4_context && has "What is going on" "step 4 shows"
tap "Soil stays wet"; tap "no drainage hole"; shot 07_step4_selected
tap "See results"; sleep 2; shot 08_results
has "Overwatering" "overwatering is ranked"
has "Most likely" "top result is labelled"
has "Check first" "top result is expanded"
for i in 1 2 3; do adb shell input swipe 540 1900 540 500 300; sleep 1; done
shot 08b_results_bottom
tap "Start over"; has "Where is the problem" "start over returns to step 1"
back; sleep 1
# ---- Plant page entry point is covered by compile; test Add Plant species search
tap "Garden"; tap "Add plant" "Add Plant" "Add new plant"; sleep 2; shot 09_add_plant
# Fields are tapped by position (the label is not a separate accessibility node).
adb shell input tap 540 1183; sleep 1; adb shell input text "monstera"; sleep 2; shot 10_suggestions
dump cur
if grep -q 'text="monstera"' "$OUT/cur.xml"; then say "PASS: text was typed into the species field"; else say "FAIL: species field did not receive text"; fi
if grep -qi "Swiss cheese plant" "$OUT/cur.xml"; then say "PASS: suggestion for Monstera deliciosa is listed"; else say "FAIL: no suggestion listed"; fi
tap "Swiss cheese plant" && sleep 1 && shot 11_applied
dump cur
if grep -q 'text="Monstera deliciosa"' "$OUT/cur.xml"; then say "PASS: species field filled with Monstera deliciosa"; else say "FAIL: species field not filled"; fi
if grep -q 'text="Swiss cheese plant"' "$OUT/cur.xml"; then say "PASS: name field filled with the common name"; else say "FAIL: name field not filled"; fi
if grep -qi "filled in from the guide" "$OUT/cur.xml"; then say "PASS: snackbar confirms schedule filled"; else say "NOTE: snackbar not seen in the dump (may have closed)"; fi
# A nickname in the name field must not show a "no match" box.
adb shell input tap 540 1005; sleep 1
for i in $(seq 1 25); do adb shell input keyevent 67; done
adb shell input text "Gerald"; sleep 2; shot 12_nickname
dump cur
if grep -q 'text="Gerald"' "$OUT/cur.xml"; then say "PASS: nickname typed"; else say "FAIL: nickname not typed"; fi
if grep -qi "No match in the care guide" "$OUT/cur.xml"; then say "FAIL: nickname shows no-match box"; else say "PASS: nickname shows no no-match box"; fi
adb logcat -d -s AndroidRuntime:E flutter:E > "$OUT/errors.txt" 2>&1
say "error lines: $(grep -c . "$OUT/errors.txt")"
