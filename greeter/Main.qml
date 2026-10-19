import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import QtQuick.Particles
import SddmComponents 2.0
import "state"

// Living Themes SDDM greeter: the lock screen brought to the login screen.
// SDDM can't read your home folder, so `living-themes` writes state/Variant.qml
// (scene, wallpaper name, theme colors) and copies the current wallpaper into
// state/ on every theme switch. A scene (scenes/<scene>/) adds its live layer,
// badge, font and particles; any other theme gets its own wallpaper and
// colors with a plain badge-less layout.
Rectangle {
  id: root
  width: 1920
  height: 1080
  color: pal.background

  Variant { id: variant }

  // The scene's look, or the plain look below for themes without one.
  Loader {
    id: sceneLoader
    source: variant.scene !== "" ? "scenes/" + variant.scene + "/Scene.qml" : ""
  }
  readonly property var look: sceneLoader.item ? sceneLoader.item : plain

  QtObject {
    id: plain
    readonly property color glow: variant.accent
    readonly property color nebula: Qt.lighter(variant.accent, 1.3)
    readonly property color glacier: variant.foreground
    readonly property string fontFamily: ""
    readonly property bool italic: false
    readonly property int greetingSize: 17
    readonly property url badge: ""
    readonly property real badgeZoom: 1
    readonly property color warmGlow: "transparent"
    readonly property string failure: "wrong password"
    readonly property string footer: "enter to log in"
    function greeting(user) { return "welcome back" + (user ? ", " + user : "") }
    readonly property var ambient: null
    readonly property var spark: ({
      image: "qrc:///particleresources/glowdot.png", color: variant.accent, colorVariation: 0.1,
      rotationVariation: 0, rotationVelocityVariation: 0,
      life: 1300, size: 12, endSize: 2, angleVariation: 55, speed: 70, speedVariation: 40, fall: 25
    })
  }

  // Theme colors from the current Omarchy theme, accents from the scene.
  QtObject {
    id: pal
    readonly property color background: variant.background
    readonly property color foreground: variant.foreground
    readonly property color accent: variant.accent
    readonly property color urgent: variant.urgent
    readonly property color glow: root.look.glow
    readonly property color nebula: root.look.nebula
    readonly property color glacier: root.look.glacier
    readonly property color clock: Qt.lighter(foreground, 1.18)
  }

  function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

  readonly property string monoFont: "JetBrainsMono Nerd Font"
  readonly property string displayFont: look.fontFamily !== "" ? look.fontFamily : monoFont
  readonly property var ambient: look.ambient
  readonly property var spark: look.spark
  readonly property bool hasBadge: String(look.badge) !== ""
  readonly property string wallpaperUrl: variant.wallpaper !== "" ? Qt.resolvedUrl("state/" + variant.wallpaper) : ""

  // --- Login state ----------------------------------------------------------
  property string currentUser: userModel.lastUser
  property int sessionIndex: {
    for (var i = 0; i < sessionModel.rowCount(); i++) {
      var name = (sessionModel.data(sessionModel.index(i, 0), Qt.DisplayRole) || "").toString()
      if (name.indexOf("uwsm") !== -1)
        return i
    }
    return sessionModel.lastIndex
  }
  property bool authenticating: false
  property string failureMessage: ""
  readonly property bool errorState: failureMessage.length > 0

  Connections {
    target: sddm
    function onLoginFailed() {
      root.authenticating = false
      root.failureMessage = root.look.failure
      passwordInput.text = ""
      passwordInput.forceActiveFocus()
      shakeAnimation.restart()
      sparkEmitter.burst(14)
    }
    function onLoginSucceeded() {
      root.failureMessage = ""
    }
  }

  function submit() {
    if (passwordInput.text.length === 0 || authenticating) return
    authenticating = true
    sparkEmitter.burst(10)
    sddm.login(currentUser, passwordInput.text, sessionIndex)
  }

  // --- Clocks ---------------------------------------------------------------
  property real t: 0
  property real ringAngle: 0
  property real intro: 0
  property real shake: 0
  property real typingPulse: 0
  property date now: new Date()
  property int lastLength: 0

  Timer {
    interval: 33
    repeat: true
    running: true
    onTriggered: {
      var dt = interval / 1000
      root.t += dt
      var speed = root.authenticating ? 320 : (root.errorState ? 12 : 28)
      root.ringAngle = (root.ringAngle + dt * speed) % 360
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  NumberAnimation on intro { from: 0; to: 1; duration: 1800; easing.type: Easing.OutCubic }

  SequentialAnimation {
    id: shakeAnimation
    NumberAnimation { target: root; property: "shake"; to: 16; duration: 45; easing.type: Easing.OutQuad }
    NumberAnimation { target: root; property: "shake"; to: -13; duration: 70; easing.type: Easing.InOutQuad }
    NumberAnimation { target: root; property: "shake"; to: 9; duration: 65; easing.type: Easing.InOutQuad }
    NumberAnimation { target: root; property: "shake"; to: -5; duration: 60; easing.type: Easing.InOutQuad }
    NumberAnimation { target: root; property: "shake"; to: 0; duration: 80; easing.type: Easing.OutQuad }
  }

  NumberAnimation {
    id: typingPulseAnimation
    target: root
    property: "typingPulse"
    from: 1
    to: 0
    duration: 700
    easing.type: Easing.OutCubic
  }

  // --- Backdrop -------------------------------------------------------------
  Item {
    id: sky
    anchors.fill: parent
    scale: 1.0 + 0.03 * (0.5 - 0.5 * Math.cos(root.t * 2 * Math.PI / 70))
    opacity: 0.25 + 0.75 * root.intro

    Image {
      id: wallpaper
      anchors.fill: parent
      source: root.wallpaperUrl
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
    }

    Loader {
      anchors.fill: parent
      active: variant.scene !== "" && root.wallpaperUrl !== ""
      Component.onCompleted: if (active) setSource("scenes/" + variant.scene + "/Layer.qml", {
        stem: variant.stem, wallpaper: root.wallpaperUrl, running: true
      })
    }
  }

  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: root.alpha(pal.background, 0.55) }
      GradientStop { position: 0.45; color: root.alpha(pal.background, 0.12) }
      GradientStop { position: 1.0; color: root.alpha(pal.background, 0.55) }
    }
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: "transparent"
      fillGradient: RadialGradient {
        centerX: root.width / 2; centerY: root.height / 2
        focalX: centerX; focalY: centerY
        centerRadius: Math.min(root.width, root.height) * 0.55
        focalRadius: 0
        GradientStop { position: 0.0; color: root.alpha(pal.background, 0.55) }
        GradientStop { position: 0.6; color: root.alpha(pal.background, 0.18) }
        GradientStop { position: 1.0; color: "transparent" }
      }
      PathRectangle { x: 0; y: 0; width: root.width; height: root.height }
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: passwordInput.forceActiveFocus()
  }

  // --- Ambient particles (fireflies, snow) and keystroke sparks ------------
  ParticleSystem { id: particles; anchors.fill: parent }

  ImageParticle {
    system: particles
    groups: ["spark"]
    anchors.fill: parent
    source: root.spark.image
    color: root.errorState ? pal.urgent : root.spark.color
    colorVariation: root.spark.colorVariation
    rotationVariation: root.spark.rotationVariation
    rotationVelocityVariation: root.spark.rotationVelocityVariation
    entryEffect: ImageParticle.Fade
  }

  ImageParticle {
    system: particles
    groups: ["ambient"]
    anchors.fill: parent
    source: "qrc:///particleresources/glowdot.png"
    color: root.ambient ? root.ambient.color : "white"
    colorVariation: root.ambient ? root.ambient.colorVariation : 0
    alpha: root.ambient ? root.ambient.alpha : 0
    entryEffect: ImageParticle.Fade
  }

  Emitter {
    system: particles
    group: "ambient"
    enabled: !!root.ambient
    x: parent.width * (root.ambient ? root.ambient.x : 0)
    y: parent.height * (root.ambient ? root.ambient.y : 0)
    width: parent.width * (root.ambient ? root.ambient.w : 1)
    height: Math.max(4, parent.height * (root.ambient ? root.ambient.h : 0))
    emitRate: root.ambient ? root.ambient.rate : 0
    lifeSpan: root.ambient ? root.ambient.life : 1000
    lifeSpanVariation: root.ambient ? root.ambient.lifeVariation : 0
    size: root.ambient ? root.ambient.size : 1
    sizeVariation: root.ambient ? root.ambient.sizeVariation : 0
    endSize: root.ambient ? root.ambient.endSize : 1
    velocity: AngleDirection {
      angle: root.ambient ? root.ambient.angle : 0
      angleVariation: root.ambient ? root.ambient.angleVariation : 0
      magnitude: root.ambient ? root.ambient.speed : 0
      magnitudeVariation: root.ambient ? root.ambient.speedVariation : 0
    }
  }

  Wander {
    system: particles
    groups: ["ambient"]
    anchors.fill: parent
    xVariance: root.ambient ? root.ambient.wanderX : 0
    yVariance: root.ambient ? root.ambient.wanderY : 0
    pace: root.ambient ? root.ambient.pace : 0
  }

  // --- Centre block ---------------------------------------------------------
  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: -30 + 30 * (1 - root.intro)
    opacity: root.intro
    spacing: 0

    Item {
      id: badgeBox
      anchors.horizontalCenter: parent.horizontalCenter
      visible: root.hasBadge
      readonly property real zoom: root.look.badgeZoom
      width: root.hasBadge ? 170 * zoom : 0
      height: root.hasBadge ? 170 * zoom : 0

      Item {
        width: 170
        height: 170
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 5 * Math.sin(root.t * 0.8)
        scale: badgeBox.zoom

        Rectangle {
          anchors.centerIn: parent
          width: 150; height: 150; radius: 75
          color: "transparent"
          border.width: 10
          border.color: root.alpha(pal.accent, 0.6 + 0.3 * Math.sin(root.t * 1.3))
          layer.enabled: true
          layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 40 }
        }

        Shape {
          anchors.fill: parent
          preferredRendererType: Shape.CurveRenderer
          ShapePath {
            strokeColor: "transparent"
            fillRule: ShapePath.OddEvenFill
            fillGradient: ConicalGradient {
              centerX: 85; centerY: 85
              angle: -root.ringAngle * 1.6
              GradientStop { position: 0.0; color: pal.accent }
              GradientStop { position: 0.3; color: pal.nebula }
              GradientStop { position: 0.55; color: root.alpha(pal.glow, 0.15) }
              GradientStop { position: 0.8; color: pal.glacier }
              GradientStop { position: 1.0; color: pal.accent }
            }
            PathRectangle { x: 10; y: 10; width: 150; height: 150; radius: 75 }
            PathRectangle { x: 12.5; y: 12.5; width: 145; height: 145; radius: 72.5 }
          }
        }

        Image {
          anchors.centerIn: parent
          width: 138; height: 138
          source: root.look.badge
          sourceSize: Qt.size(276, 276)
          smooth: true
          mipmap: true
        }
      }
    }

    Item { width: 1; height: 18 }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      textFormat: Text.PlainText
      text: root.look.greeting(root.currentUser)
      color: root.alpha(pal.foreground, 0.85)
      font.family: root.displayFont
      font.pixelSize: root.look.greetingSize
      font.italic: root.look.italic
      font.letterSpacing: 1.5
    }

    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: clockRow.implicitWidth
      height: clockRow.implicitHeight - 20

      Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: 2
        layer.enabled: true
        layer.effect: MultiEffect {
          shadowEnabled: true
          shadowColor: pal.glow
          shadowBlur: 1.0
          shadowOpacity: 0.5 + 0.2 * Math.sin(root.t * 0.9)
          shadowHorizontalOffset: 0
          shadowVerticalOffset: 0
          blurMax: 48
        }

        Repeater {
          model: ["HH", ":", "mm"]
          Text {
            textFormat: Text.PlainText
            text: modelData === ":" ? ":" : Qt.formatTime(root.now, modelData)
            color: pal.clock
            opacity: modelData === ":" ? 0.3 + 0.7 * (0.5 + 0.5 * Math.cos(root.t * Math.PI)) : 1
            font.family: root.displayFont
            font.pixelSize: 132
            font.weight: Font.Light
          }
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      textFormat: Text.PlainText
      text: Qt.formatDate(root.now, "dddd  ·  d MMMM").toUpperCase()
      color: Qt.lighter(pal.accent, 1.25)
      font.family: root.displayFont
      font.pixelSize: 16
      font.letterSpacing: 6
    }

    Item { width: 1; height: 52 }

    // --- Password field -----------------------------------------------------
    Item {
      anchors.horizontalCenter: parent.horizontalCenter
      width: 420 + 60
      height: 62 + 60

      Item {
        id: field
        width: 420
        height: 62
        x: 30 + root.shake
        y: 30
        readonly property real r: height / 2
        readonly property int ring: 2

        // Scenes with a warmGlow (Hearth): firelight behind the field,
        // swelling a little as you type.
        Rectangle {
          visible: root.look.warmGlow.a > 0
          anchors.centerIn: parent
          width: parent.width + 110
          height: parent.height + 80
          radius: height / 2
          color: root.errorState ? pal.urgent : root.look.warmGlow
          opacity: 0.2 + 0.04 * Math.sin(root.t * 2.3) + 0.02 * Math.sin(root.t * 5.7) + 0.25 * root.typingPulse
          layer.enabled: visible
          layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 64 }
        }

        Shape {
          anchors.fill: parent
          preferredRendererType: Shape.CurveRenderer
          opacity: (root.errorState ? 0.9 : 0.45 + 0.15 * Math.sin(root.t * 1.1)) + 0.5 * root.typingPulse
          layer.enabled: true
          layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 36 }
          ShapePath {
            strokeColor: "transparent"
            fillRule: ShapePath.OddEvenFill
            fillGradient: ringGradient
            PathRectangle { x: -3; y: -3; width: field.width + 6; height: field.height + 6; radius: field.r + 3 }
            PathRectangle { x: 3; y: 3; width: field.width - 6; height: field.height - 6; radius: field.r - 3 }
          }
        }

        Rectangle {
          anchors.fill: parent
          radius: field.r
          color: root.alpha(pal.background, 0.72)
        }

        Shape {
          anchors.fill: parent
          preferredRendererType: Shape.CurveRenderer
          ShapePath {
            strokeColor: "transparent"
            fillRule: ShapePath.OddEvenFill
            fillGradient: ConicalGradient {
              id: ringGradient
              centerX: field.width / 2; centerY: field.height / 2
              angle: root.ringAngle
              GradientStop { position: 0.0; color: root.errorState ? pal.urgent : pal.accent }
              GradientStop { position: 0.25; color: root.errorState ? Qt.darker(pal.urgent, 1.6) : pal.nebula }
              GradientStop { position: 0.5; color: root.errorState ? pal.urgent : pal.glow }
              GradientStop { position: 0.75; color: root.errorState ? Qt.darker(pal.urgent, 1.6) : pal.glacier }
              GradientStop { position: 1.0; color: root.errorState ? pal.urgent : pal.accent }
            }
            PathRectangle { x: 0; y: 0; width: field.width; height: field.height; radius: field.r }
            PathRectangle {
              x: field.ring; y: field.ring
              width: field.width - 2 * field.ring; height: field.height - 2 * field.ring
              radius: field.r - field.ring
            }
          }
        }

        Emitter {
          id: sparkEmitter
          system: particles
          group: "spark"
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.leftMargin: field.r
          anchors.rightMargin: field.r
          y: 0
          height: 4
          enabled: false
          lifeSpan: root.spark.life
          lifeSpanVariation: 400
          size: root.spark.size
          sizeVariation: 6
          endSize: root.spark.endSize
          velocity: AngleDirection { angle: 270; angleVariation: root.spark.angleVariation; magnitude: root.spark.speed; magnitudeVariation: root.spark.speedVariation }
          acceleration: PointDirection { y: root.spark.fall }
        }

        TextInput {
          id: passwordInput
          anchors.fill: parent
          anchors.leftMargin: field.r
          anchors.rightMargin: field.r
          verticalAlignment: TextInput.AlignVCenter
          horizontalAlignment: TextInput.AlignHCenter
          clip: true
          focus: true
          readOnly: root.authenticating
          echoMode: TextInput.Password
          passwordCharacter: "●"
          passwordMaskDelay: 0
          color: pal.clock
          selectionColor: pal.accent
          font.family: root.monoFont
          font.pixelSize: text.length > 0 ? 28 : 23
          font.letterSpacing: text.length > 0 ? 7 : 0
          cursorDelegate: Rectangle {
            width: 2
            color: pal.glow
            visible: passwordInput.activeFocus && passwordInput.text.length > 0 && !root.authenticating
          }

          onTextChanged: {
            if (text.length > root.lastLength) {
              sparkEmitter.burst(4)
              typingPulseAnimation.restart()
            }
            root.lastLength = text.length
            if (text.length > 0) root.failureMessage = ""
          }

          onAccepted: root.submit()

          Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
              text = ""
              event.accepted = true
            }
          }
        }

        Text {
          textFormat: Text.PlainText
          anchors.fill: passwordInput
          text: root.authenticating ? "Checking…" : (root.errorState ? root.failureMessage : "Enter Password")
          visible: passwordInput.text.length === 0
          color: root.errorState ? pal.urgent : root.alpha(pal.foreground, 0.5)
          opacity: root.authenticating ? 0.55 + 0.45 * Math.sin(root.t * 6) : 1
          font.family: root.monoFont
          font.pixelSize: 23
          font.italic: root.errorState
          font.letterSpacing: 1
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      textFormat: Text.PlainText
      text: root.look.footer + "   ·   esc to clear"
      color: root.alpha(pal.foreground, 0.35)
      font.family: root.monoFont
      font.pixelSize: 12
      font.letterSpacing: 2
    }
  }

  // --- Power ----------------------------------------------------------------
  Row {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: 32
    spacing: 28
    opacity: 0.35 + 0.65 * root.intro * (powerHover.containsMouse || rebootHover.containsMouse ? 1 : 0.5)

    Text {
      text: "󰜉"
      color: rebootHover.containsMouse ? pal.accent : pal.foreground
      font.family: root.monoFont
      font.pixelSize: 22
      visible: sddm.canReboot
      MouseArea { id: rebootHover; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; onClicked: sddm.reboot() }
    }
    Text {
      text: "󰐥"
      color: powerHover.containsMouse ? pal.urgent : pal.foreground
      font.family: root.monoFont
      font.pixelSize: 22
      visible: sddm.canPowerOff
      MouseArea { id: powerHover; anchors.fill: parent; anchors.margins: -8; hoverEnabled: true; onClicked: sddm.powerOff() }
    }
  }

  Component.onCompleted: passwordInput.forceActiveFocus()
}
