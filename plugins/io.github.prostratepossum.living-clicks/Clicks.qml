import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "scenes/registry.js" as Scenes

// Living Themes clicks: a small effect wherever you click, matched to the
// Omarchy theme through scenes/registry.js (byTheme). Each scene's Burst.qml
// draws one click; themes with no scene get no effects and the button
// watcher isn't even started.
// clickwatch.py reports button presses; the overlay window only exists while
// a burst is playing and is click-through, and nothing plays over fullscreen
// windows (games, video). Toggle: `omarchy-shell -q clicks toggle`.
Item {
  id: root

  FileView {
    id: themeName
    path: Quickshell.env("HOME") + "/.local/state/omarchy/current/theme.name"
    watchChanges: true
    onFileChanged: reload()
  }
  readonly property string scene: Scenes.forTheme(themeName.text())
  readonly property url burstUrl: scene !== "" ? Qt.resolvedUrl("scenes/" + scene + "/Burst.qml") : ""

  property bool enabled: true
  readonly property bool live: enabled && scene !== ""
  property int maxBursts: 12
  readonly property string helper: String(Qt.resolvedUrl("clickwatch.py")).replace(/^file:\/\//, "")

  ListModel { id: bursts }
  property int nextId: 0

  function spawn(button, gx, gy) {
    if (!live || bursts.count >= maxBursts) return
    bursts.append({ bid: nextId++, button: button, gx: gx, gy: gy, born: Date.now() })
  }

  function finish(bid) {
    for (var i = 0; i < bursts.count; i++) {
      if (bursts.get(i).bid === bid) { bursts.remove(i); return }
    }
  }

  Process {
    id: watcher
    running: root.live
    command: ["setpriv", "--pdeathsig", "TERM", "/usr/bin/python3", root.helper]
    // Exit code 3 = python-evdev missing; retrying would not help.
    onExited: function(code) { if (root.live && code !== 3) restartTimer.restart() }
    stdout: SplitParser {
      onRead: function(line) {
        var p = String(line).trim().split(" ")
        if (p.length === 3) root.spawn(p[0], Number(p[1]), Number(p[2]))
      }
    }
  }

  // A crashed or unplugged watcher comes back on its own.
  Timer {
    id: restartTimer
    interval: 3000
    onTriggered: if (root.live && !watcher.running) watcher.running = true
  }

  IpcHandler {
    target: "clicks"
    function toggle(): void { root.enabled = !root.enabled }
    function setEnabled(on: bool): void { root.enabled = on }
    function test(): void {
      var s = Quickshell.screens[0]
      root.spawn("L", s.x + s.width / 2, s.y + s.height / 2)
    }
    // testButton L|R|M — play one burst at the screen centre.
    function testButton(button: string): void {
      var s = Quickshell.screens[0]
      root.spawn(button, s.x + s.width / 2, s.y + s.height / 2)
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel
      required property var modelData

      readonly property var hyprMonitor: Hyprland.monitorFor(modelData)
      readonly property bool covered: !!(hyprMonitor && hyprMonitor.activeWorkspace && hyprMonitor.activeWorkspace.hasFullscreen)

      function mine(gx, gy) {
        return gx >= modelData.x && gx < modelData.x + modelData.width
          && gy >= modelData.y && gy < modelData.y + modelData.height
      }

      screen: modelData
      visible: bursts.count > 0
      anchors { top: true; bottom: true; left: true; right: true }
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "living-clicks"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      mask: Region {}

      Repeater {
        model: bursts

        delegate: Loader {
          id: slot
          required property int bid
          required property string button
          required property real gx
          required property real gy

          active: panel.mine(gx, gy) && !panel.covered && root.burstUrl !== ""
          x: gx - panel.modelData.x
          y: gy - panel.modelData.y
          onActiveChanged: if (!active) root.finish(bid)
          Component.onCompleted: {
            if (!active) Qt.callLater(root.finish, bid)
            else setSource(root.burstUrl, { button: slot.button })
          }
          onLoaded: item.done.connect(function() { root.finish(slot.bid) })
        }
      }
    }
  }
}
