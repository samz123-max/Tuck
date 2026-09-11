#!/bin/zsh
# Transfer local pre-release history and preferences into Tuck's new sandbox.
# The original container is never changed or removed.
set -eu

repo_root="${0:A:h:h}"
user_root="${TUCK_MIGRATION_HOME:-${HOME:?A user home directory is required}}"
if [[ "$user_root" != /* || "$user_root" == "/" ]]; then
  print -u2 "Migration home must be an absolute user directory, not /."
  exit 1
fi
legacy_library="$user_root/Library/Containers/org.p0deje.Maccy/Data/Library"
tuck_library="$user_root/Library/Containers/app.tuck.clipboard/Data/Library"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_root="${repo_root:h}/artifacts/private-backup/tuck-identity-migration-$timestamp"

set +e
pgrep -f '/Contents/MacOS/(Maccy|Slipwell|Tuck)( |$)' >/dev/null
process_status=$?
set -e
if [[ $process_status -eq 0 ]]; then
  print -u2 "Quit Maccy, Slipwell, and Tuck before migrating."
  exit 1
elif [[ $process_status -ne 1 ]]; then
  print -u2 "Unable to confirm that clipboard apps are stopped; migration was not started."
  exit 1
fi

if [[ ! -d "$legacy_library" ]]; then
  print -u2 "Legacy container not found: $legacy_library"
  exit 1
fi

if [[ ! -d "$tuck_library" ]]; then
  print -u2 "Tuck's new sandbox has not been created yet. Launch the new build once, quit it, then rerun this tool."
  exit 1
fi

umask 077
mkdir -p "$backup_root/legacy" "$backup_root/new-container-before-migration"

legacy_support="$legacy_library/Application Support/Maccy"
tuck_support="$tuck_library/Application Support/Maccy"
legacy_preferences="$legacy_library/Preferences/org.p0deje.Maccy.plist"
tuck_preferences="$tuck_library/Preferences/app.tuck.clipboard.plist"

if [[ -d "$legacy_support" ]]; then
  ditto "$legacy_support" "$backup_root/legacy/Application Support/Maccy"
  if [[ -e "$tuck_support" ]]; then
    mkdir -p "${tuck_support:h}"
    mv "$tuck_support" "$backup_root/new-container-before-migration/Maccy"
  fi
  mkdir -p "${tuck_support:h}"
  ditto "$legacy_support" "$tuck_support"
fi

if [[ -f "$legacy_preferences" ]]; then
  cp -p "$legacy_preferences" "$backup_root/legacy/org.p0deje.Maccy.plist"
  if [[ -e "$tuck_preferences" ]]; then
    mkdir -p "${tuck_preferences:h}"
    mv "$tuck_preferences" "$backup_root/new-container-before-migration/app.tuck.clipboard.plist"
  fi
  mkdir -p "${tuck_preferences:h}"
  cp -p "$legacy_preferences" "$tuck_preferences"
  plutil -lint "$tuck_preferences" >/dev/null
fi

# UserDefaults is cached by a per-user daemon. Restart it after the on-disk
# domain is replaced so Tuck reads the migrated values on its next launch.
killall cfprefsd 2>/dev/null || true

print "Migration complete."
print "Backup: $backup_root"
print "The original org.p0deje.Maccy container was left unchanged."
