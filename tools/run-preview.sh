#!/bin/zsh
set -eu
cd "${0:A:h:h}"
if /usr/bin/pgrep -f '/Contents/MacOS/(Maccy|Slipwell|Tuck)( |$)' >/dev/null; then
  print -u2 'Quit all running Maccy, Slipwell, and Tuck apps before isolated preview testing.'
  exit 1
fi
variant=${1:-redesign}
shift || true
case "$variant" in
  baseline) product=Maccy ;;
  redesign) product=Tuck ;;
  *) print -u2 'Choose baseline or redesign'; exit 2 ;;
esac
exec "../artifacts/$variant/DerivedData/Build/Products/Debug/$product.app/Contents/MacOS/$product" enable-testing "$@"
