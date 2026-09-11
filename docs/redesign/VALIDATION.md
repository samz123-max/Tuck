# Slipwell validation record

> Historical record: these results and captures were produced under the earlier Slipwell working identity. The current product identity is Tuck; its packaging and acceptance evidence is recorded in [Tuck Phase 4](tuck/PHASE-4-RELEASE.md).

Test environment: Apple Silicon Mac, macOS 26.6.2, Xcode 26.6. Upstream reference: `c376789c5d377b7c520b6f6e91f3f3a1aa28640b`.

## Signing update — 7 September 2026, 12:20

After a local Apple Development identity was configured in Xcode, a clean arm64 Release build was signed, installed from the rebuilt DMG, and launched successfully with the existing history. Signature verification passed with the system trust store available; Hardened Runtime remains enabled. No application logic changed and no additional UI suite was run. Signing account and team details are intentionally excluded from this public record.

The current DMG contains this development-signed app; it is not Developer ID signed or notarised. The packaging script distinguishes signing certificate types in its installation notes. Current DMG SHA-256: `c58e1f0955188d4c28388762e25d158bdb12b1b33c37d60d21e9dea95ccdb0a9`.

The artifact checks below describe the preceding ad-hoc build unless otherwise stated.

## Baseline

The unmodified app built successfully for arm64. The original suite reported **119 passed / 8 failed / 127 unique tests** (retries increased execution count). Full summary: [baseline-tests.json](baseline-tests.json).

Two clipboard exclusion tests assume the foreground app is Xcode or Finder. Six UI cases failed around global hotkey activation or popup availability. These were observed before application changes. Baseline tests were run through the same Xcode installation and ad-hoc signing setup used for the redesign.

## Visual evidence

[before-native](before-native) contains native window captures of upstream Maccy. [after-native](after-native) contains Slipwell with the same disposable text, URL, and image fixtures. Numbered filenames identify empty, text, pinned, link, search, no-results, Settings, image, and history states. Both Light and Dark are captured; additional Slipwell frames show Images filtering and Links with search.

Captures use the native Computer Use window capture. XCTest screenshot attachments captured wallpaper behind the unusually high-level Maccy panel and were rejected as visual evidence. Original system appearance was Auto and was restored after capture. Fixture sessions used the upstream DEBUG `enable-testing` option: in-memory history and isolated preferences. However, the separately installed Maccy was later discovered still running and capturing system clipboard fixtures. The isolated test store did not protect that other process. See the isolation incident below.

## Live checks completed

- Typed text using the existing no-results Return workflow, reopened, inspected the text preview.
- Pinned with the visible row button: item moved to Pinned, button became Unpin, popup remained open.
- Navigated between pinned, image, and URL items with arrow keys.
- Captured a real image from Preview; image preview and Images filtering worked.
- Filtered Links, typed `apple`, and confirmed only the matching URL remained with focus in search.
- Cleared search with Control-U and exercised Nothing found and Show all types presentation.
- Opened Settings with Command-comma; shortcut recorder values and original settings panes remained available.
- Inspected accessibility trees: labelled search, native radio buttons for categories, row pin/unpin actions, selected item state, and existing copy/delete actions remain exposed.

## User handover — 7 September 2026

The user explicitly chose to leave the existing history as-is, retain the private backup, and perform additional UI testing themselves. Recovery is therefore no longer a release gate. No snapshot recovery or live-store replacement was performed.

The app is installed and launches from `/Applications/Slipwell.app`. Remaining user acceptance checks include automatic paste permissions/behavior, restart, accessibility display preferences and VoiceOver, remaining shortcut variants, large-history scrolling and installation on another Apple Silicon Mac. These are not claimed as completed. The experimental artifact is ready for that testing; Developer ID signing and notarisation remain unavailable.

## Release artifact checks

The Release app and `Slipwell-Apple-Silicon.dmg` were built successfully. The DMG mounts read-only and contains the app, an Applications shortcut, installation notes and the original MIT licence. The app was copied from that image to `/Applications/Slipwell.app`; the installed executable is arm64 and its ad-hoc signature passes `codesign --verify --deep --strict`. Its dynamic dependencies resolve exclusively to system frameworks/libraries. The new native `.icon` asset compiles into the app and its Finder icon was inspected.

An installed launch exposed a signing mismatch with the inactive Sparkle updater. The experiment already uses manual updates, so the unused framework was removed instead of weakening library validation. The stored upstream update preference remains untouched. A clean Release build and fresh DMG staging directory avoid stale framework files. The corrected app launches normally and displays the existing 200-item history. Hardened Runtime remains enabled. This final packaging change was validated by clean compilation, signature verification, dependency inspection and installed launch; the full test suite results below precede this dependency-only correction.

No Developer ID identity is available; this image is not notarised or signed with a trusted distribution identity. Successful local verification does not establish Gatekeeper acceptance on another Mac.

Final DMG SHA-256: `78419353b6135b08ea56ce9232437a58f9dee71983c8e38c84f70fe9274ee9f3`.

## Isolation incident and recovery

On 6 September, process inspection found the original `/Applications/Maccy.app` still running while isolated test builds used the system clipboard. Its live history contained test UUID fixtures. This also competed for the global shortcut. The original application was quit without clearing its store. The current store and preferences were copied to a private, untracked backup outside this repository.

A local Time Machine snapshot from 6 September at 11:45:52 predates the baseline suite (12:57:22). Recovery required administrator authentication and was not performed. On 7 September the user explicitly chose to leave history as-is and revisit recovery only if needed. Local snapshots can expire, so future recovery is not guaranteed. The post-incident private backup remains available. Earlier assumptions that test-mode isolation protected the separately running original app were incorrect.

The test and preview launch scripts now refuse to start if any Maccy or Slipwell process is already running. Private clipboard data is excluded from the repository, screenshots and distributable.

## Unit results after investigation

All **98 unit tests passed**, including classification across clipboard formats, category composition with every search mode, capture/pin/reload while filtering, and a saved SQLite history reopened with pin and content bytes intact. The earlier empty-pin test crash did not recur in this complete unit run. The clipboard exclusion tests now use the actual foreground application's identifier instead of assuming Xcode or Finder.

Ten measured searches over a 10,000-item history averaged approximately **10.6 ms** in Debug (5,000 matching links). Fixture creation was outside the measured block. This measures search/filter logic, not opening or scrolling latency.

Xcode 26's UI runner reports denied direct PostEvent access, despite its Accessibility entry being enabled. Hotkey tests use XCTest's public keyboard API with explicit modifiers. The direct repeated-key-down case retains its original implementation and explicitly skips when PostEvent is unavailable; held-modifier cycling is checked independently.

## Full UI results

The final full UI run reported **38 passed, 1 skipped, 0 final failures**: [ui-tests.json](ui-tests.json). Combined with the complete unit run, the current suites report **136 passed and 1 skipped** across 137 unique tests. This includes every original test plus ten additions. The baseline was 119 passed and 8 failed across 127 unique tests.

The outside-click/popup test passed on its first retry after an event-synthesis timeout. It is recorded as a retry, not an entirely clean first pass. The skipped test is the direct repeated-key-down case described above. Global opening/closing and held-modifier cycling through second and third items passed.

The full run also passed text/image/file/RTF/HTML copying, capture, numeric shortcuts, search, pin/unpin and deletion during search, clear/clear-all, both temporary capture-disable gestures, no-results Return, hidden-search typing, category composition, and the visible pin button's non-copying behavior.

Additional native preview checks confirmed Control-N/P, Command-Up/Down, Page Up/Down and Control-Space still select and toggle the expected state. These used disposable in-memory history with the installed original app stopped.
