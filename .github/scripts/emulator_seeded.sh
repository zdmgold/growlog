#!/usr/bin/env bash
# Seeded run: 17 plants / 3 rooms / overdue and due-in-N-days care / photo sets / Doctor scans / wishlist are written into
# the app database, then Home, Schedule, Garden (Plants, Rooms, Wishlist), four Plant Pages, Settings, Connect AI (no key) and
# Paul's chat (no key) are checked in 10 languages. Count-dependent strings are checked EXACTLY (an ICU evaluator that follows
# Dart's plural rules) so Arabic few/many and Hebrew dual forms are seen on screen.
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
key(){ python3 $SC key "$1" "$2"; }
overflow(){ adb logcat -d -s flutter | grep -c "overflowed"; }
capture(){ ensure_app; allow_dialog; dump "$1_a"; shot "$1_a"; }
capture_scroll(){ capture "$1"; scrolldn; dump "$1_b"; shot "$1_b"; scrolldn; dump "$1_c"; shot "$1_c"; }
verify(){ local name=$1 l=$2 r=$3; shift 3; local xs=""; for s in a b c; do [ -f "$OUT/${name}_$s.xml" ] && xs="$xs,$OUT/${name}_$s.xml"; done; xs=${xs#,}
  local R; R=$(python3 $SC check "$l" "$r" "$xs" "$@"); echo "$R" | sed 's/^/  /' >> "$LOG"
  if echo "$R" | grep -q "RESULT PASS"; then say "PASS: $name"; PASSES=$((PASSES+1)); else say "FAIL: $name"; FAILS=$((FAILS+1)); echo "$R" | grep -E "MISSING|LEAK|found" | head -8 | sed 's/^/     /' | tee -a "$LOG" >/dev/null; fi; }
openplant(){ # lang name
  tap "$(key $1 navGarden)"; sleep 2; tap "$(key $1 plantsTab)"; sleep 1
  local PC; PC=$(key $1 plantCardAccessibility | sed "s/{plantName}/$2/")
  for t in 1 2 3 4; do tap "$PC" && break; scrolldn; done; sleep 3; }

say "===== seed the database ====="
adb shell am force-stop $PKG; adb shell pm clear $PKG >/dev/null 2>&1
adb shell pm grant $PKG android.permission.POST_NOTIFICATIONS >/dev/null 2>&1
adb shell cmd locale set-app-locales $PKG --locales en >/dev/null 2>&1
launch 24; adb shell am force-stop $PKG; sleep 2
adb exec-out run-as $PKG cat databases/growlog.db > /tmp/growlog.db
say "database pulled: $(stat -c %s /tmp/growlog.db) bytes"
adb shell run-as $PKG mkdir -p files
n=0; for f in $(ls /tmp/photos/*.jpg 2>/dev/null | head -3); do adb push "$f" /data/local/tmp/seed_$n.jpg >/dev/null 2>&1; adb shell run-as $PKG cp /data/local/tmp/seed_$n.jpg files/seed_$n.jpg; n=$((n+1)); done
say "photos copied into the app: $n"
python3 .github/scripts/seed_db.py /tmp/growlog.db /data/data/$PKG/files | tee -a "$LOG"
adb push /tmp/growlog.db /data/local/tmp/growlog.db >/dev/null 2>&1
adb shell run-as $PKG cp /data/local/tmp/growlog.db databases/growlog.db
adb shell run-as $PKG rm -f databases/growlog.db-wal databases/growlog.db-shm databases/growlog.db-journal
launch 22; capture seed_en_home
verify seed_en_home en 1.0 "fmt:statusDue:count=15" navHome navGarden

for entry in ar:ar he:he ko:ko zh:zh-CN ja:ja de:de hi:hi fr:fr es:es pt:pt; do
  L=${entry%%:*}; TAG=${entry#*:}
  say "===== $L ($TAG) ====="
  adb shell am force-stop $PKG; adb shell cmd locale set-app-locales $PKG --locales "$TAG" >/dev/null 2>&1
  launch 22; OV0=$(overflow)
  capture ${L}_home; verify ${L}_home $L 1.0 navHome navGarden navSchedule "fmt:statusDue:count=15"
  tap "$(key $L navSchedule)"; sleep 2; capture_scroll ${L}_schedule
  verify ${L}_schedule $L 0.5 dueNow "fmt:overdueDays:count=15" "fmt:overdueDays:count=5" "fmt:overdueDays:count=2" "fmt:overdueDays:count=1"
  tap "$(key $L navGarden)"; sleep 2; tap "$(key $L plantsTab)"; sleep 1; capture ${L}_garden
  verify ${L}_garden $L 0.0 "fmt:plantCountLabel:count=17" plantsTab
  tap "$(key $L roomsTitle)"; sleep 2; capture ${L}_rooms
  verify ${L}_rooms $L 0.6 "fmt:roomCardAccessibility:count=12,roomName=Room C" "fmt:roomCardAccessibility:count=3,roomName=Room B" "fmt:roomCardAccessibility:count=2,roomName=Room A"
  tap "$(key $L wishlistTitle)"; sleep 2; capture ${L}_wishlist; verify ${L}_wishlist $L 0.5 "text:Wish A" "text:Wish B"
  openplant $L P01; capture_scroll ${L}_p01; verify ${L}_p01 $L 0.5 "fmt:photosCount:count=3" "fmt:overdueDays:count=2" doctorTitle
  adb shell input keyevent 4; sleep 2
  openplant $L P03; capture_scroll ${L}_p03; verify ${L}_p03 $L 0.5 "fmt:photosCount:count=11" "fmt:overdueDays:count=5"
  adb shell input keyevent 4; sleep 2
  openplant $L P05; capture_scroll ${L}_p05; verify ${L}_p05 $L 0.5 "fmt:careDueInDays:count=5"
  adb shell input keyevent 4; sleep 2
  openplant $L P17; capture_scroll ${L}_p17; verify ${L}_p17 $L 0.5 "fmt:careDueInDays:count=12"
  adb shell input keyevent 4; sleep 2
  tap "$(key $L navHome)"; sleep 2
  tap "$(key $L navSettings)"; sleep 2; capture_scroll ${L}_settings
  verify ${L}_settings $L 0.5 settingsTitle theme themeSystem themeLight themeDark notifications backupRestore exportData importData about version privacyPolicy termsOfService storageSection
  adb shell input keyevent 4; sleep 2
  tap "$(key $L offSetupTitle)"; sleep 2; tap "$(key $L offUseKey)"; sleep 3; capture ${L}_connectai
  verify ${L}_connectai $L 0.6 connectAiTitle chooseProvider hintPayAsYouGo hintFreeTier hintCheckPricing hintSomeFree
  adb shell input keyevent 4; sleep 2; ensure_app; tap "$(key $L navHome)"; sleep 2
  tap "$(key $L askPaul)"; sleep 3; capture ${L}_paul; verify ${L}_paul $L 0.6 paulNeedsConnection connectAiToChat notConnected
  adb shell input keyevent 4; sleep 2
  say "  overflow lines in $L: $(( $(overflow) - OV0 ))"
done
adb logcat -d -s flutter | grep -i -B1 -A6 "overflowed" | cut -c1-200 > "$OUT/overflow.txt"
adb logcat -d -s AndroidRuntime:E flutter:E > "$OUT/errors.txt" 2>&1
say "overflow lines total: $(overflow)"; say "error lines: $(grep -c . "$OUT/errors.txt")"; say "GrowLog-related error lines: $(grep -ciE 'growlog|flutter' "$OUT/errors.txt")"
say "SUMMARY pass=$PASSES fail=$FAILS notfound=$NOTFOUND"
