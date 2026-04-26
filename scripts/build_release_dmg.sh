#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

ARTIFACTS_DIR="$ROOT_DIR/BuildArtifacts"
DERIVED_DATA_DIR="$ARTIFACTS_DIR/Build"
RELEASE_DIR="$DERIVED_DATA_DIR/Build/Products/Release"
APP_NAME="TimeTrack"
APP_DIR="$ARTIFACTS_DIR/Packaging/${APP_NAME}.app"
DMG_ROOT_DIR="$ARTIFACTS_DIR/DMGRoot"
DMG_PATH="$ARTIFACTS_DIR/${APP_NAME}.dmg"
ASSET_CATALOG_DIR="$ROOT_DIR/WorkTimeTracker/Resources/Assets.xcassets"
mkdir -p "$ARTIFACTS_DIR"
ICON_BUILD_DIR="$(mktemp -d "$ARTIFACTS_DIR/app-icon.XXXXXX")"
ICON_INFO_PLIST="$ICON_BUILD_DIR/IconInfo.plist"

rm -rf "$APP_DIR" "$DMG_ROOT_DIR" "$DMG_PATH"

xcodebuild \
  -scheme WorkTimeTracker \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  build

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$RELEASE_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp -R "$RELEASE_DIR/WorkTimeTracker_WorkTimeTracker.bundle" "$APP_DIR/Contents/Resources/"
cp -R "$RELEASE_DIR/PackageFrameworks" "$APP_DIR/Contents/Frameworks"

mkdir -p "$ICON_BUILD_DIR/out"
xcrun actool "$ASSET_CATALOG_DIR" \
  --compile "$ICON_BUILD_DIR/out" \
  --platform macosx \
  --target-device mac \
  --minimum-deployment-target 14.0 \
  --app-icon AppIcon \
  --output-partial-info-plist "$ICON_INFO_PLIST" \
  --compress-pngs \
  --errors \
  --warnings \
  --notices \
  --output-format human-readable-text

cp "$ICON_BUILD_DIR/out/Assets.car" "$APP_DIR/Contents/Resources/Assets.car"
cp "$ICON_BUILD_DIR/out/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"

cat > "$APP_DIR/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconName</key>
    <string>AppIcon</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIconFiles</key>
    <array>
        <string>AppIcon</string>
    </array>
    <key>CFBundleIdentifier</key>
    <string>worktimetracker.${APP_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

printf 'APPL????' > "$APP_DIR/Contents/PkgInfo"

codesign --force --deep --sign - "$APP_DIR"

mkdir -p "$DMG_ROOT_DIR"
cp -R "$APP_DIR" "$DMG_ROOT_DIR/"
ln -sfn /Applications "$DMG_ROOT_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_ROOT_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$ICON_BUILD_DIR"

echo "APP: $APP_DIR"
echo "DMG: $DMG_PATH"
