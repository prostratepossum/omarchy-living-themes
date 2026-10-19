.pragma library
// Scene registry, shared by every living-* plugin (each plugin ships an
// identical copy as scenes/registry.js).
//
// A scene is a folder scenes/<scene>/ inside each plugin. To add one, drop the
// folders in and add a line to each table below.

// Wallpaper filename substring -> scene. Drives the background, lock screen,
// intro and login screen. Wallpapers that match nothing stay static.
var byWallpaper = [
  { match: "starwatch",     scene: "starwatch" },
  { match: "moonlithearth", scene: "hearth" }
]

// Omarchy theme name -> scene. Drives the click effects, which have no
// wallpaper to go on. Themes not listed here get no click effects.
var byTheme = {
  "alpine-marmot":  "starwatch",
  "moonlit-hearth": "hearth"
}

function fileName(path) {
  var s = String(path || "")
  return s.substring(s.lastIndexOf("/") + 1)
}

// "/…/0-moonlithearth-hearth.jpg" -> "0-moonlithearth-hearth"
function stem(path) {
  return fileName(path).replace(/\.[^.]+$/, "")
}

function forWallpaper(path) {
  var name = fileName(path)
  for (var i = 0; i < byWallpaper.length; i++) {
    if (name.indexOf(byWallpaper[i].match) !== -1) return byWallpaper[i].scene
  }
  return ""
}

function forTheme(name) {
  var key = String(name || "").trim()
  return byTheme.hasOwnProperty(key) ? byTheme[key] : ""
}
