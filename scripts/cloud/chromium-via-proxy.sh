#!/bin/bash
# Chromium launcher for Remotion renders inside Claude Code cloud sessions.
#
# Cloud sessions reach the internet only through an HTTPS proxy ($HTTPS_PROXY).
# Remotion starts Chromium with --no-proxy-server, --proxy-server='direct://'
# and --proxy-bypass-list=*, so every remote asset (Google Fonts, remote images)
# fails with net::ERR_CERT_AUTHORITY_INVALID and the render aborts.
#
# This wrapper drops those three flags and points Chromium at the proxy again.
# remotion-composer/remotion.config.ts uses it only when
# OPENMONTAGE_BROWSER_EXECUTABLE is set, which .claude/hooks/session-start.sh
# does in cloud sessions. Local renders are unaffected.
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"

# Prefer the headless shell Remotion downloaded itself (version-matched),
# fall back to the Playwright build preinstalled in cloud images.
browser=""
for candidate in \
  "$repo_root/remotion-composer/node_modules/.remotion/chrome-headless-shell/linux64/chrome-headless-shell-linux64/chrome-headless-shell" \
  /opt/pw-browsers/chromium_headless_shell-*/chrome-linux/headless_shell; do
  if [ -x "$candidate" ]; then
    browser="$candidate"
    break
  fi
done
if [ -z "$browser" ]; then
  echo "chromium-via-proxy: no headless Chromium found. Run: cd remotion-composer && npx remotion browser ensure" >&2
  exit 1
fi

args=()
for arg in "$@"; do
  case "$arg" in
    --no-proxy-server | --proxy-server=* | --proxy-bypass-list=*) ;;
    *) args+=("$arg") ;;
  esac
done

if [ -n "${HTTPS_PROXY:-}" ]; then
  args+=("--proxy-server=$HTTPS_PROXY" "--proxy-bypass-list=localhost;127.0.0.1")
fi

exec "$browser" "${args[@]}"
