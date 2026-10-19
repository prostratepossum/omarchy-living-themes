import QtQuick

// Moonlit Hearth clicks, small, slow and quiet: a snowflake turns as it drifts
// down (left drifts left, right drifts right); middle leaves a faint frost
// ring and a few settling motes.
Item {
  id: scene

  property string button: "L"
  signal done()

  readonly property color snow: "#e4eef7"
  readonly property color frost: "#d4e3f0"

  Timer { interval: 1700; running: true; onTriggered: scene.done() }

  Snowflake {
    visible: scene.button !== "M"
    drift: scene.button === "R" ? 1 : -1
  }

  Rings {
    visible: scene.button === "M"
    ringColor: Qt.rgba(0.83, 0.89, 0.94, 0.55)
  }

  Repeater {
    model: scene.button === "M" ? 5 : 0
    Mote {
      required property int index
      x0: (index - 2) * 6 + (Math.random() - 0.5) * 6
      fall: 14 + Math.random() * 14
      delay: Math.random() * 220
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

  // A snowflake, turning slowly as it drifts down.
  component Snowflake: Item {
    id: sf
    property real drift: 1
    property real p: 0
    x: sf.drift * 16 * p + 4 * Math.sin(p * 7)
    y: 26 * p
    opacity: p < 0.12 ? p / 0.12 * 0.85 : 0.85 * (1 - Math.pow((p - 0.12) / 0.88, 1.5))
    Text {
      text: "❄"
      textFormat: Text.PlainText
      color: scene.snow
      font.pixelSize: 17
      x: -width / 2; y: -height / 2
      rotation: sf.drift * 90 * sf.p
      style: Text.Outline
      styleColor: Qt.rgba(0.04, 0.08, 0.14, 0.35)
    }
    NumberAnimation on p { from: 0; to: 1; duration: 1600; easing.type: Easing.OutSine }
  }

  // Frost motes that settle slowly downward.
  component Mote: Rectangle {
    id: mote
    property real x0: 0
    property real fall: 24
    property int delay: 0
    property real p: 0
    width: 2.2; height: 2.2; radius: 1.1
    color: scene.frost
    x: x0 + 3 * Math.sin(p * 5 + x0) - 1.1
    y: -4 + fall * p - 1.1
    opacity: p <= 0 ? 0 : 0.55 * Math.sin(Math.PI * Math.min(1, p * 1.1))
    SequentialAnimation on p {
      PauseAnimation { duration: mote.delay }
      NumberAnimation { from: 0; to: 1; duration: 1400; easing.type: Easing.OutQuad }
    }
  }
}
