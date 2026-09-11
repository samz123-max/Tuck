# Tuck identity — Phase 2 implementation record

## Scope

Phase 2 replaces the visible Slipwell working identity with Tuck without changing clipboard behaviour, persistence, menu-bar icon choices, or their defaults.

## Applied identity

- App bundle and executable display name: **Tuck**
- Finder and system display name: **Tuck**
- Header and Settings window: **Tuck**
- About and update messaging: **Tuck**
- Status-item accessibility name: **Tuck — clipboard history**, localised suffix retained
- Tagline: **A happy little home for everything you copy.**
- Application icon artwork: retained unchanged and renamed as a Tuck source asset
- Release-tool output contract: `Tuck.app` and `Tuck-Apple-Silicon.dmg`

## Compatibility invariants

- `PRODUCT_BUNDLE_IDENTIFIER` remains `org.p0deje.Maccy`.
- The Swift module and Xcode scheme remain Maccy.
- Application Support storage and standard preferences remain Maccy's existing locations.
- Localised `defaults write` examples use the real `org.p0deje.Maccy` preference domain.
- Test and preview guards recognise Maccy, the earlier Slipwell build, and Tuck so only one clipboard process can run.
- The Phase 3 menu icon migration has not been implemented here.

> Superseded on 11 September 2026: Tuck now uses `app.tuck.clipboard`. See
> [BUNDLE-IDENTITY-MIGRATION.md](BUNDLE-IDENTITY-MIGRATION.md) for the current identity and local-data transition.

## Historical evidence

The existing validation record, screenshots, and test JSON retain Slipwell where they describe artifacts that were genuinely produced under that working identity. They are historical evidence, not current product naming.

## Verification

- Project, scheme, Info.plist, and every localised strings file parse successfully.
- A clean Debug arm64 build succeeds using the existing pinned package checkout.
- The resulting bundle is `Tuck.app` with executable, display name, and bundle name `Tuck`.
- The built identifier remains `org.p0deje.Maccy`.
- The clean bundle contains `Tuck.icns` and no stale Slipwell icon resource.
- Full clipboard tests were not launched while the separately installed Slipwell process was running, preserving the project's clipboard-isolation rule. The build and static identity checks are sufficient for this phase; the complete suite remains part of Phase 4 acceptance.
