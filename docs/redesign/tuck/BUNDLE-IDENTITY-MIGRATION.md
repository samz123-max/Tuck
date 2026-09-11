# Tuck bundle identity migration

Date: 11 September 2026

Tuck's application bundle identifier is `app.tuck.clipboard`. Its unit-test and UI-test targets use `app.tuck.clipboard.tests` and `app.tuck.clipboard.uitests` respectively.

## Why a local migration is needed

The earlier development builds used Maccy's `org.p0deje.Maccy` identifier. Because the app is sandboxed, changing that identifier gives Tuck a new container; macOS does not let the new app silently read another app's sandbox. This only affects machines that ran a pre-release Tuck build under the legacy identifier.

## One-time local transition

1. Quit Maccy, Slipwell, and Tuck.
2. Build and launch the new Tuck once so macOS creates the `app.tuck.clipboard` sandbox, then quit it.
3. Run `./tools/migrate-to-tuck-identity.sh`.
4. Launch Tuck and verify history, pins, shortcuts, appearance, and ignored-app settings.

The tool copies the existing history and preferences, creates a timestamped private backup under `../artifacts/private-backup`, and leaves the original `org.p0deje.Maccy` container untouched. It refuses to run while any related clipboard process is active. Do not run Maccy and Tuck simultaneously.

## Distribution boundary

This is a development-machine transition tool, not an installer action. Tuck has not yet shipped publicly under the legacy identifier, so the first public release can start cleanly with `app.tuck.clipboard` and requires no end-user identity migration.
