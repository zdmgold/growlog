#!/usr/bin/env bash
# Language stress test: system language, manual choice, restart, "phone default", unsupported/variant system languages.
# Every check first makes sure the app itself is in the foreground (a launcher screenshot is a FAIL, never a pass).
set -u
PKG=com.zdmgold.growlog
OUT=/tmp/emu; mkdir -p "$OUT"
APK=build/app/outputs/flutter-apk/app-debug.apk
LOG="$OUT/steps.txt"; : > "$LOG"
PASSES=0; FAILS=0; NOTFOUND=0
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
ensure_app(){ infront && return 0; say "  (app not in front: $(focused | cut -c1-90) -> relaunching)"; launch 12; infront; }
allow_dialog(){ dump cur; if grep -q "send you notifications" "$OUT/cur.xml" 2>/dev/null; then XY=$(python3 .github/scripts/ui_tap.py "$OUT/cur.xml" "Allow") && { set -- $XY; adb shell input tap "$1" "$2"; sleep 2; say "  (notification dialog was showing; tapped Allow)"; }; fi; }
tap(){ ensure_app; allow_dialog; dump cur; local XY; XY=$(python3 .github/scripts/ui_tap.py "$OUT/cur.xml" "$@") || { say "  NOT FOUND: $*"; NOTFOUND=$((NOTFOUND+1)); return 1; }; set -- $XY; adb shell input tap "$1" "$2"; sleep 2; return 0; }
txt(){ python3 .github/scripts/lang_check.py text "$1" "$2"; }
check(){ # name, lang, rtl, [expect]  expect=fail for the negative control
  ensure_app; allow_dialog; dump "$1"; shot "$1"
  local R; R=$(python3 .github/scripts/lang_check.py check "$OUT/$1.xml" "$2" "$3"); echo "$R" | sed 's/^/  /' >> "$LOG"
  if echo "$R" | grep -q "RESULT PASS"; then got=pass; else got=fail; fi
  want=${4:-pass}
  if [ "$got" = "$want" ]; then say "PASS: $1"; PASSES=$((PASSES+1)); else say "FAIL: $1 (wanted $want, got $got)"; FAILS=$((FAILS+1)); fi; }
fresh(){ # tag
  adb shell am force-stop $PKG; adb shell pm clear $PKG >/dev/null 2>&1
  adb shell pm grant $PKG android.permission.POST_NOTIFICATIONS >/dev/null 2>&1
  adb shell cmd locale set-app-locales $PKG --locales "$1" >/dev/null 2>&1
  adb shell cmd locale get-app-locales $PKG 2>&1 | head -1 | sed 's/^/  locale set: /' >> "$LOG"; }
overflow(){ adb logcat -d -s flutter | grep -c "overflowed"; }

LANGS=(en:en:0 es:es:0 fr:fr:0 de:de:0 pt:pt:0 ar:ar:1 hi:hi:0 ja:ja:0 ko:ko:0 zh:zh-CN:0 he:he:1)
NEXTS=(es fr de pt ar hi ja ko zh he en)
NAMES=("Español" "Français" "Deutsch" "Português" "العربية" "हिन्दी" "日本語" "한국어" "中文" "עברית" "English")
RTLS=(0 0 0 0 1 0 0 0 0 1 0)

for idx in "${!LANGS[@]}"; do
  entry=${LANGS[$idx]}
  L=${entry%%:*}; rest=${entry#*:}; TAG=${rest%%:*}; RTL=${rest##*:}
  N=${NEXTS[$idx]}; NN=${NAMES[$idx]}; NRTL=${RTLS[$idx]}
  say "===== system language $L ($TAG), manual choice $N ====="
  fresh "$TAG"; launch 22
  check "${L}_01_first_launch" "$L" "$RTL"
  if [ "$L" = en ]; then check "en_01b_negative_control_must_not_look_german" de 0 fail; fi
  tap "$(txt $L navGarden)" && check "${L}_02_garden" "$L" "$RTL"
  tap "$(txt $L navSchedule)" && check "${L}_03_schedule" "$L" "$RTL"
  tap "$(txt $L navHome)"
  tap "$(txt $L navSettings)" && { sleep 2; shot "${L}_04_settings"; adb shell input keyevent 4; sleep 2; }
  tap "$(txt $L headerChangeLanguage)" && { sleep 2; shot "${L}_05_language_sheet"; }
  tap "$NN" && sleep 3
  check "${L}_06_manual_$N" "$N" "$NRTL"
  adb shell am force-stop $PKG; sleep 2; launch 18
  check "${L}_07_after_restart_$N" "$N" "$NRTL"
  tap "$(txt $N headerChangeLanguage)" && sleep 2
  tap "$(txt $N phoneDefault)" && sleep 3
  check "${L}_08_phone_default" "$L" "$RTL"
  say "  overflow lines so far: $(overflow)"
done

say "===== unsupported and variant system languages ====="
fresh "sw-KE"; launch 22; check "x_swahili_falls_back_to_english" en 0
fresh "zh-TW"; launch 22; check "x_traditional_chinese_shows_simplified" zh 0
adb logcat -d -s flutter | grep -i -B1 -A6 "overflowed" | cut -c1-200 > "$OUT/overflow.txt"
adb logcat -d -s AndroidRuntime:E flutter:E > "$OUT/errors.txt" 2>&1
say "overflow lines total: $(overflow)"; say "error lines: $(grep -c . "$OUT/errors.txt")"
say "SUMMARY pass=$PASSES fail=$FAILS notfound=$NOTFOUND"
