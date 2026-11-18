#!/usr/bin/env bash
# Language stress test: per-app language from the system side, a manual choice, a restart, and "phone default".
set -u
PKG=com.zdmgold.growlog
OUT=/tmp/emu; mkdir -p "$OUT"
APK=build/app/outputs/flutter-apk/app-debug.apk
LOG="$OUT/steps.txt"; : > "$LOG"
say(){ echo "$*" | tee -a "$LOG"; }
adb install -r -g "$APK" >/dev/null 2>&1
adb shell settings put global hide_error_dialogs 1
adb logcat -c
shot(){ adb exec-out screencap -p > "$OUT/$1.png"; }
dump(){ for i in 1 2 3; do adb shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1 && break; sleep 2; done; adb pull /sdcard/ui.xml "$OUT/$1.xml" >/dev/null 2>&1; }
closed(){ adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null 2>&1; }
tap(){ dump cur; XY=$(python3 .github/scripts/ui_tap.py "$OUT/cur.xml" "$@") || { say "  NOT FOUND: $*"; return 1; }; set -- $XY; adb shell input tap "$1" "$2"; sleep 2; return 0; }
launch(){ adb shell am start -n "$PKG/.MainActivity" >/dev/null 2>&1; sleep "${1:-18}"; closed; sleep 1; }
txt(){ python3 .github/scripts/lang_check.py text "$1" "$2"; }
check(){ # name, lang, rtl
  dump "$1"; shot "$1"; R=$(python3 .github/scripts/lang_check.py check "$OUT/$1.xml" "$2" "$3"); echo "$R" | sed 's/^/  /' >> "$LOG"
  echo "$R" | grep -q "RESULT PASS" && say "PASS: $1" || say "FAIL: $1"; }
overflow(){ adb logcat -d -s flutter | grep -c "overflowed"; }

LANGS="en:en:0 es:es:0 fr:fr:0 de:de:0 pt:pt:0 ar:ar:1 hi:hi:0 ja:ja:0 ko:ko:0 zh:zh-CN:0 he:he:1"
NEXTS=(es fr de pt ar hi ja ko zh he en)
NAMES=("Español" "Français" "Deutsch" "Português" "العربية" "हिन्दी" "日本語" "한국어" "中文" "עברית" "English")
RTLS=(0 0 0 0 1 0 0 0 0 1 0)
i=0
for entry in $LANGS; do
  L=${entry%%:*}; rest=${entry#*:}; TAG=${rest%%:*}; RTL=${rest##*:}
  N=${NEXTS[$i]}; NN=${NAMES[$i]}; NRTL=${RTLS[$i]}
  say "===== system language $L ($TAG), manual choice $N ====="
  adb shell am force-stop $PKG; adb shell pm clear $PKG >/dev/null 2>&1
  adb shell cmd locale set-app-locales $PKG --locales "$TAG" >/dev/null 2>&1
  launch 22
  check "${L}_01_first_launch" "$L" "$RTL"
  tap "$(txt $L navGarden)" && check "${L}_02_garden" "$L" "$RTL"
  tap "$(txt $L navSchedule)" && check "${L}_03_schedule" "$L" "$RTL"
  tap "$(txt $L navHome)"
  # Settings by position (header icons: LTR on the right, RTL on the left)
  if [ "$RTL" = 1 ]; then SX=127; LX=421; else SX=953; LX=659; fi
  adb shell input tap $SX 232; sleep 3; closed; shot "${L}_04_settings"
  adb shell input keyevent 4; sleep 2
  # manual choice
  adb shell input tap $LX 232; sleep 3; closed; shot "${L}_05_language_sheet"
  tap "$NN" && sleep 3
  check "${L}_06_manual_$N" "$N" "$NRTL"
  # restart keeps the manual choice
  adb shell am force-stop $PKG; sleep 2; launch 18
  check "${L}_07_after_restart_$N" "$N" "$NRTL"
  # phone default returns to the system language
  if [ "$NRTL" = 1 ]; then LX2=421; else LX2=659; fi
  adb shell input tap $LX2 232; sleep 3; closed
  tap "$(txt $N phoneDefault)" && sleep 3
  check "${L}_08_phone_default" "$L" "$RTL"
  say "  overflow lines so far: $(overflow)"
  i=$((i+1))
done

say "===== unsupported and variant system languages ====="
adb shell am force-stop $PKG; adb shell pm clear $PKG >/dev/null 2>&1
adb shell cmd locale set-app-locales $PKG --locales "sw-KE" >/dev/null 2>&1; launch 22
check "x_swahili_falls_back_to_english" en 0
adb shell am force-stop $PKG; adb shell pm clear $PKG >/dev/null 2>&1
adb shell cmd locale set-app-locales $PKG --locales "zh-TW" >/dev/null 2>&1; launch 22
check "x_traditional_chinese_shows_simplified" zh 0
adb logcat -d -s flutter | grep -i -B1 -A6 "overflowed" | cut -c1-200 > "$OUT/overflow.txt"
adb logcat -d -s AndroidRuntime:E flutter:E > "$OUT/errors.txt" 2>&1
say "overflow lines total: $(overflow)"; say "error lines: $(grep -c . "$OUT/errors.txt")"
