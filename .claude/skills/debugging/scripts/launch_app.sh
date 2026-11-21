#!/bin/bash
# Launches an app of the example project on a simulator with `fvm flutter run`
# in the background, writes its output to a log file, and waits until the app
# is ready or the launch fails.
#
# Usage: launch_app.sh <device-udid> <target-dart-file> <log-file>
#   <target-dart-file> is relative to the example directory,
#   e.g. lib/repro/issue_655.dart or lib/tutorial/scrollable_sheet.dart.
#
# Any `flutter run` that is already running for the same device is stopped
# first, because two apps cannot run on one simulator at the same time.
set -u

if [ $# -ne 3 ]; then
  echo "Usage: $0 <device-udid> <target-dart-file> <log-file>" >&2
  exit 2
fi
udid=$1
target=$2
log=$3

example_dir="$(git rev-parse --show-toplevel)/example"
if [ ! -f "$example_dir/$target" ]; then
  echo "Target not found: $example_dir/$target" >&2
  exit 2
fi

if pkill -f "flutter_tools.snapshot run -d $udid"; then
  sleep 1
fi

cd "$example_dir" || exit 1
nohup fvm flutter run -d "$udid" -t "$target" > "$log" 2>&1 &
pid=$!

# Wait for the "ready" banner, a build error, or the process exiting.
while true; do
  if grep -q "Flutter run key commands" "$log"; then
    echo "Ready. Log: $log"
    grep -E "EXCEPTION CAUGHT|Failed assertion" "$log" | head -5
    exit 0
  fi
  if ! kill -0 "$pid" 2>/dev/null; then
    echo "flutter run exited before the app was ready. Last lines of $log:" >&2
    tail -20 "$log" >&2
    exit 1
  fi
  sleep 2
done
