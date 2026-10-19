# Adding a scene

A scene is the animated look for one theme. Each plugin, and the login screen, keeps its scenes in its own `scenes/<name>/` folder. A new theme needs those folders plus an entry in each of the registry's two tables; nothing else in the plugins changes.

## 1. Register it

`shared/registry.js` is the scene registry. Every plugin carries an identical copy as `scenes/registry.js`; edit the shared one and copy it over:

```bash
for p in plugins/*/scenes; do cp shared/registry.js "$p/registry.js"; done
```

Add your scene to both tables:

```js
var byWallpaper = [
  { match: "starwatch",     scene: "starwatch" },
  { match: "moonlithearth", scene: "hearth" },
  { match: "mynewtheme",    scene: "mynew" }      // wallpapers named *mynewtheme*
]

var byTheme = {
  "alpine-marmot":  "starwatch",
  "moonlit-hearth": "hearth",
  "my-new-theme":   "mynew"                       // click effects for this Omarchy theme
}
```

`living-themes` reads `byWallpaper` from the installed background plugin when it updates the login screen, so keep each entry on one line in that format.

## 2. Add the folders

Copy an existing scene and change it. `hearth` is the most complete example.

| Folder | Files | What they do |
|---|---|---|
| `plugins/…-background/scenes/<name>/` | `Layer.qml` (+ shader, images) | Draws the whole wallpaper plus its animation. |
| `plugins/…-lock/scenes/<name>/` | `Scene.qml`, `Layer.qml`, `badge.png` (+ fonts, sprites) | Look of the lock screen, and the same live layer. |
| `plugins/…-intro/scenes/<name>/` | `Scene.qml`, `Layer.qml`, `badge.png` (+ the layer's shader and any fonts) | Look of the login intro. |
| `plugins/…-clicks/scenes/<name>/` | `Burst.qml` | One click effect. |
| `greeter/scenes/<name>/` | `Scene.qml`, `Layer.qml`, `badge.png` (+ the layer's shader, fonts and keystroke sprite) | Look of the SDDM login screen. |

### Layer.qml

Every `Layer.qml` exposes the same properties. The plugins set them; the layer handles the rest, including loading the wallpaper itself.

```qml
property string stem: ""      // wallpaper file name without extension, e.g. "0-moonlithearth-hearth"
property url wallpaper        // the wallpaper image
property bool running: false  // animate only while true
```

Use `stem` when one scene covers several wallpapers that need different positions (Moonlit Hearth keeps a table of moon, window and chimney positions per wallpaper).

### Scene.qml (lock screen and login screen)

An invisible `Item` with these properties. Copy `scenes/hearth/Scene.qml` for the full list:

- `glow`, `nebula`, `glacier`: accent colours for the clock glow, rings and cursor
- `fontFamily` (`""` for the shell font), `italic`, `greetingSize`
- `badge`, `badgeZoom`
- `warmGlow`: colour of the light behind the password field, `"transparent"` for none
- `greeting(now, user)` (lock) or `greeting(user)`, `failure`, `footer` (login screen)
- `shuffle()`: called each time the lock screen appears (pick a new line, or do nothing)
- `ambient`: the background particles (rate, size, direction, …), or `null` for none
- `spark`: what each keystroke throws off the field

### Scene.qml (intro)

`mote`, `nebula`, `glacier`, `fontFamily`, `italic`, `titleSize`, `badge`, `badgeZoom`, `fromTop` (particles fall from the top instead of rising), `moteSize`, `moteSizeVariation`, `title(now, user)` and `subtitle(user)`.

### Burst.qml (clicks)

Takes `property string button` (`"L"`, `"R"` or `"M"`), plays at its own origin, and emits `done()` when it's finished. Keep it short and subtle; it plays on every click.

## 3. Test it

- Lint: `/usr/lib/qt6/bin/qmllint <file>` (look for `[syntax]` lines).
- Render a layer on its own: a small `Window` that loads `scenes/<name>/Layer.qml` at 1280×720 and saves a frame with `grabToImage`, run with `/usr/lib/qt6/bin/qml`.
- Lock screen (restarts your shell): `omarchy-restart-shell`, then `omarchy-shell lock previewInteractive`.
- Login screen: copy `greeter/` somewhere, write a `state/Variant.qml` for your scene, put a wallpaper next to it as `state/wallpaper.jpg`, and run `sddm-greeter-qt6 --test-mode --theme <that dir>`.
- `omarchy plugin validate plugins/<plugin>` before submitting.
