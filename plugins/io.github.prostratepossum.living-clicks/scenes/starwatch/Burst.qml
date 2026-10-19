import QtQuick

// Starwatch clicks: fireflies (left), lavender sparkles (right), a glacier
// ripple (middle). Every scene Burst.qml takes `button` (L, R or M), plays
// at its own origin and emits done() when finished.
Item {
  id: scene

  property string button: "L"
  signal done()

  readonly property color firefly: "#e3dc5c"
  readonly property color fireflyCore: "#fffbd0"
  readonly property color nebula: "#9d8fe6"
  readonly property color glacier: "#57add0"

  Timer { interval: 1100; running: true; onTriggered: scene.done() }

  Rings {
    ringColor: scene.button === "R" ? scene.nebula : scene.button === "M" ? scene.glacier : scene.firefly
    count: scene.button === "M" ? 3 : 1
  }

  Repeater {
    model: scene.button === "L" ? 7 : 0
    Firefly {
      required property int index
      angle: (index / 7) * Math.PI * 2 + Math.random() * 0.7
      distance: 22 + Math.random() * 26
      lift: 10 + Math.random() * 14
      size: 5 + Math.random() * 3.5
      duration: 650 + Math.random() * 350
    }
  }

  Repeater {
    model: scene.button === "R" ? 5 : 0
    Sparkle {
      required property int index
      angle: (index / 5) * Math.PI * 2 - Math.PI / 2 + Math.random() * 0.5
      distance: 18 + Math.random() * 18
      size: 11 + Math.random() * 7
      duration: 700 + Math.random() * 300
      color: index % 2 ? scene.nebula : scene.fireflyCore
    }
  }

  // Expanding rings, then done() after `life` ms.
  component Rings: Item {
    id: rings
    property color ringColor: "white"
    property int count: 1
    Repeater {
      model: rings.count
      Rectangle {
        required property int index
        property real r: 0
        x: -r; y: -r
        width: r * 2; height: r * 2
        radius: r
        color: "transparent"
        border.width: 1.6
        border.color: rings.ringColor
        opacity: 0
        SequentialAnimation on r {
          PauseAnimation { duration: index * 120 }
          NumberAnimation { from: 3; to: 26 + index * 6; duration: 520; easing.type: Easing.OutCubic }
        }
        SequentialAnimation on opacity {
          PauseAnimation { duration: index * 120 }
          NumberAnimation { from: 0.85; to: 0; duration: 520; easing.type: Easing.InQuad }
        }
      }
    }
  }

  component Firefly: Item {
    id: fly
    property real angle: 0
    property real distance: 30
    property real lift: 12
    property real size: 5
    property int duration: 800
    property real p: 0

    x: Math.cos(angle) * distance * p
    y: Math.sin(angle) * distance * p - lift * p * p
    opacity: p < 0.25 ? p / 0.25 : 1 - (p - 0.25) / 0.75

    Rectangle {
      width: fly.size * 3.2; height: width; radius: width / 2
      x: -width / 2; y: -height / 2
      color: scene.firefly
      opacity: 0.3
    }
    Rectangle {
      width: fly.size * 1.8; height: width; radius: width / 2
      x: -width / 2; y: -height / 2
      color: scene.firefly
      opacity: 0.65
    }
    Rectangle {
      width: fly.size * 0.8; height: width; radius: width / 2
      x: -width / 2; y: -height / 2
      color: scene.fireflyCore
    }

    NumberAnimation on p { from: 0; to: 1; duration: fly.duration; easing.type: Easing.OutQuad }
  }

  component Sparkle: Text {
    id: spark
    property real angle: 0
    property real distance: 24
    property real size: 12
    property int duration: 800
    property real p: 0

    text: "✦"
    font.pixelSize: size
    x: Math.cos(angle) * distance * p - width / 2
    y: Math.sin(angle) * distance * p - height / 2
    rotation: p * 90
    scale: p < 0.3 ? 0.4 + p * 2 : 1 - (p - 0.3) * 0.8
    opacity: 1 - p * p

    NumberAnimation on p { from: 0; to: 1; duration: spark.duration; easing.type: Easing.OutCubic }
  }
}
