# Tuck

**A happy little home for everything you copy.** Tuck is an experimental macOS redesign of [Maccy](https://github.com/p0deje/Maccy), built from its existing native application rather than a replacement clipboard engine.

## What changed

- A clearer header, focused search field and native All / Text / Links / Images control.
- Visible pin and unpin buttons, a labelled Pinned area, and the existing pin shortcuts and ordering options.
- More comfortable row spacing, restrained native materials, readable selection across system accent colours, and accessibility labels on new controls.
- A new name and original icon featuring paper slips gathered in a small teal holder.
- A playful menu-bar icon family: Pocket by default, with Peek, Buddy, and Spark alternatives.
- A modern native Settings window with three approachable sections and power-user controls kept behind Advanced Settings.

Categories refine the existing search. Links are complete HTTP, HTTPS or email links; text containing a link remains Text. Images are recognised by their clipboard formats. Files and other supported formats remain available in All. Classification is local, deterministic, cached only in memory, and adds no stored fields or migration.

## Still Maccy underneath

Clipboard capture, deduplication, paste and formatting actions, exclusion rules, pin letters, keyboard shortcuts, history limits, preferences and SwiftData models retain the upstream implementations. Existing exact, fuzzy, mixed and regular-expression search preferences remain supported. No account, telemetry, service, AI classifier or runtime dependency was added. Existing on-device image text recognition remains intact.

Tuck uses its own `app.tuck.clipboard` bundle identifier. Existing local development history and preferences can be transferred once with the documented migration tool; the original Maccy container is left intact as a fallback. Quit Maccy before running Tuck and run one version at a time. Tuck targets Apple Silicon and macOS 14 or later, using native glass on macOS 26 and native material fallbacks on earlier systems.

Automatic upstream updates are disabled for this experiment so Maccy's updater cannot replace Tuck with the original app. The stored preference is retained; the update control explains the experimental distribution. Updates to Tuck are manual.

The inactive Sparkle updater framework is not bundled. The release keeps Hardened Runtime enabled and needs no developer tools or external runtime files.

## Installation and signing

The Tuck release DMG will contain Tuck and an Applications shortcut. Drag Tuck to Applications, then open it there. Grant the normal Accessibility permission if you use automatic paste. Do not run it alongside Maccy or the earlier redesign build.

You can also copy the complete `Tuck.app` bundle from Applications to another Apple Silicon Mac. Clipboard history and preferences are separate local data; copying the app does not copy them. Additional UI acceptance testing is being performed by the project owner.

Packaging and signing will be revalidated as Tuck in Phase 4. The earlier redesign release was signed with the project owner’s Apple Development certificate; it was a testing build, not Developer ID signed or notarised. Distribution to other Macs still requires Developer ID signing and Apple notarisation for the conventional Gatekeeper experience. No security setting is disabled by this project.

## Development

Build and test Tuck with the Tuck scheme and Swift module:

```sh
./tools/xcode.sh -project Tuck.xcodeproj -scheme Tuck -configuration Debug \
  -destination 'platform=macOS,arch=arm64' CODE_SIGN_IDENTITY=- \
  CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= test
```

See [architecture](docs/redesign/ARCHITECTURE.md) and the [historical validation record](docs/redesign/VALIDATION.md), including captures of the earlier working identity and the baseline test comparison.

## Attribution

Derived from Maccy by Alex (p0deje) and its contributors. Original copyright and the [MIT licence](LICENSE) are retained. Tuck is an independent experimental fork, not an official Maccy release. Existing third-party acknowledgements remain included.
