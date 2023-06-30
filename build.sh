#!/usr/bin/env bash
## 
##  build.sh
##  PristineTouch
##  Original author: github.com/gltchitm
##  Recreated by Turann_ on 30.06.2023.
##

appname="PristineTouch"
execname="pristinetouch"
identifier="xyz.turannul.PristineTouch"
version="1.0"
###################################################
buildpath="build/PristineTouch.app/Contents/MacOS"
plistpath="build/PristineTouch.app/Contents/"

rm -rf build/
mkdir -p $buildpath

cat << EOF > $plistpath/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$appname</string>
    <key>CFBundleDisplayName</key>
    <string>$appname</string>
    <key>CFBundleExecutable</key>
    <string>$execname</string>
    <key>CFBundleIdentifier</key>
    <string>$identifier</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>$version</string>
    <key>CFBundleShortVersionString</key>
    <string>$version</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>MacOSX</string>
    </array>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

clang -framework Cocoa -o $buildpath/$execname src/main.m src/AppDelegate.m && echo -e " Build successful: $version" || echo -e "Build failed!"
