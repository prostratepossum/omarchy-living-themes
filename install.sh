#!/bin/bash
# Living Themes for Omarchy: the shared live wallpaper, lock screen, intro and
# click plugins, the theme switcher, and (optionally) the login screen.
# Theme repos (Alpine Marmot, Moonlit Hearth) run this for you.
#
#   ./install.sh              plugins + theme switcher (living-themes + hook + shell colours)
#   ./install.sh --greeter    ...plus the SDDM login screen (asks for sudo)
#   ./install.sh --sound      ...plus the login chime (themes that ship one)
#   ./install.sh --yes        don't ask before removing the old per-theme plugins
#   ./install.sh --no-plugins only the theme switcher
#   ./install.sh --uninstall  put the stock Omarchy plugins and your own settings back
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
PLUGINS_DIR="$HOME/.config/omarchy/plugins"
HOOK_DIR="$HOME/.config/omarchy/hooks/theme-set.d"
BIN="$HOME/.local/bin/living-themes"
UNIT="$HOME/.config/systemd/user/living-themes-login-sound.service"
STAMP=$(date +%s)
PLUGINS=(io.github.prostratepossum.living-background io.github.prostratepossum.living-lock
         io.github.prostratepossum.living-intro io.github.prostratepossum.living-clicks)
# The per-theme plugins these replace; they fight over the same IPC names.
OLD_PLUGINS=(io.github.prostratepossum.starwatch-background io.github.prostratepossum.starwatch-lock
             io.github.prostratepossum.starwatch-intro io.github.prostratepossum.starwatch-clicks
             io.github.prostratepossum.moonlit-hearth-background io.github.prostratepossum.moonlit-hearth-lock
             io.github.prostratepossum.moonlit-hearth-intro io.github.prostratepossum.moonlit-hearth-clicks)

plugins=1 greeter=0 sound=0 yes=0 uninstall=0
for arg in "$@"; do
  case "$arg" in
  --greeter) greeter=1 ;;
  --sound) sound=1 ;;
  --yes | -y) yes=1 ;;
  --no-plugins) plugins=0 ;;
  --uninstall) uninstall=1 ;;
  -h | --help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

command -v omarchy >/dev/null || { echo "This needs Omarchy (https://omarchy.org)." >&2; exit 1; }

remove_bashrc_block() {
  sed -i '/# >>> living-themes >>>/,/# <<< living-themes <<</d' "$HOME/.bashrc" 2>/dev/null || true
}

if (( uninstall )); then
  [[ -x $BIN ]] && "$BIN" release || true
  for id in "${PLUGINS[@]}"; do omarchy plugin remove "$id" --yes 2>/dev/null || true; done
  omarchy plugin enable omarchy.background >/dev/null 2>&1 || true
  omarchy plugin enable omarchy.lock >/dev/null 2>&1 || true
  omarchy-restart-shell >/dev/null 2>&1 || true
  rm -f "$HOOK_DIR/living-themes.hook" "$BIN"
  remove_bashrc_block
  if [[ -f $UNIT ]]; then
    systemctl --user disable living-themes-login-sound.service 2>/dev/null || true
    rm -f "$UNIT"
    systemctl --user daemon-reload 2>/dev/null || true
  fi
  rm -rf "$HOME/.local/state/living-themes"
  # Drop folders the installer created, if nothing else lives in them.
  rmdir "$HOOK_DIR" "$HOME/.config/omarchy/hooks" "$(dirname "$UNIT")" "$HOME/.config/systemd" "$(dirname "$BIN")" 2>/dev/null || true
  echo "Removed Living Themes; the stock Omarchy background and lock screen are back."
  if [[ -d /usr/share/sddm/themes/living-themes ]]; then
    echo "The login screen is still installed. Remove it with: $SRC/greeter/install.sh --revert"
  fi
  exit 0
fi

if (( plugins )); then
  echo "✦ Installing the Living Themes plugins (live wallpaper, lock screen, intro, click effects)"
  found=()
  for id in "${OLD_PLUGINS[@]}"; do if [[ -d $PLUGINS_DIR/$id ]]; then found+=("$id"); fi; done
  if (( ${#found[@]} )); then
    echo "  These older per-theme plugins do the same job and would clash:"
    printf '    %s\n' "${found[@]}"
    answer=n
    if (( yes )); then
      answer=y
    elif [[ -t 0 ]]; then
      read -rp "  Remove them? [Y/n] " answer
      answer=${answer:-y}
    else
      echo "  Not a terminal, so leaving them alone (rerun with --yes to remove them)."
    fi
    if [[ $answer == [yY]* ]]; then
      for id in "${found[@]}"; do omarchy plugin remove "$id" --yes >/dev/null 2>&1 || rm -rf "${PLUGINS_DIR:?}/$id"; done
      echo "  removed."
    fi
  fi

  mkdir -p "$PLUGINS_DIR"
  for id in "${PLUGINS[@]}"; do
    if [[ -d $PLUGINS_DIR/$id ]] && ! diff -rq "$SRC/plugins/$id" "$PLUGINS_DIR/$id" >/dev/null 2>&1; then
      mv "$PLUGINS_DIR/$id" "$PLUGINS_DIR/.$id.bak.$STAMP"
      echo "  backed up existing $id -> .$id.bak.$STAMP"
    fi
    rm -rf "${PLUGINS_DIR:?}/$id"
    cp -a "$SRC/plugins/$id" "$PLUGINS_DIR/$id"
  done
  # Enabling the background and lock forks switches off the stock ones
  # (they declare clonedFrom); removing them brings the stock ones back.
  omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
  for id in "${PLUGINS[@]}"; do omarchy plugin enable "$id" >/dev/null; done
  omarchy-restart-shell >/dev/null 2>&1 || true

  # The click effects read mouse buttons through evdev.
  if ! /usr/bin/python3 -c 'import evdev' 2>/dev/null; then
    echo "  click effects need python-evdev:  sudo pacman -S python-evdev"
  fi
  if ! id -nG | grep -qw input; then
    echo "  click effects need the input group:  sudo usermod -aG input \$USER  (then log out and back in)"
  fi
fi

echo "✦ Installing the theme switcher (living-themes)"
mkdir -p "$(dirname "$BIN")" "$HOOK_DIR"
install -m755 "$SRC/bin/living-themes" "$BIN"
install -m755 "$SRC/hooks/living-themes.hook" "$HOOK_DIR/living-themes.hook"
remove_bashrc_block
{ echo '# >>> living-themes >>>'; cat "$SRC/extras/bashrc.sh"; echo '# <<< living-themes <<<'; } >> "$HOME/.bashrc"
echo "  added the shell-colour loader to ~/.bashrc"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "  note: ~/.local/bin isn't on your PATH; the hook calls it by full path anyway" ;; esac

if (( sound )); then
  echo "✦ Enabling the login chime"
  mkdir -p "$(dirname "$UNIT")"
  install -m644 "$SRC/extras/systemd/living-themes-login-sound.service" "$UNIT"
  systemctl --user daemon-reload
  systemctl --user enable living-themes-login-sound.service
fi

if (( greeter )); then
  echo "✦ Installing the login screen (sudo)"
  "$SRC/greeter/install.sh"
fi

"$BIN" apply

cat <<DONE

✦ Done. Switching themes now swaps the scene, cursor, prompt and login screen.
  living-themes                                status
  omarchy-shell -q intro play                  replay the login intro
  omarchy-shell lock previewInteractive        preview the lock screen (closes after 90s)
  omarchy-shell -q background toggleAnimation  pause/resume the live wallpaper
  omarchy-shell -q clicks toggle               turn the click effects on/off
DONE
