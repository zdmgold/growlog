#!/usr/bin/env bash
# Emulator accessibility pass at 200% text size: tap-target sizes, labels, overflow messages.
set -u
PKG=com.zdmgold.growlog
OUT=/tmp/emu; mkdir -p "$OUT"
APK=build/app/outputs/flutter-apk/app-debug.apk
LOG="$OUT/steps.txt"; : > "$LOG"; A11Y="$OUT/a11y.txt"; : > "$A11Y"
say(){ echo "$*" | tee -a "$LOG"; }
adb install -r -g "$APK" >/dev/null 2>&1
adb shell settings put system font_scale 2.0
adb shell settings put global hide_error_dialogs 1
adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null 2>&1
DENS=$(adb shell wm density | grep -o '[0-9]\+' | tail -1); say "density=$DENS font_scale=$(adb shell settings get system font_scale)"
adb logcat -c
adb shell am start -W -n "$PKG/.MainActivity" >/dev/null 2>&1; sleep 25
shot(){ adb exec-out screencap -p > "$OUT/$1.png"; }
dump(){ for i in 1 2 3; do adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 && break; sleep 2; done; adb pull /sdcard/ui.xml "$OUT/$1.xml" >/dev/null 2>&1; }
tap(){ dump cur; XY=$(python3 .github/scripts/ui_tap.py "$OUT/cur.xml" "$@") || { say "NOT FOUND: $*"; return 1; }; set -- $XY; adb shell input tap "$1" "$2"; sleep 2; return 0; }
visit(){ sleep 1; adb logcat -d -s flutter | grep -c overflowed | sed "s/^/overflow-count-before-$1: /" >> "$OUT/steps.txt"; shot "$1"; dump "$1"; python3 .github/scripts/a11y_scan.py "$OUT/$1.xml" "$1" "$DENS" | tee -a "$A11Y"; }
back(){ adb shell input keyevent 4; sleep 2; }
scroll(){ adb shell input swipe 540 1700 540 600 300; sleep 1; }

visit 01_home
scroll; visit 02_home_scrolled; scroll; scroll; visit 03_home_bottom
adb shell input swipe 540 600 540 2000 300; adb shell input swipe 540 600 540 2000 300
tap "Garden" && visit 04_garden
tap "Wishlist" && visit 05_wishlist
tap "Rooms" && visit 06_rooms
tap "Plants"; tap "Add plant" "Add Plant" && visit 07_add_plant
scroll; visit 08_add_plant_scrolled
# Create a plant, then check the Plant Page
scroll; adb shell input swipe 540 600 540 2000 300; adb shell input swipe 540 600 540 2000 300; sleep 1
dump cur; XY=$(python3 .github/scripts/ui_edit.py "$OUT/cur.xml" 0) && { set -- $XY; adb shell input tap "$1" "$2"; sleep 1; adb shell input text "Fern"; sleep 1; adb shell input keyevent 4; sleep 1; }
tap "Maidenhair fern"; sleep 1; shot 08b_species_applied; scroll; scroll; scroll; for i in 1 2 3; do tap "Save Plant" && break; scroll; sleep 2; done; sleep 4; shot 08c_after_save
tap "Garden"; sleep 2; for i in 1 2 3; do tap "Fern" && break; sleep 3; done; sleep 2; visit 18_plant_page
scroll; visit 19_plant_page_scrolled; scroll; visit 20_plant_page_bottom
back; back
tap "Schedule" && visit 09_schedule
tap "Scans" && visit 10_scans
tap "Symptom checker" && visit 11_symptom_step1
tap "Leaves"; tap "Next" && visit 12_symptom_step2
tap "Yellowing leaves"; scroll; visit 13_symptom_step2_scrolled
back; back; back
tap "Home"
dump cur; XY=$(python3 .github/scripts/ui_tap.py "$OUT/cur.xml" "Settings" "settings") && { set -- $XY; adb shell input tap "$1" "$2"; sleep 2; }
visit 14_settings_or_home
scroll; visit 15_settings_scrolled
back
scroll; tap "Set up plant identification" && visit 16_gate_sheet
tap "Use my own AI key" && visit 17_connect_ai
adb logcat -d -s flutter | grep -i -A14 "overflowed" | cut -c1-200 > "$OUT/overflow.txt"
say "overflow lines: $(grep -c . "$OUT/overflow.txt")"
adb logcat -d -s AndroidRuntime:E flutter:E > "$OUT/errors.txt" 2>&1; say "error lines: $(grep -c . "$OUT/errors.txt")"
