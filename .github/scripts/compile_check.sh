#!/usr/bin/env bash
# Compile check: analyze, tests, Dart compile, Android Kotlin/Java compile. Never builds an APK.
R=/tmp/report.txt
: > "$R"
FAIL=0

sec() { { echo ""; echo "##### $1"; } >> "$R"; }

run() {
  local name="$1"; shift
  sec "$name"
  "$@" > /tmp/step.log 2>&1
  local rc=$?
  tail -n 60 /tmp/step.log >> "$R"
  echo "exit=$rc" >> "$R"
  if [ $rc -ne 0 ]; then FAIL=1; fi
}

sec "environment"
{ echo "commit: $GITHUB_SHA"; flutter --version 2>&1 | head -4; } >> "$R"

run "pub get" flutter pub get

run "gen-l10n" flutter gen-l10n
{ echo "generated l10n files:"; find lib -name 'app_localizations*.dart' | sort | head -20; } >> "$R"

sec "analyze (errors only, then summary)"
flutter analyze --no-fatal-infos --no-fatal-warnings > /tmp/analyze.log 2>&1
RC=$?
grep -E "^\s*error •" /tmp/analyze.log | cut -c1-260 | head -150 >> "$R"
grep -E "^\s*warning •" /tmp/analyze.log | wc -l | sed 's/^/warnings: /' >> "$R"
grep -E "^\s*info •" /tmp/analyze.log | wc -l | sed 's/^/infos: /' >> "$R"
tail -n 3 /tmp/analyze.log >> "$R"
echo "exit=$RC" >> "$R"
if [ $RC -ne 0 ]; then FAIL=1; fi

sec "unit tests"
if [ -d test ]; then
  flutter test > /tmp/test.log 2>&1; RC=$?
  tail -n 40 /tmp/test.log >> "$R"; echo "exit=$RC" >> "$R"
  if [ $RC -ne 0 ]; then FAIL=1; fi
else
  echo "no test/ directory - skipped" >> "$R"
fi

run "dart compile (flutter build bundle)" flutter build bundle

sec "android scaffold"
flutter create --platforms=android . > /tmp/create.log 2>&1; echo "exit=$?" >> "$R"
{ ls android 2>/dev/null | head -20; ls android/app/src/main/kotlin 2>/dev/null | head; } >> "$R"

sec "android kotlin + java compile (no APK)"
( cd android && chmod +x gradlew && ./gradlew --no-daemon --console=plain :app:compileDebugKotlin :app:compileDebugJavaWithJavac > /tmp/gradle.log 2>&1 ); RC=$?
grep -E "^e: |error:|FAILED|What went wrong|BUILD (SUCCESSFUL|FAILED)|Could not|Unsupported|incompatible" /tmp/gradle.log | cut -c1-260 | head -60 >> "$R"
tail -n 15 /tmp/gradle.log | cut -c1-260 >> "$R"
echo "exit=$RC" >> "$R"
if [ $RC -ne 0 ]; then FAIL=1; fi

sec "result"
if [ $FAIL -eq 0 ]; then echo "ALL CHECKS PASSED" >> "$R"; else echo "CHECKS FAILED" >> "$R"; fi
echo $FAIL > /tmp/status
exit 0
