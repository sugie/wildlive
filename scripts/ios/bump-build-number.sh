#!/usr/bin/env bash
# Set the iOS build number to the current UTC time (YYMMDDHHmm).
#
# Run before archiving for TestFlight or the App Store. App Store Connect
# refuses an upload whose build number has been used before, and a date is
# monotonic without asking anyone what the last one was.
#
# Rewrites CURRENT_PROJECT_VERSION in Config/Shared.xcconfig. Commit the
# result: the repository should record which build number was shipped.

set -euo pipefail

xcconfig="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/apps/ios/WildLive/Config/Shared.xcconfig"

[ -f "$xcconfig" ] || { echo "not found: $xcconfig" >&2; exit 1; }

previous="$(sed -n 's/^CURRENT_PROJECT_VERSION = //p' "$xcconfig")"
build="$(date -u +%y%m%d%H%M)"

if [ "$build" = "$previous" ]; then
    echo "build number is already $build (same minute); nothing to do"
    exit 0
fi

# A later archive must never carry a lower number than an earlier one.
if [ -n "$previous" ] && [ "$previous" -gt "$build" ] 2>/dev/null; then
    echo "refusing to go backwards: $previous -> $build" >&2
    echo "the clock or the committed value is wrong; fix before archiving" >&2
    exit 1
fi

sed -i '' "s/^CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = ${build}/" "$xcconfig"
echo "build number ${previous:-none} -> ${build}"
