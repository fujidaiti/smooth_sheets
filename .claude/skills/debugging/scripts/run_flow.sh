#!/bin/bash
# Runs Maestro flow files with the Maestro CLI and prints one line per step
# with the elapsed seconds. On failure, saves a small screenshot of the
# simulator next to the app log and prints the app exceptions that were logged
# while the flow ran.
#
# Usage: run_flow.sh <device-udid> <app-log-file> <flow.yaml>...
set -u

if [ $# -lt 3 ]; then
  echo "Usage: $0 <device-udid> <app-log-file> <flow.yaml>..." >&2
  exit 2
fi
udid=$1
log=$2
shift 2

start_line=$(($(wc -l < "$log") + 1))

output=$(maestro --device "$udid" test "$@" 2>&1 |
  perl -MTime::HiRes=time -ne 'BEGIN { $| = 1; $t = time }
    printf "%5.1fs %s", time - $t, $_
      if /COMPLETED|FAILED|WARNED|SKIPPED|rror|Assertion/')
echo "$output"

# Show only the exceptions logged during this run.
tail -n +"$start_line" "$log" |
  grep -E "EXCEPTION CAUGHT|Failed assertion|Another exception|Null check" |
  head -5

if echo "$output" | grep -q FAILED; then
  shot="$(dirname "$log")/fail.jpg"
  xcrun simctl io "$udid" screenshot --type=jpeg "$shot" > /dev/null 2>&1 &&
    sips -Z 600 "$shot" > /dev/null &&
    echo "Screenshot: $shot"
  exit 1
fi
