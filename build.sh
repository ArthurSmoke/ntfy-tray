#!/bin/bash

rm -rf NtfyTray.app
rm -f NtfyTray

mkdir -p NtfyTray.app/Contents/MacOS
mkdir -p NtfyTray.app/Contents/Resources

swiftc Sources/*.swift Sources/Views/*.swift \
  -o NtfyTray \
  -framework SwiftUI \
  -framework UserNotifications \
  -framework AppKit \
  -framework ServiceManagement

cp NtfyTray NtfyTray.app/Contents/MacOS/
cp Info.plist NtfyTray.app/Contents/
cp ntfy.icns NtfyTray.app/Contents/Resources/AppIcon.icns

chmod +x NtfyTray.app/Contents/MacOS/NtfyTray

codesign --force --deep --sign - NtfyTray.app

echo "构建完成: NtfyTray.app"
