#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC_PATH="$APP_ROOT/pubspec.yaml"
VERSION_FROM_PUBSPEC="$(sed -nE 's/^version:[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)[[:space:]]*$/\1/p' "$PUBSPEC_PATH" | head -n 1)"
BUILD_NUMBER_FROM_PUBSPEC="$(sed -nE 's/^version:[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)[[:space:]]*$/\2/p' "$PUBSPEC_PATH" | head -n 1)"

VERSION="${1:-$VERSION_FROM_PUBSPEC}"
BUILD_NUMBER="${2:-$BUILD_NUMBER_FROM_PUBSPEC}"
OUTPUT_DIRECTORY="${3:-$APP_ROOT/dist/macos}"

if [[ -z "$VERSION" || -z "$BUILD_NUMBER" ]]; then
  echo "Could not read the version from $PUBSPEC_PATH." >&2
  exit 1
fi
if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter was not found on PATH. Install Flutter and enable macOS desktop support first.' >&2
  exit 1
fi

if [[ "$OUTPUT_DIRECTORY" != /* ]]; then
  OUTPUT_DIRECTORY="$PWD/$OUTPUT_DIRECTORY"
fi
mkdir -p "$OUTPUT_DIRECTORY"
OUTPUT_DIRECTORY="$(cd "$OUTPUT_DIRECTORY" && pwd)"

cd "$APP_ROOT"
flutter build macos --release --build-name="$VERSION" --build-number="$BUILD_NUMBER"

APP_PATH="$APP_ROOT/build/macos/Build/Products/Release/CerebroSync.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "The release bundle is missing $APP_PATH." >&2
  exit 1
fi

ARCHIVE_NAME="CerebroSync-macos-v${VERSION}.zip"
ARCHIVE_PATH="$OUTPUT_DIRECTORY/$ARCHIVE_NAME"
CHECKSUM_PATH="$ARCHIVE_PATH.sha256"
STAGING_PATH="$OUTPUT_DIRECTORY/CerebroSync-macos-v${VERSION}"
NOTARY_ZIP="$OUTPUT_DIRECTORY/.CerebroSync-notary-v${VERSION}.zip"

rm -rf "$STAGING_PATH" "$ARCHIVE_PATH" "$CHECKSUM_PATH" "$NOTARY_ZIP"
mkdir -p "$STAGING_PATH"
ditto "$APP_PATH" "$STAGING_PATH/CerebroSync.app"

# Set MACOS_SIGNING_IDENTITY to a Developer ID Application identity for a
# website release. An unsigned app will trigger a Gatekeeper warning.
if [[ -n "${MACOS_SIGNING_IDENTITY:-}" ]]; then
  codesign --deep --force --options runtime --timestamp \
    --sign "$MACOS_SIGNING_IDENTITY" "$STAGING_PATH/CerebroSync.app"
fi

# Set NOTARIZE=1 together with APPLE_ID, APPLE_TEAM_ID, and
# APPLE_APP_PASSWORD after signing. The password should be an app-specific
# password, not the Apple ID password.
if [[ "${NOTARIZE:-0}" == '1' ]]; then
  : "${APPLE_ID:?Set APPLE_ID when NOTARIZE=1}"
  : "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID when NOTARIZE=1}"
  : "${APPLE_APP_PASSWORD:?Set APPLE_APP_PASSWORD when NOTARIZE=1}"
  ditto -c -k --sequesterRsrc --keepParent \
    "$STAGING_PATH/CerebroSync.app" "$NOTARY_ZIP"
  xcrun notarytool submit "$NOTARY_ZIP" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --wait
  xcrun stapler staple "$STAGING_PATH/CerebroSync.app"
  rm -f "$NOTARY_ZIP"
fi

ditto -c -k --sequesterRsrc --keepParent \
  "$STAGING_PATH/CerebroSync.app" "$ARCHIVE_PATH"
if command -v hdiutil >/dev/null 2>&1; then
  hdiutil create -volname CerebroSync -srcfolder "$STAGING_PATH" \
    -ov -format UDZO "$OUTPUT_DIRECTORY/CerebroSync-macos-v${VERSION}.dmg" >/dev/null
fi

shasum -a 256 "$ARCHIVE_PATH" > "$CHECKSUM_PATH"
rm -rf "$STAGING_PATH"

echo "macOS release: $ARCHIVE_PATH"
echo "SHA-256: $CHECKSUM_PATH"
