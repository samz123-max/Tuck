# Tuck identity — Phase 3 menu-bar implementation record

## Implemented family

- **Pocket** is the default.
- **Peek**, **Buddy**, and **Spark** are available alternatives.
- Settings exposes only these four choices, in that order.
- Each option has an explicit accessibility label and help description.
- All assets are single-colour macOS template images with transparent backgrounds at 16 × 16 pixels (1×) and 32 × 32 pixels (2×).

The checked-in PNGs are generated from the Phase 1 vector masters by `tools/render-menu-icons.swift`. The proof page uses the generated PNGs for its native-size light and dark rows.

## Preference compatibility

The legacy raw values `maccy`, `clipboard`, `scissors`, and `paperclip` remain decodable but are excluded from the Settings picker. A one-time `2026-09-09-tuck-menu-icons` migration maps any of them to Pocket. Current Tuck selections pass through the migration unchanged.

Keeping the raw values as hidden compatibility cases avoids a decode failure before the application reaches its migration lifecycle. The obsolete image assets themselves have been removed.

## Acceptance checks

- Asset sources are reproducible and contain alpha at exact 1× and 2× dimensions.
- The asset catalogue declares template rendering for every option.
- Unit coverage is included for the visible order, accessibility labels, legacy mapping, current-value preservation, and template-image behavior.
- A clean build-for-testing compiles the app, the new tests, and all four named assets without missing-image or asset-catalogue warnings.
- The generated PNG proof was inspected at native size in simulated light and dark menu bars.
- With the separately installed Slipwell process stopped, the dedicated unit suite passed all 102 tests with no failures or skips. This includes the four new menu-icon tests. Evidence: `../artifacts/redesign/TuckPhase3UnitTests.xcresult`.
- The complete suite also passed all 102 unit tests, but its UI runner failed before executing a UI test because macOS timed out while enabling XCTest automation mode. Evidence: `../artifacts/redesign/TuckPhase3Tests.xcresult`.
- An isolated UI-only retry reproduced the same runner-initialization timeout before any UI test executed. The generated `.xctestrun` was checked and correctly points its UI target, host, and product paths at `Tuck.app`; no Tuck crash report or stuck app process was found. Evidence: `../artifacts/redesign/TuckPhase3UITestsRetry.xcresult`.
- The remaining UI-suite check is therefore an automation-environment acceptance item rather than a product assertion failure.
