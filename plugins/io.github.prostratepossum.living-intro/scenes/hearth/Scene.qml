import QtQuick

// Moonlit Hearth login intro: snow falls and gathers into the moon-and-cabin
// badge, then "Moonlit Hearth" and "come in from the cold".
Item {
  visible: false

  FontLoader { id: cormorant; source: Qt.resolvedUrl("fonts/CormorantGaramond-Italic.ttf") }

  readonly property color mote: "#e4eef7"      // snow
  readonly property color nebula: "#8fbbe0"    // moonlight
  readonly property color glacier: "#f0c47a"   // hearth amber
  readonly property string fontFamily: cormorant.status === FontLoader.Ready ? cormorant.font.family : ""
  readonly property bool italic: true
  readonly property int titleSize: 66
  readonly property url badge: Qt.resolvedUrl("badge.png")
  readonly property real badgeZoom: 1.3
  readonly property bool fromTop: true         // snow falls from the top
  readonly property int moteSize: 14
  readonly property int moteSizeVariation: 8

  function title(now, user) { return "Moonlit Hearth" }
  function subtitle(user) { return "❄   come in from the cold" + (user ? ", " + user : "") + "   ❄" }
}
