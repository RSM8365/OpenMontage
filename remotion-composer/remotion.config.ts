import { Config } from "@remotion/cli/config";

// Cloud sessions route outbound HTTPS through a proxy that Remotion's Chromium
// bypasses by default. .claude/hooks/session-start.sh sets this variable to
// scripts/cloud/chromium-via-proxy.sh there. Unset locally, so nothing changes.
const browserExecutable = process.env.OPENMONTAGE_BROWSER_EXECUTABLE;
if (browserExecutable) {
  Config.setBrowserExecutable(browserExecutable);
}
