# Tuck project identity

The developer-facing application identity now matches the shipped Tuck product.

## Renamed

- Xcode project and shared scheme: `Tuck.xcodeproj` and `Tuck`
- Main target, Swift module and app entry point: `Tuck`
- Source, unit-test and UI-test directories and targets
- Test plan, entitlements file, build scripts and repository tooling
- App Intent descriptions, issue templates and current documentation

The current Tuck README is the repository root `README.md`. The inherited Maccy README is retained as `README-Maccy.md` for upstream reference.

## Intentionally retained

- `org.p0deje.Maccy` is retained only as a legacy bundle and pasteboard identifier.
- `Application Support/Maccy` remains the internal storage location to avoid an unnecessary clipboard-history migration.
- Maccy names in migration tooling, compatibility tests, upstream issue links, historical validation records, licence notices and attribution remain accurate by design.

## Validation

- The Debug and Release configurations build from the Tuck project and scheme.
- Build settings report `Tuck` for the project, target, product, executable and Swift module.
- The bundle identifier remains `app.tuck.clipboard`.
- All 111 unit tests passed after the rename.
- The Apple Silicon Release app and DMG passed signature, architecture and disk-image verification.
