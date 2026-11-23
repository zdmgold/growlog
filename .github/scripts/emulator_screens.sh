#!/usr/bin/env bash
# Screens in every language: Home, Plant Page, Add Plant, Schedule and a full Symptom Checker run to a result.
# One plant is created in English, then each language is switched in turn. Each screen is checked for the expected
# localized text (from the ARB files and the symptom overlay files), English leaks, and overflow.
set -u
PKG=com.zdmgold.growlog
OUT=/tmp/emu; mkdir -p "$OUT"
APK=build/app/outputs/flutter-apk/app-debug.apk
LOG="$OUT/steps.txt"; : > "$LOG"
PASSES=0; FAILS=0; NOTFOUND=0
SC=.github/scripts/screens_check.py
say(){ echo "$*" | tee -a "$LOG"; }
adb install -r -g "$APK" >/dev/null 2>&1
adb shell settings put global hide_error_dialogs 1
adb logcat -c
shot(){ adb exec-out screencap -p > "$OUT/$1.png"; }
dump(){ local t; for t in 1 2 3; do adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 && break; sleep 2; done; adb pull /sdcard/ui.xml "$OUT/$1.xml" >/dev/null 2>&1; }
closed(){ adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null 2>&1; }
focused(){ adb shell dumpsys window 2>/dev/null | grep -E "mCurrentFocus" | head -1; }
infront(){ focused | grep -q "$PKG"; }
launch(){ adb shell am start -n "$PKG/.MainActivity" >/dev/null 2>&1; sleep "${1:-18}"; closed; sleep 1; }
ensure_app(){ infront && return 0; say "  (app not in front -> relaunching)"; launch 12; infront; }
allow_dialog(){ dump cur; if grep -q "send you notifications" "$OUT/cur.xml" 2>/dev/null; then XY=$(python3 .github/scripts/ui_tap.py "$OUT/cur.xml" "Allow") && { set -- $XY; adb shell input tap "$1" "$2"; sleep 2; say "  (notification dialog: tapped Allow)"; }; fi; }
tap(){ ensure_app; allow_dialog; dump cur; local XY; XY=$(python3 .github/scripts/ui_tap.py "$OUT/cur.xml" "$@") || { say "  NOT FOUND: $*"; NOTFOUND=$((NOTFOUND+1)); return 1; }; set -- $XY; adb shell input tap "$1" "$2"; sleep 2; return 0; }
scrolldn(){ adb shell input swipe 540 1700 540 600 300; sleep 1; }
scrollup(){ adb shell input swipe 540 600 540 2000 300; sleep 1; }
key(){ python3 $SC key "$1" "$2"; }
lid(){ python3 $SC labelid "$1" "$2"; }
overflow(){ adb logcat -d -s flutter | grep -c "overflowed"; }
capture(){ ensure_app; allow_dialog; dump "$1_a"; shot "$1_a"; }
capture_scroll(){ capture "$1"; scrolldn; dump "$1_b"; shot "$1_b"; scrolldn; dump "$1_c"; shot "$1_c"; }
verify(){ # name lang ratio items...
  local name=$1 l=$2 r=$3; shift 3; local xs=""; for s in a b c; do [ -f "$OUT/${name}_$s.xml" ] && xs="$xs,$OUT/${name}_$s.xml"; done; xs=${xs#,}
  local R; R=$(python3 $SC check "$l" "$r" "$xs" "$@"); echo "$R" | sed 's/^/  /' >> "$LOG"
  if echo "$R" | grep -q "RESULT PASS"; then say "PASS: $name"; PASSES=$((PASSES+1)); else say "FAIL: $name"; FAILS=$((FAILS+1)); echo "$R" | grep -E "MISSING|LEAK|found" | head -8 | sed 's/^/     /' | tee -a "$LOG" >/dev/null; fi; }

say "===== create one plant in English ====="
adb shell am force-stop $PKG; adb shell pm clear $PKG >/dev/null 2>&1
adb shell pm grant $PKG android.permission.POST_NOTIFICATIONS >/dev/null 2>&1
adb shell cmd locale set-app-locales $PKG --locales en >/dev/null 2>&1
launch 24
tap "Garden"; tap "Plants"; tap "Add plant" "Add Plant" "Add new plant"; sleep 2
scrolldn; scrollup; scrollup; sleep 1
dump cur; XY=$(python3 .github/scripts/ui_edit.py "$OUT/cur.xml" 0) && { set -- $XY; adb shell input tap "$1" "$2"; sleep 1; adb shell input text "Fern"; sleep 1; adb shell input keyevent 4; sleep 1; }
tap "Maidenhair fern"; sleep 1; scrolldn; scrolldn; scrolldn
for t in 1 2 3; do tap "Save Plant" && break; scrolldn; sleep 2; done; sleep 4
tap "Garden"; sleep 2; tap "Plants"; sleep 1; dump plantcheck; shot plantcheck
if grep -q "Fern" "$OUT/plantcheck.xml"; then say "plant created: yes"; else say "plant created: NOT CONFIRMED"; fi

for entry in ar:ar he:he ko:ko zh:zh-CN ja:ja de:de hi:hi fr:fr es:es pt:pt; do
  L=${entry%%:*}; TAG=${entry#*:}
  say "===== $L ($TAG) ====="
  adb shell am force-stop $PKG; adb shell cmd locale set-app-locales $PKG --locales "$TAG" >/dev/null 2>&1
  launch 22; OV0=$(overflow)
  capture ${L}_home; verify ${L}_home $L 1.0 navHome navGarden navSchedule scanAPlant
  for t in 1 2 3; do tap "Fern" && break; scrolldn; done; sleep 3
  capture_scroll ${L}_plant; verify ${L}_plant $L 0.5 careTitle logCareNow growthTitle doctorTitle editScheduleAction
  adb shell input keyevent 4; sleep 2
  tap "$(key $L navGarden)"; sleep 2; tap "$(key $L addPlant)" "$(key $L navAddPlant)"; sleep 2
  capture_scroll ${L}_add; verify ${L}_add $L 0.6 addPlantScreenTitle plantNameLabel speciesLabel careSchedule waterEvery savePlant
  adb shell input keyevent 4; sleep 1; adb shell input keyevent 4; sleep 2
  tap "$(key $L navSchedule)"; sleep 2; capture ${L}_schedule; verify ${L}_schedule $L 0.6 dueNow upcoming all
  tap "$(key $L scansTab)"; sleep 2; tap "$(key $L symptomCheckerTitle)"; sleep 2
  capture ${L}_sym1; verify ${L}_sym1 $L 0.6 symptomCheckerTitle symptomStepWhere symptomNext sym:leaves
  tap "$(lid $L leaves)"; tap "$(key $L symptomNext)"; sleep 2
  capture ${L}_sym2; verify ${L}_sym2 $L 0.6 symptomStepWhat sym:yellowing sym:wilting
  tap "$(lid $L yellowing)"; tap "$(lid $L wilting)"; tap "$(key $L symptomNext)"; sleep 2
  tap "$(lid $L age_old)"; tap "$(key $L symptomNext)"; sleep 2
  tap "$(lid $L wet_soil)"; tap "$(lid $L no_drainage)"; capture ${L}_sym4; verify ${L}_sym4 $L 0.5 symptomStepContext sym:wet_soil sym:no_drainage
  tap "$(key $L symptomSeeResults)"; sleep 3
  capture_scroll ${L}_results; verify ${L}_results $L 0.5 prob:overwatering symptomMostLikely symptomResultsTitle
  say "  overflow lines in $L: $(( $(overflow) - OV0 ))"
  adb shell input keyevent 4; sleep 1; adb shell input keyevent 4; sleep 1; adb shell input keyevent 4; sleep 1
done
adb logcat -d -s flutter | grep -i -B1 -A6 "overflowed" | cut -c1-200 > "$OUT/overflow.txt"
adb logcat -d -s AndroidRuntime:E flutter:E > "$OUT/errors.txt" 2>&1
say "overflow lines total: $(overflow)"; say "error lines: $(grep -c . "$OUT/errors.txt")"; say "GrowLog-related error lines: $(grep -ciE 'growlog|flutter' "$OUT/errors.txt")"
say "SUMMARY pass=$PASSES fail=$FAILS notfound=$NOTFOUND"
