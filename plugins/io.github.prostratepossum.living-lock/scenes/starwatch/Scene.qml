import QtQuick

// Starwatch look for the lock screen: marmot badge, firefly palette, fireflies
// rising from the meadow, firefly sparks on each keystroke.
Item {
  visible: false

  readonly property color glow: "#e3dc5c"      // fireflies, clock glow, cursor
  readonly property color nebula: "#9d8fe6"
  readonly property color glacier: "#57add0"
  readonly property string fontFamily: ""      // "" = the shell font
  readonly property bool italic: false
  readonly property int greetingSize: 17
  readonly property url badge: Qt.resolvedUrl("badge.png")
  readonly property real badgeZoom: 1
  readonly property color warmGlow: "transparent"

  function greeting(now, user) {
    var h = now.getHours()
    var g = h >= 5 && h < 12 ? "good morning"
      : h >= 12 && h < 17 ? "good afternoon"
      : h >= 17 && h < 21 ? "good evening"
      : "the stars are out"
    return "󰖔  " + g + (user ? ", " + user : "")
  }
  function shuffle() {}

  // Fireflies drifting up out of the meadow.
  readonly property var ambient: ({
    color: "#e3dc5c", colorVariation: 0.06, alpha: 0.9,
    x: 0, y: 0.62, w: 1, h: 0.38,
    rate: 2.5, life: 11000, lifeVariation: 4000, size: 16, sizeVariation: 10, endSize: 6,
    angle: 270, angleVariation: 30, speed: 12, speedVariation: 8,
    wanderX: 40, wanderY: 12, pace: 30
  })

  // Keystroke sparks: firefly dots thrown up off the field.
  readonly property var spark: ({
    image: "qrc:///particleresources/glowdot.png", color: "#e3dc5c", colorVariation: 0.12,
    rotationVariation: 0, rotationVelocityVariation: 0,
    life: 1300, size: 12, endSize: 2, angleVariation: 55, speed: 70, speedVariation: 40, fall: 25
  })
}
