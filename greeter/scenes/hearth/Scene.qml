import QtQuick

// Moonlit Hearth look for the login screen: moon-and-cabin badge, Cormorant
// Garamond, snow, warm firelight behind the field, snowflake keystrokes.
Item {
  visible: false

  FontLoader { id: cormorant; source: Qt.resolvedUrl("fonts/CormorantGaramond-Italic.ttf") }

  readonly property color glow: "#f0c47a"
  readonly property color nebula: "#8fbbe0"
  readonly property color glacier: "#e4eef7"
  readonly property string fontFamily: cormorant.status === FontLoader.Ready ? cormorant.font.family : ""
  readonly property bool italic: false
  readonly property int greetingSize: 24
  readonly property url badge: Qt.resolvedUrl("badge.png")
  readonly property real badgeZoom: 1.3
  readonly property color warmGlow: "#f0b35e"
  readonly property string failure: "the door is still latched"
  readonly property string footer: "the hearth is lit"

  function greeting(user) { return "❄   come in from the cold" + (user ? ", " + user : "") + "   ❄" }

  readonly property var ambient: ({
    color: "#e4eef7", colorVariation: 0.04, alpha: 0.75,
    x: -0.1, y: -0.02, w: 1.2, h: 0.01,
    rate: 6, life: 16000, lifeVariation: 4000, size: 14, sizeVariation: 8, endSize: 10,
    angle: 95, angleVariation: 12, speed: 70, speedVariation: 30,
    wanderX: 60, wanderY: 0, pace: 40
  })
  readonly property var spark: ({
    image: Qt.resolvedUrl("flake.png"), color: "#eef5fc", colorVariation: 0.03,
    rotationVariation: 180, rotationVelocityVariation: 90,
    life: 2200, size: 15, endSize: 9, angleVariation: 70, speed: 45, speedVariation: 20, fall: 60
  })
}
