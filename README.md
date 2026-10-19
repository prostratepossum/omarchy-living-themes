# Living Themes

The shared parts of the [Alpine Marmot](https://github.com/prostratepossum/omarchy-alpine-marmot-theme) and [Moonlit Hearth](https://github.com/prostratepossum/omarchy-moonlit-hearth-theme) themes for [Omarchy](https://omarchy.org): the shell plugins for the live wallpaper, lock screen, login intro and click effects, an optional SDDM login screen, and a theme switcher. With it installed you can move between the two themes, or to any other Omarchy theme, and the plugins, cursor, prompt, terminal colours and login screen change to match. Theme-specific boot splashes are offered through a notification, since they need sudo.

You normally don't install this by hand. Both theme installers run it for you.

## What switches

| Piece | How it picks the look |
|---|---|
| **Live wallpaper** (`living-background`) | By wallpaper name. `*starwatch*` gets the Starwatch sky (twinkling stars, fireflies, shooting stars), `*moonlithearth*` gets Moonlit Hearth (falling snow, moon halo, lit windows, chimney smoke). Every other wallpaper is shown as stock Omarchy shows it. Pauses under fullscreen windows. |
| **Lock screen** (`living-lock`) | By wallpaper name. Scenes bring their badge, font, greeting, ambient particles (fireflies or snow) and what each keystroke throws off the password field. Other wallpapers get a plain lock screen in the theme's own colours. |
| **Login intro** (`living-intro`) | By wallpaper name, once per boot. Wallpapers without a scene get no intro. |
| **Click effects** (`living-clicks`) | By theme name. Alpine Marmot: fireflies, sparkles, a ripple. Moonlit Hearth: a drifting snowflake, a frost ring. Other themes get no click effects, and the button watcher doesn't run. |
| **Login screen** (`greeter/`, optional) | The lock screen at the SDDM login, with the current theme's wallpaper and colours plus its scene if it has one. |
| **Theme package** (`living-themes` + hook) | Each theme's `extras/` folder: prompt, lazygit, fastfetch, fzf/eza colours, cursor, login chime, boot splash. Themes without one get your own prompt, lazygit, fastfetch, colours and cursor back; the boot splash stays as it is. |

## Install

Requires an up-to-date Omarchy (the Quickshell-based `omarchy-shell`).

```bash
git clone https://github.com/prostratepossum/omarchy-living-themes.git
cd omarchy-living-themes
./install.sh              # plugins + theme switcher
./install.sh --greeter    # ...plus the SDDM login screen (asks for sudo)
./install.sh --sound      # ...plus the login chime for themes that ship one
```

If you installed an older version of Alpine Marmot or Moonlit Hearth, the installer finds their per-theme plugins (`starwatch-*`, `moonlit-hearth-*`) and offers to remove them, since two lock screens or two backgrounds can't run at once. Pass `--yes` to remove them without asking.

The installer puts `living-themes` in `~/.local/bin`, a hook in `~/.config/omarchy/hooks/theme-set.d/`, and a short block in `~/.bashrc` that loads the theme's fzf/eza colours. Running it again is safe.

**Click effects setup:** the plugin reads mouse buttons through evdev, so it needs:

```bash
sudo pacman -S python-evdev
sudo usermod -aG input $USER   # then log out and back in
```

The helper opens each input device just long enough to see what it is, keeps only pointer devices (anything with a left button and no letter keys), and acts only on button presses. The cursor position comes from Hyprland, so movement isn't recorded. The `input` group lets any program you run read input devices, so skip the click effects if that trade-off isn't for you (`omarchy plugin remove io.github.prostratepossum.living-clicks`).

## The theme switcher

The hook runs `living-themes apply` after every `omarchy theme set`. You can also run it yourself:

```bash
living-themes              # what's active
living-themes apply        # re-apply the current theme's package
living-themes boot         # install the current theme's boot splash (sudo)
living-themes greeter      # refresh the login screen
living-themes list         # themes that ship a package
```

The first time it replaces `~/.config/starship.toml`, `~/.config/lazygit/config.yml` or `~/.config/fastfetch/config.jsonc`, your file is moved to `~/.local/state/living-themes/originals/`. It goes back in place whenever you pick a theme that doesn't ship that file, and on uninstall. The same goes for your cursor.

The boot splash needs your password, so switching to a theme with a different splash sends a notification with an **Update boot splash** button instead of changing it straight away.

### Theme packages

A theme takes part by shipping `extras/` inside its theme folder (`~/.config/omarchy/themes/<theme>/extras/`). Every file is optional:

| File | Used for |
|---|---|
| `starship.toml` | Prompt (`~/.config/starship.toml` links here) |
| `lazygit.yml` | lazygit colours (`~/.config/lazygit/config.yml` links here) |
| `fastfetch.jsonc` | fastfetch config (`~/.config/fastfetch/config.jsonc` links here). Point its logo at `~/.local/state/living-themes/current/fastfetch-logo.txt`. |
| `fastfetch-logo.txt` | The terminal image |
| `shell.sh` | `EZA_COLORS` / `FZF_DEFAULT_OPTS`; shells started after the install pick up a theme change at their next prompt |
| `cursor` | Name of an installed XCursor theme |
| `login.wav` | Login chime (with `--sound`) |
| `boot.sh`, `boot.plymouth` | Command that installs the boot splash, and the Plymouth theme name it sets |

## Try it out

```bash
omarchy-shell -q intro play                  # replay the login intro
omarchy-shell lock previewInteractive        # preview the lock screen without locking (closes after 90 s)
omarchy-shell -q background toggleAnimation  # pause/resume the live wallpaper
omarchy-shell -q clicks testButton L         # play a click effect in the middle of the screen (L, R or M)
omarchy-shell -q clicks toggle               # turn the click effects on/off
```

The live wallpaper uses about 7–9% GPU busy on a Radeon RX 9070 XT. Turn it off with the toggle above if you're on battery.

## Login screen

```bash
./greeter/install.sh            # install and make it the active SDDM theme (sudo)
./greeter/install.sh --revert   # back to your previous login screen
```

SDDM can't read your home folder, so `living-themes` copies the current wallpaper and theme colours into the installed theme's `state/` folder on every switch. That folder stays owned by you, so switching themes never needs sudo. It was checked in SDDM's test mode (`sddm-greeter-qt6 --test-mode --theme <dir>`) with both scenes and with a plain theme.

## Uninstall

```bash
./install.sh --uninstall          # stock Omarchy background and lock screen, your own prompt/cursor/configs back
./greeter/install.sh --revert     # if you installed the login screen
```

## Adding a scene

See [CONTRIBUTING.md](CONTRIBUTING.md). In short: add a `scenes/<name>/` folder to each plugin and to `greeter/`, add the scene to both tables in `shared/registry.js`, and copy the registry into the plugins.

## Notes

- Shaders ship precompiled (`.qsb`). After editing one, rebuild it with
  `/usr/lib/qt6/bin/qsb --glsl "100es,120,150" --hlsl 50 --msl 12 -o <name>.frag.qsb <name>.frag`.
- The background and lock plugins are forks of Omarchy's built-in `omarchy.background` and `omarchy.lock` (MIT). Enabling them switches the stock ones off; removing them brings the stock ones back.

## Credits

- Moonlit Hearth art generated with [FLUX.1 [schnell]](https://huggingface.co/black-forest-labs/FLUX.1-schnell) (Apache-2.0) from original prompts.
- [Cormorant Garamond](https://github.com/CatharsisFonts/Cormorant) (SIL Open Font License 1.1) for the Moonlit Hearth lock screen, intro and login screen. The license is bundled next to each copy.

## License

Code: MIT (see `LICENSE`). Scene artwork (badges, sprites): free for personal use. Please don't resell it or use it in other products without asking.
