#!/bin/zsh
# Prepares two simulators for a HatchPlan Pro demo or screen recording.
#
#   ./DemoAssets/prepare_demo.sh           build, install, import demo media
#   ./DemoAssets/prepare_demo.sh --fresh   also delete the app first, so the
#                                          recording starts from onboarding
#   ./DemoAssets/prepare_demo.sh --clean   erase both simulators completely
#                                          (Photos, Face ID, sign-ins) first
#
# Supervisor runs on iPhone 17, manager on iPhone 17 Pro (iOS 26.2).

set -e
cd "$(dirname "$0")/.."

SUPERVISOR_SIM="iPhone 17"
MANAGER_SIM="iPhone 17 Pro"
BUNDLE_ID="com.nadunika.HatchPlanPro"
BUILD_DIR="build"
APP="$BUILD_DIR/Build/Products/Debug-iphonesimulator/HatchPlanPro.app"

udid_for() {
  xcrun simctl list devices available | grep -E "^ +$1 \(" | grep -m1 -oE '[0-9A-F-]{36}'
}

SUP=$(udid_for "$SUPERVISOR_SIM")
MGR=$(udid_for "$MANAGER_SIM")
[[ -z "$SUP" || -z "$MGR" ]] && { echo "Could not find '$SUPERVISOR_SIM' and '$MANAGER_SIM' simulators."; exit 1; }

echo "▶ Building HatchPlan Pro…"
xcodebuild -project HatchPlanPro.xcodeproj -scheme HatchPlanPro \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath "$BUILD_DIR" build -quiet

for SIM in "$SUP" "$MGR"; do
  NAME=$([[ "$SIM" == "$SUP" ]] && echo "$SUPERVISOR_SIM (Supervisor)" || echo "$MANAGER_SIM (Manager)")
  echo "▶ Preparing $NAME"
  if [[ "$1" == "--clean" ]]; then
    xcrun simctl shutdown "$SIM" 2>/dev/null || true
    xcrun simctl erase "$SIM"
  fi
  xcrun simctl boot "$SIM" 2>/dev/null || true
  xcrun simctl bootstatus "$SIM" -b >/dev/null

  if [[ "$1" == "--fresh" ]]; then
    xcrun simctl uninstall "$SIM" "$BUNDLE_ID" 2>/dev/null || true
  fi
  xcrun simctl install "$SIM" "$APP"

  # Clean status bar for recordings: 9:41, full battery and signal.
  xcrun simctl status_bar "$SIM" override --time "9:41" --batteryState charged --batteryLevel 100 \
    --cellularBars 4 --wifiBars 3 2>/dev/null || true

  # Demo media: certificates for New Plan, egg photos for observations.
  for f in DemoAssets/demo_flock_certificate.png DemoAssets/Certificates/*.png DemoAssets/*.jp*g(N) DemoAssets/*.png(N); do
    [[ -f "$f" ]] && xcrun simctl addmedia "$SIM" "$f" 2>/dev/null || true
  done
done

open -a Simulator
echo ""
echo "✅ Ready. Supervisor: $SUPERVISOR_SIM   Manager: $MANAGER_SIM"
echo "   In the $MANAGER_SIM window choose Features › Face ID › Enrolled before approving."
