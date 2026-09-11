# Tuck settings redesign

Date: 11 September 2026
Branch: `design/tuck-settings-redesign`

## Product intent

Tuck's settings should help regular users make a few understandable decisions, then get out of the way. The redesign replaces the inherited six-pane toolbar with a native, resizable SwiftUI sidebar window and progressive disclosure.

## Primary navigation

- **General** — launch at login, the global Open Tuck shortcut, automatic paste, update status, and notifications.
- **Appearance** — list style, the Tuck menu-bar icon family, popup location, and automatic previews.
- **Privacy & History** — an explicit local-only privacy statement, excluded applications, remembered content types, friendly history-size presets, pin management, and a confirmed clear-history action.

## Advanced settings

The Advanced Settings sheet preserves the existing specialist controls in four focused sections:

- Behaviour: search algorithm, sort order, pin placement, plain-text paste, custom history limit, and clearing behaviour.
- Interface: detailed menu-bar, content, search, preview, and visibility controls.
- Shortcuts: pin, delete, and preview shortcuts.
- Rules & Automation: pasteboard types, regular expressions, allow-list mode, capture pause, and command-line examples.

No stored preference key was removed or reset. Existing user choices continue to load from the same Defaults keys.

## Technical cleanup

The obsolete third-party Settings window framework and its pane-identifier extension were removed. Tuck now owns the window through `NSWindow`, `NSHostingController`, and native SwiftUI navigation and controls.

## Validation

- Clean Debug arm64 build succeeds.
- All 109 unit tests pass with no failures or skips: `../artifacts/redesign/TuckSettingsRedesignUnitTests.xcresult`.
- Static project and diff validation are clean.
- Visual acceptance remains pending because the Mac was locked during the first automated inspection attempt. The redesign should be reviewed at default and minimum window sizes, in light and dark appearances, before merge.
