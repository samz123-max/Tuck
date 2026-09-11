#!/bin/zsh
# Build a self-contained arm64 Release app and conventional drag-to-Applications DMG.
# Set TUCK_SIGN_IDENTITY and TUCK_TEAM to use an available signing certificate.
set -eu
cd "${0:A:h:h}"
release_root="${PWD:h}/artifacts/release"
identity="${TUCK_SIGN_IDENTITY:--}"
team="${TUCK_TEAM:-}"
mkdir -p "$release_root"
./tools/xcode.sh -project Maccy.xcodeproj -scheme Maccy -configuration Release \
  -destination 'platform=macOS,arch=arm64' -derivedDataPath "$release_root/DerivedData" \
  -clonedSourcePackagesDirPath "${PWD:h}/artifacts/baseline/DerivedData/SourcePackages" \
  CODE_SIGN_IDENTITY="$identity" CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM="$team" \
  CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO clean build \
  > "$release_root/build.log" 2>&1
app="$release_root/DerivedData/Build/Products/Release/Tuck.app"
codesign --verify --deep --strict --verbose=2 "$app"
[[ "$(lipo -archs "$app/Contents/MacOS/Tuck")" == arm64 ]]
staging="$(mktemp -d "$release_root/DMG-contents.XXXXXX")"
mkdir -p "$staging"
ditto "$app" "$staging/Tuck.app"
[[ -L "$staging/Applications" ]] || ln -s /Applications "$staging/Applications"
cp LICENSE "$staging/License.txt"
cat > "$staging/Read Me.txt" <<'READ_ME'
Tuck — Experimental

Drag Tuck to Applications, then open it from Applications.
Quit Maccy or Slipwell first. Use one version at a time. Tuck uses its own
app.tuck.clipboard identity. Pre-release users can follow the migration guide
in docs/redesign/tuck/BUNDLE-IDENTITY-MIGRATION.md in the source repository.

This build is for Apple Silicon Macs with macOS 14 or later.
Grant Accessibility permission if you use automatic paste.

Derived from Maccy by Alex Rodionov and contributors, under the MIT license.
https://github.com/p0deje/Maccy

This experimental build is locally ad-hoc signed. It is not notarised.
A Developer ID signature and Apple notarisation are still required for
frictionless installation on other Macs. Do not disable macOS security.
READ_ME
authority="$(codesign -d --verbose=2 "$app" 2>&1 | sed -n 's/^Authority=//p' | head -1)"
if [[ "$authority" == "Developer ID Application:"* ]]; then
  sed -i '' 's/This experimental build is locally ad-hoc signed. It is not notarised./This build is Developer ID signed. Check the release notes for notarisation status./' "$staging/Read Me.txt"
elif [[ "$identity" != - ]]; then
  sed -i '' 's/This experimental build is locally ad-hoc signed. It is not notarised./This experimental build is Apple Development signed for testing. It is not notarised./' "$staging/Read Me.txt"
fi
hdiutil create -volname Tuck -srcfolder "$staging" -format UDZO -ov \
  "$release_root/Tuck-Apple-Silicon.dmg"
if [[ "$authority" == "Developer ID Application:"* ]]; then
  codesign --sign "$identity" --timestamp "$release_root/Tuck-Apple-Silicon.dmg"
fi
hdiutil verify "$release_root/Tuck-Apple-Silicon.dmg"
shasum -a 256 "$release_root/Tuck-Apple-Silicon.dmg" > "$release_root/SHA256.txt"
print "Built $release_root/Tuck-Apple-Silicon.dmg"
