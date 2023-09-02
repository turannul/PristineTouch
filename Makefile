appname := PristineTouch
execname := pristinetouch
identifier := xyz.turannul.PristineTouch
version := 1.1.2-1
execpath := build/PristineTouch.app/Contents/MacOS
plistpath := build/PristineTouch.app/Contents/

all: $(execpath)/$(execname)

$(execpath)/$(execname): src/main.m src/PristineTouch.m
	rm -rf build/
	mkdir -p $(execpath)
	@printf '<?xml version="1.0" encoding="UTF-8"?>\n' > $(plistpath)/Info.plist
	@printf '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n' >> $(plistpath)/Info.plist
	@printf '<plist version="1.0">\n' >> $(plistpath)/Info.plist
	@printf '<dict>\n' >> $(plistpath)/Info.plist
	@printf '    <key>CFBundleName</key>\n' >> $(plistpath)/Info.plist
	@printf '    <string>$(appname)</string>\n' >> $(plistpath)/Info.plist
	@printf '    <key>CFBundleDisplayName</key>\n' >> $(plistpath)/Info.plist
	@printf '    <string>$(appname)</string>\n' >> $(plistpath)/Info.plist
	@printf '    <key>CFBundleExecutable</key>\n' >> $(plistpath)/Info.plist
	@printf '    <string>$(execname)</string>\n' >> $(plistpath)/Info.plist
	@printf '    <key>CFBundleIdentifier</key>\n' >> $(plistpath)/Info.plist
	@printf '    <string>$(identifier)</string>\n' >> $(plistpath)/Info.plist
	@printf '    <key>CFBundlePackageType</key>\n' >> $(plistpath)/Info.plist
	@printf '    <string>APPL</string>\n' >> $(plistpath)/Info.plist
	@printf '    <key>CFBundleVersion</key>\n' >> $(plistpath)/Info.plist
	@printf '    <string>$(version)</string>\n' >> $(plistpath)/Info.plist
	@printf '    <key>CFBundleShortVersionString</key>\n' >> $(plistpath)/Info.plist
	@printf '    <string>$(version)</string>\n' >> $(plistpath)/Info.plist
	@printf '    <key>CFBundleSupportedPlatforms</key>\n' >> $(plistpath)/Info.plist
	@printf '    <array>\n' >> $(plistpath)/Info.plist
	@printf '        <string>MacOSX</string>\n' >> $(plistpath)/Info.plist
	@printf '    </array>\n' >> $(plistpath)/Info.plist
	@printf '    <key>LSMinimumSystemVersion</key>\n' >> $(plistpath)/Info.plist
	@printf '    <string>11.0</string>\n' >> $(plistpath)/Info.plist
	@printf '    <key>LSUIElement</key>\n' >> $(plistpath)/Info.plist
	@printf '    <true/>\n' >> $(plistpath)/Info.plist
	@printf '</dict>\n' >> $(plistpath)/Info.plist
	@printf '</plist>\n' >> $(plistpath)/Info.plist
	@clang -framework Cocoa -framework IOKit -o $(execpath)/$(execname) src/main.m src/PristineTouch.m && printf "Build successful: $(version)\n" || printf "Build failed!\n"

c:
	rm -rf build/
