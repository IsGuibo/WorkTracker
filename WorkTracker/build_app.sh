#!/bin/bash
# 构建 工作追踪.app
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
DISPLAY="工作追踪"
BUNDLE_ID="com.worktracker.local"
VERSION="1.0.1"
APP="$DIR/$DISPLAY.app"

echo "▶ 编译 release 版本…"
swift build -c release --package-path "$DIR"

echo "▶ 组装 $DISPLAY.app…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$DIR/.build/release/WorkTracker" "$APP/Contents/MacOS/WorkTracker"

echo "▶ 生成图标…"
swift "$DIR/generate_icon.swift" "$APP/Contents/Resources"

cat > "$APP/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>             <string>$DISPLAY</string>
    <key>CFBundleDisplayName</key>      <string>$DISPLAY</string>
    <key>CFBundleIdentifier</key>       <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>          <string>$VERSION</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleExecutable</key>       <string>WorkTracker</string>
    <key>CFBundlePackageType</key>      <string>APPL</string>
    <key>CFBundleIconFile</key>         <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>   <string>14.0</string>
    <key>NSHighResolutionCapable</key>  <true/>
    <key>NSPrincipalClass</key>         <string>NSApplication</string>
    <key>NSHumanReadableCopyright</key> <string>© 2026</string>
</dict>
</plist>
PLIST

echo ""
echo "✓ $APP"
