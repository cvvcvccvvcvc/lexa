#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIGURATION="${CONFIGURATION:-debug}"
APP_NAME="Lexa"
BINARY_NAME="VocabularyApp"
APP_DIR="$ROOT_DIR/Build/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SCRIPT_HOME="$ROOT_DIR/.build/script-home"
CLANG_CACHE="$ROOT_DIR/.build/clang-module-cache"
SWIFTPM_CACHE="$ROOT_DIR/.build/swiftpm-module-cache"

cd "$ROOT_DIR"

mkdir -p "$SCRIPT_HOME" "$CLANG_CACHE" "$SWIFTPM_CACHE"
export HOME="$SCRIPT_HOME"
export CLANG_MODULE_CACHE_PATH="$CLANG_CACHE"
export SWIFTPM_MODULECACHE_OVERRIDE="$SWIFTPM_CACHE"

swift build --disable-sandbox --configuration "$CONFIGURATION" --product "$BINARY_NAME"
BUILD_DIR="$(swift build --disable-sandbox --configuration "$CONFIGURATION" --show-bin-path)"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$BUILD_DIR/$BINARY_NAME" "$MACOS_DIR/$BINARY_NAME"

if [[ -f "$ROOT_DIR/Resources/AppIcon.icns" ]]; then
    cp "$ROOT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$BINARY_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>local.lexa.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

echo "$APP_DIR"
