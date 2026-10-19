import QtQuick

// Starwatch login intro: fireflies rise out of the meadow and gather into the
// marmot badge, then a time-of-day greeting and "welcome back".
Item {
  visible: false

  readonly property color mote: "#e3dc5c"      // the particles, title glow, iris rim
  readonly property color nebula: "#9d8fe6"
  readonly property color glacier: "#57add0"
  readonly property string fontFamily: ""      // "" = the shell font
  readonly property bool italic: false
  readonly property int titleSize: 58
  readonly property url badge: Qt.resolvedUrl("badge.png")
  readonly property real badgeZoom: 1
  readonly property bool fromTop: false        // fireflies rise from the bottom
  readonly property int moteSize: 18
  readonly property int moteSizeVariation: 10

  function title(now, user) {
    var h = now.getHours()
    if (h >= 5 && h < 12) return "good morning"
    if (h >= 12 && h < 17) return "good afternoon"
    if (h >= 17 && h < 21) return "good evening"
    return "the stars are out"
  }
  function subtitle(user) { return "✦  welcome back" + (user ? ", " + user : "") + "  ✦" }
}
