import QtQuick
import QtQuick.Particles

// Starwatch live layer. Re-renders the wallpaper through starwatch.frag, which
// twinkles its stars, drifts and pulses the fireflies painted in the grass and
// sends the odd shooting star across the sky; glowing fireflies also rise out
// of the meadow and wander. Same interface as every scene Layer.qml.
Item {
  id: layer

  property string stem: ""
  property url wallpaper
  property bool running: false
  property real time: 0

  Timer {
    interval: 33
    repeat: true
    running: layer.running
    onTriggered: layer.time = (layer.time + interval / 1000) % 3400
  }

  Image {
    id: plate
    anchors.fill: parent
    source: layer.wallpaper
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: true
    visible: false
  }

  ShaderEffect {
    anchors.fill: parent
    visible: plate.status === Image.Ready
    property var source: plate
    property real time: layer.time
    property vector2d texel: Qt.vector2d(1 / Math.max(1, plate.sourceSize.width), 1 / Math.max(1, plate.sourceSize.height))
    property real aspect: width / Math.max(1, height)
    fragmentShader: Qt.resolvedUrl("starwatch.frag.qsb")
  }

  ParticleSystem {
    id: fireflies
    anchors.fill: parent
    running: layer.running
  }

  ImageParticle {
    system: fireflies
    anchors.fill: parent
    source: "qrc:///particleresources/glowdot.png"
    color: "#e3dc5c"
    colorVariation: 0.06
    alpha: 0.9
    entryEffect: ImageParticle.Fade
  }

  Emitter {
    system: fireflies
    x: 0
    y: parent.height * 0.62
    width: parent.width
    height: parent.height * 0.38
    emitRate: 2.5
    lifeSpan: 11000
    lifeSpanVariation: 4000
    size: 16
    sizeVariation: 10
    endSize: 6
    velocity: AngleDirection { angle: 270; angleVariation: 30; magnitude: 12; magnitudeVariation: 8 }
  }

  Wander {
    system: fireflies
    anchors.fill: parent
    xVariance: 40
    yVariance: 12
    pace: 30
  }
}
