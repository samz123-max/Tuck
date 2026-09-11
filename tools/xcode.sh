#!/bin/zsh
set -eu
cd "${0:A:h:h}"
for argument in "$@"; do
  if [[ "$argument" == test || "$argument" == test-without-building ]]; then
    if /usr/bin/pgrep -f '/Contents/MacOS/(Maccy|Slipwell|Tuck)( |$)' >/dev/null; then
      print -u2 'Quit all running Maccy, Slipwell, and Tuck apps before clipboard tests. Tests use the system clipboard.'
      exit 1
    fi
  fi
done
exec xcodebuild "$@"
