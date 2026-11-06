#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Break Reminder - DMG Build & Packaging Script
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

APP_NAME="BreakReminder"
SCHEME="BreakReminder"
CONFIGURATION="Release"
VERSION="1.0.0"
DIST_DIR="${PROJECT_ROOT}/dist"
BUILD_DIR="${PROJECT_ROOT}/.build/DerivedData"
STAGING_DIR="${PROJECT_ROOT}/.build/dmg_staging"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"

echo "========================================================================"
echo "Building ${APP_NAME} (${VERSION}) - Configuration: ${CONFIGURATION}"
echo "========================================================================"

# 1. Clean previous staging & dist
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"
mkdir -p "${DIST_DIR}"

# 2. Build Release configuration
echo "[1/6] Compiling ${APP_NAME} in ${CONFIGURATION} mode..."
xcodebuild -project "${PROJECT_ROOT}/BreakReminder.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${BUILD_DIR}" \
    -destination 'platform=macOS' \
    build

BUILT_APP="${BUILD_DIR}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
if [ ! -d "${BUILT_APP}" ]; then
    echo "Error: Built application not found at ${BUILT_APP}"
    exit 1
fi

# 3. Copy to staging directory
echo "[2/6] Staging application bundle..."
cp -R "${BUILT_APP}" "${STAGING_DIR}/${APP_NAME}.app"

# 4. Optional Developer ID signing
if [ -n "${DEVELOPER_ID_APPLICATION:-}" ]; then
    echo "[3/6] Signing with Developer ID Application: ${DEVELOPER_ID_APPLICATION}..."
    codesign --force --deep --timestamp \
        --options runtime \
        --entitlements "${PROJECT_ROOT}/BreakReminder/Resources/BreakReminder.entitlements" \
        --sign "${DEVELOPER_ID_APPLICATION}" \
        "${STAGING_DIR}/${APP_NAME}.app"
    codesign --verify --deep --strict "${STAGING_DIR}/${APP_NAME}.app"
    echo "Signed successfully with Developer ID."
else
    echo "[3/6] No DEVELOPER_ID_APPLICATION specified; performing local ad-hoc signature..."
    codesign --force --deep --sign - "${STAGING_DIR}/${APP_NAME}.app"
fi

# 5. Create Applications symlink
echo "[4/6] Creating /Applications symlink in DMG..."
ln -s /Applications "${STAGING_DIR}/Applications"

# 6. Generate compressed DMG
echo "[5/6] Generating compressed DMG image..."
rm -f "${DMG_PATH}"
hdiutil create \
    -volname "${APP_NAME}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

# 7. Optional DMG signing and Notarization
if [ -n "${DEVELOPER_ID_APPLICATION:-}" ]; then
    echo "[6/6] Signing DMG disk image..."
    codesign --sign "${DEVELOPER_ID_APPLICATION}" "${DMG_PATH}"
    
    if [ "${NOTARIZE:-false}" = "true" ]; then
        if [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_PASSWORD:-}" ] && [ -n "${TEAM_ID:-}" ]; then
            echo "Submitting DMG for Apple Notarization..."
            xcrun notarytool submit "${DMG_PATH}" \
                --apple-id "${APPLE_ID}" \
                --password "${APPLE_PASSWORD}" \
                --team-id "${TEAM_ID}" \
                --wait
            
            echo "Stapling notarization ticket to DMG..."
            xcrun stapler staple "${DMG_PATH}"
            echo "Notarization and stapling complete!"
        else
            echo "Warning: NOTARIZE=true was requested, but APPLE_ID, APPLE_PASSWORD, or TEAM_ID is unset."
            echo "Skipping notarization step."
        fi
    else
        echo "Skipping notarization (NOTARIZE!=true)."
    fi
else
    echo "[6/6] Ad-hoc signed DMG created (unsigned/locally signed)."
    echo "Note: When distributing outside the Mac App Store without Developer ID notarization,"
    echo "users will need to Right Click -> Open or run 'xattr -cr /Applications/${APP_NAME}.app'."
fi

# Clean up staging
rm -rf "${STAGING_DIR}"

echo "========================================================================"
echo "Successfully generated DMG:"
echo "${DMG_PATH}"
echo "Size: $(du -sh "${DMG_PATH}" | awk '{print $1}')"
echo "========================================================================"
