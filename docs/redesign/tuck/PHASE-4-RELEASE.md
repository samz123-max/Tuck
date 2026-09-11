# Tuck identity — Phase 4 release-readiness record

Date: 11 September 2026

## Outcome

The approved Tuck redesign is merged into `master` and is ready for the user's remaining deferred manual UI acceptance. A clean Apple Silicon Release candidate and installable disk image have been produced and validated.

This is an experimental local build, not a public distribution build. The current machine has no valid code-signing identity, so the artifact is ad-hoc signed and is not notarised.

## Acceptance evidence

- The dedicated unit suite passes all **102 tests**, with no failures or skips. This includes the Tuck menu-icon order, labels, template rendering, legacy-value migration, and current-value preservation checks. Evidence: `../artifacts/redesign/TuckPhase3UnitTests.xcresult`.
- The approved Compact, Comfortable, and Detailed list styles and refined Tuck heading/tagline pass all **106 unit tests**. This includes preference persistence and the curated style contract. Evidence: `../artifacts/redesign/TuckListStylesFinalTests.xcresult`.
- The final bundle-identity suite passes all **107 unit tests**, with no failures or skips. It includes Tuck's new pasteboard marker and legacy-marker compatibility. Evidence: `../artifacts/redesign/TuckBundleIdentityUnitTests.xcresult`.
- A clean arm64 Release build succeeds. The only compiler diagnostics are existing Swift 6 sendability warnings; there are no build errors or asset-catalogue warnings.
- The final Release app launches successfully in isolated `enable-testing` mode and terminates cleanly after the startup smoke test.
- Bundle name, display name, and executable are `Tuck`; the bundle identifier is now `app.tuck.clipboard` and the minimum macOS version remains 14.0.
- The executable is arm64 and links only against macOS system frameworks and libraries. No obsolete embedded Sparkle framework is present.
- The app signature passes deep, strict verification with Hardened Runtime enabled. Release packaging explicitly disables injected base entitlements, so the final app does not contain the debug-only `get-task-allow` entitlement.
- The disk image passes `hdiutil verify`. A read-only mount contains `Tuck.app`, an `/Applications` shortcut, the matching MIT licence, and installation notes that tell users to quit Maccy or Slipwell before launching Tuck.
- The packaged application contains no Slipwell-branded resources. Remaining legacy Maccy identifiers are limited to compatibility handling, recovery tooling, tests, attribution, or historical documentation.

## Release candidate

- App: `../artifacts/release/DerivedData/Build/Products/Release/Tuck.app`
- Disk image: `../artifacts/release/Tuck-Apple-Silicon.dmg`
- SHA-256: `841a0bfae1238b95e2b63899ee5e984ffa4820b43c7b48f302871c7111e0ce11`
- Checksum file: `../artifacts/release/SHA256.txt`
- Signing: ad-hoc, Hardened Runtime enabled, not notarised

The packaging script can later produce a signed candidate by setting `TUCK_SIGN_IDENTITY` and `TUCK_TEAM`. Developer ID signing and Apple notarisation are still required before external public distribution.

## Deferred acceptance

The user will perform the remaining UI checks later. The XCTest UI runner was attempted twice in Phase 3 but timed out while enabling macOS automation mode before any UI test executed; this was an automation-environment failure, not a product assertion failure.

Manual acceptance should cover menu-bar rendering for all four icons in light and dark appearances, icon switching and persistence after restart, automatic paste permissions and behaviour, VoiceOver/accessibility presentation, shortcut variants, large-history scrolling, and installation on another Apple Silicon Mac.

## Phase status

Phase 4 is complete for implementation and local release readiness. The subsequent Tuck identity update uses `app.tuck.clipboard`, with a tested one-time migration for pre-release local data. Public distribution remains gated on Developer ID signing, notarisation, and the user's deferred UI acceptance.
