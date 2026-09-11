# Tuck engineering record

Tuck is an experimental presentation and discoverability redesign of Maccy.

## Recoverable source baseline

- Repository: this source repository.
- Upstream: https://github.com/p0deje/Maccy
- Baseline: c376789c5d377b7c520b6f6e91f3f3a1aa28640b
- Default branch: master, unchanged.
- Completed redesign branch: experiment/modern-macos-ui.
- Tuck identity branch: design/tuck-rebrand.
- Upstream push URL is deliberately DISABLED in the local clone.
- Toolchain: Xcode 26.6, macOS 26.6.2, arm64.
- Unmodified Debug arm64 build: passed with local ad-hoc signing overrides.
- Original build and test evidence lives in ../artifacts/baseline relative to the repository. The baseline build remains available independently of later source changes.

## Existing responsibilities

Clipboard.swift owns capture, exclusion handling, copy, and paste. History and the SwiftData HistoryItem/HistoryItemContent models own deduplication, history size, pin assignments, and persistence. Storage uses Application Support/Maccy/Storage.sqlite. Search implements exact, fuzzy, regular-expression, and mixed modes against existing titles; image text recognition already uses Apple's local Vision framework.

HistoryItemDecorator supplies display state, lazy thumbnails, source-app icons, search highlighting, and accessibility labels. NavigationManager, Popup, KeyChord, and KeyHandlingView implement keyboard selection, numeric shortcuts, configurable pin/delete shortcuts, and cycling. FloatingPanel implements the nonactivating, resizable menu-bar popup. SwiftUI views supply presentation. Settings uses the existing Settings package. No repository AGENTS.md was found.

## Before-state inspection (source record, not screenshots)

- Header: an optional Maccy title inline with a 23-point search field and preview toggle.
- History: compact 24-point rows on macOS 26, shortcut indicators, optional source-app icons, lazy image thumbnails, an accent-colour selection.
- Pins: separate top or bottom group, as selected in preferences. Separation is a divider, with no visible group heading or persistent row pin control.
- Search: defaults to always visible, may be hidden by existing preferences; queries preserve existing search modes. Clearing uses an accessible xmark button.
- No-results: empty history area; Enter can copy the typed query, an existing behavior that must remain.
- Preview: optional side pane with content, source and metadata, and pin/delete/extracted-text controls.
- Footer: keyboard-navigable Clear, Preferences, About, and Quit, with alternate Clear All semantics.
- Settings: General, Storage, Appearance, Pins, Ignore, Advanced; all must remain available.
- Appearance: upstream already uses NSGlassEffectView on macOS 26 and NSVisualEffectView on earlier systems. Retain native materials with accessible fallbacks rather than simulating effects.

## Design decisions

Identity: Tuck, a friendly verb for putting something safely away for later. The retained icon uses ivory paper slips in a deep teal holder. Tuck replaces the earlier Slipwell working identity; name availability and trademark clearance remain outside this engineering record.

Keep the existing nonactivating Mac panel and list workflow. Improve hierarchy with a compact identity line, prominent search, native segmented type filtering, labelled pinned sections, and a direct pin affordance. Do not move keyboard-navigable footer actions into a menu or change their order. Keep existing visibility preferences and pin placement semantics.

Classification belongs outside the persistent models. It should inspect existing pasteboard representations without decoding images, classify deterministically, and compose with the existing search engine. Do not add a schema migration or modify clipboard bytes. All is the neutral/default state, with Text, Links, and Images as refinements; unsupported or other representations remain available in All.

Validation must distinguish existing test assumptions from application regressions. The original suite contains foreground-app-dependent exclusion tests and a custom CGEvent-based global-hotkey harness; preserve the first run before correcting any harness defects.
