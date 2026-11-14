#!/bin/zsh
# Builds Sadhana.app and Sadhana.dmg into ./build
set -e
cd "$(dirname "$0")"
B=build
APP=$B/Sadhana.app
rm -rf $B && mkdir -p $APP/Contents/{MacOS,Resources}

swiftc -O -parse-as-library -target arm64-apple-macos14.0 Sources/*.swift -o $B/Sadhana-arm64
swiftc -O -parse-as-library -target x86_64-apple-macos14.0 Sources/*.swift -o $B/Sadhana-x86_64
lipo -create $B/Sadhana-arm64 $B/Sadhana-x86_64 -output $APP/Contents/MacOS/Sadhana

cp -R Resources/voice Resources/sounds Resources/CREDITS.txt $APP/Contents/Resources/

# icon
swiftc scripts/Icon.swift -o $B/icongen && $B/icongen $B/icon.png
mkdir -p $B/AppIcon.iconset
for s in 16 32 128 256 512; do
  sips -z $s $s $B/icon.png --out $B/AppIcon.iconset/icon_${s}x${s}.png >/dev/null
  sips -z $((s*2)) $((s*2)) $B/icon.png --out $B/AppIcon.iconset/icon_${s}x${s}@2x.png >/dev/null
done
iconutil -c icns $B/AppIcon.iconset -o $APP/Contents/Resources/AppIcon.icns

cat > $APP/Contents/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Sadhana</string>
  <key>CFBundleDisplayName</key><string>Sadhana</string>
  <key>CFBundleIdentifier</key><string>com.tanmay.sadhana</string>
  <key>CFBundleExecutable</key><string>Sadhana</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.healthcare-fitness</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
EOF

codesign --force --deep -s - $APP

# dmg
mkdir -p $B/dmg && cp -R $APP $B/dmg/ && ln -s /Applications $B/dmg/Applications
hdiutil create -volname Sadhana -srcfolder $B/dmg -ov -format UDZO $B/Sadhana.dmg >/dev/null
rm -rf $B/dmg $B/Sadhana-arm64 $B/Sadhana-x86_64 $B/icongen $B/AppIcon.iconset
echo "Built $B/Sadhana.dmg"
