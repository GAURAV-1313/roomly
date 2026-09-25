#!/usr/bin/env bash
# Why: rules that are only written down drift. This script is the gate behind docs/ENGINEERING.md —
# every rule it can check mechanically, it checks. Run it before calling any change done.
#   scripts/check.sh          architecture + lint + build + tests
#   scripts/check.sh --fast   architecture + lint only
set -uo pipefail
cd "$(dirname "$0")/.."

FAILED=0
fail() { printf '  ✗ %b\n' "$1"; FAILED=1; }
pass() { echo "  ✓ $1"; }

# grep that ignores comment lines, returns matching "file:line: text"
code_grep() { grep -rnE "$1" "${@:2}" --include='*.swift' 2>/dev/null | grep -vE '^[^:]+:[0-9]+:\s*//' || true; }

echo "Architecture"
hits=$(code_grep '^import (Photos|PhotosUI|Contacts|AVFoundation)$' Roomy/App Roomy/Features Roomy/Design Roomy/Stores Roomy/Core)
[ -z "$hits" ] && pass "Photos/Contacts/AVFoundation imported only in Services/" || fail "framework import outside Services/:\n$hits"

hits=$(code_grep '\b(PHAsset|PHImageManager|PHPhotoLibrary|PHAssetResource|PHFetch|CNContact)[A-Za-z]*\b' Roomy/App Roomy/Features Roomy/Design Roomy/Stores Roomy/Core)
[ -z "$hits" ] && pass "PhotoKit/Contacts types used only in Services/" || fail "PhotoKit/Contacts outside Services/:\n$hits"

hits=$(code_grep '^import ' Roomy/Core | grep -vE 'import (Foundation|CoreGraphics|os)$')
[ -z "$hits" ] && pass "Core/ imports only Foundation, CoreGraphics, os" || fail "Core/ imports:\n$hits"

hits=$(code_grep '^import SwiftUI$' Roomy/Stores Roomy/Services)
[ -z "$hits" ] && pass "Stores/ and Services/ do not import SwiftUI" || fail "UI framework in Stores/ or Services/:\n$hits"
hits=$(code_grep '^import UIKit$' Roomy/Stores)
[ -z "$hits" ] || fail "UIKit in Stores/:\n$hits"

hits=$(code_grep '\b(AppState|ScanStore|Basket|PhotoLibrary|PhotoAccess|ContactAccess)\b' Roomy/Design)
[ -z "$hits" ] && pass "Design/ knows nothing about stores or services" || fail "Design/ depends on app state:\n$hits"

hits=$(code_grep '(deleteAssets|CNSaveRequest)' Roomy | grep -v '^Roomy/Services/Deletion/')
[ -z "$hits" ] && pass "deletion APIs only in Services/Deletion/" || fail "deletion API outside Services/Deletion/:\n$hits"

echo "Hygiene"
long=$(find Roomy RoomyTests -name '*.swift' -exec awk 'END { if (NR > 200) print FILENAME " (" NR " lines)" }' {} \;)
[ -z "$long" ] && pass "every file ≤ 200 lines" || fail "files over 200 lines:\n$long"

hits=$(code_grep '\bprint\(' Roomy)
[ -z "$hits" ] && pass "no print()" || fail "print() in app code:\n$hits"

hits=$(code_grep '"[^"]*(Day [0-9]|TODO|FIXME|lorem)[^"]*"' Roomy)
[ -z "$hits" ] && pass "no developer copy in user-facing strings" || fail "developer copy in strings:\n$hits"

hits=$(grep -rnE '(Day [0-9]|for now)' Roomy RoomyTests --include='*.swift' || true)
[ -z "$hits" ] && pass "no time-bound comments" || fail "time-bound comments:\n$hits"

# The app, its mascot and its identifiers are all called Roomy; the old working name must not come back.
hits=$(grep -rniI "phodex" Roomy RoomyTests docs design/README.md README.md project.yml 2>/dev/null || true)
[ -z "$hits" ] && pass "one name everywhere: Roomy" || fail "old name found:\n$hits"

missing=$(for f in $(find Roomy RoomyTests -name '*.swift'); do head -1 "$f" | grep -q '^// Why:' || echo "$f"; done)
[ -z "$missing" ] && pass "every file starts with a // Why: comment" || fail "missing // Why: header:\n$missing"

echo "Format"
lint=$(xcrun swift-format lint -r Roomy RoomyTests 2>&1)
[ -z "$lint" ] && pass "swift-format lint clean" || fail "swift-format:\n$(echo "$lint" | head -40)"

# Several copies of the project can be checked at once (parallel agents). There is one simulator and limited
# memory, so builds take turns: a lock directory, taken over if a crashed run left it behind for 30 minutes.
BUILD_LOCK=/tmp/roomy-build.lock
take_build_lock() {
    while ! mkdir "$BUILD_LOCK" 2>/dev/null; do
        if [ -n "$(find "$BUILD_LOCK" -maxdepth 0 -mmin +30 2>/dev/null)" ]; then
            rmdir "$BUILD_LOCK" 2>/dev/null
            continue
        fi
        sleep 5
    done
    trap 'rmdir "$BUILD_LOCK" 2>/dev/null' EXIT
}

if [ "${1:-}" != "--fast" ]; then
    echo "Build and test"
    take_build_lock
    # New files join the project only through XcodeGen; regenerating first means none is silently skipped.
    xcodegen generate --quiet >/dev/null 2>&1 && pass "Xcode project regenerated" || fail "xcodegen generate failed"
    SIM=$(xcrun simctl list devices available | grep -m1 -oE 'iPhone 1[5-9][^(]*\(([0-9A-F-]{36})\)' | grep -oE '[0-9A-F-]{36}')
    log=$(mktemp)
    xcodebuild -project Roomy.xcodeproj -scheme Roomy -destination "platform=iOS Simulator,id=$SIM" \
        -skipMacroValidation test >"$log" 2>&1
    status=$?
    warnings=$(grep -E '^/.*: warning:' "$log" | grep -v 'Metadata extraction skipped' | sort -u)
    [ $status -eq 0 ] && pass "build and tests pass ($(grep -oE 'Executed [0-9]+ tests' "$log" | tail -1))" \
        || fail "build or tests failed:\n$(grep -E '(: error:|error: |Test Case .* failed|\*\* .* FAILED \*\*|crashed)' "$log" | head -20)"
    [ -z "$warnings" ] && pass "zero compiler warnings" || fail "warnings:\n$warnings"
    rm -f "$log"
fi

echo
[ $FAILED -eq 0 ] && echo "All checks passed." || { echo "Checks failed."; exit 1; }
