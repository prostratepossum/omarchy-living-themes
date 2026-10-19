#!/bin/bash
# Install the Living Themes SDDM login screen (needs sudo; run in a real terminal).
#   ./install.sh           install/update and make it the active login screen
#   ./install.sh --revert  back to your previous login screen
# Preview without installing (shows the default look until living-themes has
# written a state/ folder next to it):
#   sddm-greeter-qt6 --test-mode --theme "$(dirname "$0")"
#
# state/ in the installed theme stays owned by you, so `living-themes` can
# switch the look and copy the wallpaper in without sudo.
set -euo pipefail
SRC=$(cd "$(dirname "$0")" && pwd)
DEST=/usr/share/sddm/themes/living-themes
CONF=/etc/sddm.conf.d/zz-living-themes.conf
ME=$(id -un)

if [[ ${1:-} == --revert ]]; then
  sudo rm -f "$CONF"
  sudo rm -rf "$DEST"
  echo "Reverted: SDDM uses its previous login screen again."
  exit 0
fi

sudo mkdir -p "$DEST/state"
sudo install -m644 "$SRC"/Main.qml "$SRC"/metadata.desktop "$SRC"/theme.conf "$DEST/"
sudo rm -rf "$DEST/scenes"
sudo cp -r "$SRC/scenes" "$DEST/scenes"
sudo chmod -R a+rX "$DEST/scenes"
sudo chown "$ME" "$DEST/state"
sudo chmod 755 "$DEST/state"
[[ -f $DEST/state/Variant.qml ]] || install -m644 "$SRC/state/Variant.qml" "$DEST/state/Variant.qml"
sudo mkdir -p "$(dirname "$CONF")"
printf '[Theme]\nCurrent=living-themes\n' | sudo tee "$CONF" >/dev/null
if command -v living-themes >/dev/null; then living-themes greeter || true; fi
echo "Installed. The next logout shows the Living Themes login screen."
echo "Undo with: $0 --revert"
