#!/bin/bash
# SessionStart hook.
#
# Every session (local and cloud): put .venv/bin on PATH so tools that probe
# for CLI binaries (piper, etc.) find them, even when the venv is not
# activated, e.g. in the desktop app's Code tab.
#
# Cloud sessions only (CLAUDE_CODE_REMOTE=true): run `make setup`, install the
# dev requirements, download the headless browsers for Remotion and HyperFrames,
# and route Remotion's Chromium through the session proxy. Idempotent, so a
# resumed session only re-checks what is already installed.
set -euo pipefail

project_dir="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$project_dir"

persist() {
  if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
    echo "$1" >> "$CLAUDE_ENV_FILE"
  fi
}

if [ "${CLAUDE_CODE_REMOTE:-}" = "true" ]; then
  log="${TMPDIR:-/tmp}/openmontage-session-start.log"
  : > "$log"
  started=$(date +%s)

  if ! command -v ffmpeg >/dev/null 2>&1; then
    { apt-get update && apt-get install -y ffmpeg; } >> "$log" 2>&1
  fi

  if ! make setup >> "$log" 2>&1; then
    echo "OpenMontage setup failed, see $log"
    tail -n 20 "$log"
    exit 1
  fi
  .venv/bin/python -m pip install -q -r requirements-dev.txt >> "$log" 2>&1
  (cd remotion-composer && npx remotion browser ensure) >> "$log" 2>&1
  npx --yes hyperframes browser ensure >> "$log" 2>&1

  persist "export OPENMONTAGE_BROWSER_EXECUTABLE=\"$project_dir/scripts/cloud/chromium-via-proxy.sh\""
  echo "OpenMontage cloud setup done in $(( $(date +%s) - started ))s (log: $log)"
fi

if [ -x "$project_dir/.venv/bin/python" ]; then
  persist "export VIRTUAL_ENV=\"$project_dir/.venv\""
  persist "export PATH=\"$project_dir/.venv/bin:\$PATH\""
fi
