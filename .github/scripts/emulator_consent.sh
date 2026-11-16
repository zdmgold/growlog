#!/usr/bin/env bash
# Exercises the consent step on the emulator, pretending to be in the EEA (build flag CONSENT_DEBUG=eea).
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
flog(){ adb logcat -d -s flutter | grep -i "consent\|canRequestAds\|privacyOptions"; }

adb shell am start -W -n "$PKG/.MainActivity" >/dev/null 2>&1; sleep 25
adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null 2>&1; sleep 2
shot 00_consent_form
# Google's form is a web view that the screen dump cannot read, so it is answered by position.
adb shell input tap 540 1819; say "tapped Do not consent"; sleep 10
adb shell am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS >/dev/null 2>&1
shot 01_after_launch; dump home
say "== consent log after launch =="; flog | cut -c1-230 | tee -a "$LOG"
grep -q "Consent outcome" <(flog) && say "PASS: the consent step ran and reported an outcome" || say "FAIL: no consent outcome logged"
grep -q "requestAds=true" <(flog) && say "PASS: ads are allowed to be requested" || say "NOTE: ads not allowed by the outcome"
grep -qi "Test Ad" "$OUT/home.xml" && say "PASS: a banner ad is showing" || say "NOTE: no banner ad in the screen dump yet"

# Background and return: a failed first step must be retried exactly once
adb shell input keyevent KEYCODE_HOME; sleep 4
adb shell am start -n "$PKG/.MainActivity" >/dev/null 2>&1; sleep 15
say "== consent log after returning =="; flog | cut -c1-230 | tee -a "$LOG"
N=$(flog | grep -c "Consent retry on return to foreground"); say "retry lines: $N"
adb shell input keyevent KEYCODE_HOME; sleep 3; adb shell am start -n "$PKG/.MainActivity" >/dev/null 2>&1; sleep 10
N2=$(flog | grep -c "Consent retry on return to foreground")
[ "$N2" -le 1 ] && say "PASS: retried at most once (count $N2)" || say "FAIL: retried more than once ($N2)"

# Settings: the Privacy choices row appears only when Google says it is required
dump cur; XY=$(python3 .github/scripts/ui_tap.py "$OUT/cur.xml" "Settings" "settings") && { set -- $XY; adb shell input tap "$1" "$2"; sleep 3; }
for i in 1 2 3 4; do adb shell input swipe 540 1700 540 700 300; sleep 1; done
shot 02_settings_about; dump st
grep -qi "Privacy choices" "$OUT/st.xml" && say "PASS: Privacy choices row is shown" || say "FAIL: Privacy choices row is not shown"
tap "Privacy choices" && sleep 8 && shot 03_options_form && say "opened Privacy choices (see 03_options_form.png)"
adb logcat -d -s AndroidRuntime:E flutter:E > "$OUT/errors.txt" 2>&1; say "error lines: $(grep -c . "$OUT/errors.txt")"
