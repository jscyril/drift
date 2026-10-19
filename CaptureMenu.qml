import QtQuick
import Quickshell
import Quickshell.Wayland
import "services"
import "components"

// Capture menu (Print / Mod+Shift+X): screenshots and recordings.
// Keys 1-5 pick, ←/→ + Enter work too, Esc closes.
PanelWindow {
    id: menu
    signal close()

    screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) || Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "drift-capture"
    color: "transparent"

    readonly property var actions: Capture.recording
        ? [{ icon: "close", label: "stop recording", ramp: "temp", run: () => Capture.stop() }]
        : [
            { icon: "crop", label: "region", ramp: "down", run: () => Capture.shot("region") },
            { icon: "monitor", label: "screen", ramp: "gh", run: () => Capture.shot("screen") },
            { icon: "window", label: "window", ramp: "mem", run: () => Capture.shot("window") },
            { icon: "record", label: "rec region", ramp: "temp", run: () => Capture.record("region") },
            { icon: "video", label: "rec screen", ramp: "temp", run: () => Capture.record("screen") }
        ]
    property int sel: 0
    function activate(i) { var a = actions[i]; close(); a.run() }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.surface, 0.6)
        MouseArea { anchors.fill: parent; onClicked: menu.close() }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            var n = menu.actions.length
            if (e.key === Qt.Key_Escape || e.key === Qt.Key_Q) menu.close()
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_H) menu.sel = (menu.sel + n - 1) % n
            else if (e.key === Qt.Key_Right || e.key === Qt.Key_L || e.key === Qt.Key_Tab) menu.sel = (menu.sel + 1) % n
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) menu.activate(menu.sel)
            else if (e.key >= Qt.Key_1 && e.key < Qt.Key_1 + n) menu.activate(e.key - Qt.Key_1)
            else if (e.key === Qt.Key_E) Capture.edit = !Capture.edit
            else if (e.key === Qt.Key_A) Capture.audio = !Capture.audio
            else if (e.key === Qt.Key_D) Capture.delay = Capture.delay === 0 ? 3 : Capture.delay === 3 ? 5 : 0
            e.accepted = true
        }
    }

    PixelBox {
        id: panel
        anchors.centerIn: parent
        width: tiles.width + 40
        height: col.height + 40
        step: 4
        fill: Theme.alpha(Theme.surface, 0.97)
        stroke: Capture.recording ? Theme.ramp("temp", 1) : Theme.accent
        title: Capture.recording ? "recording " + Theme.clockSecs(Capture.recSecs) : "capture"
        titleColor: Capture.recording ? Theme.ramp("temp", 1) : Theme.accent
        MouseArea { anchors.fill: parent }

        Column {
            id: col
            x: 20; y: 22
            spacing: 16

            Row {
                id: tiles
                spacing: 12
                Repeater {
                    model: menu.actions
                    Item {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool cur: menu.sel === index
                        readonly property color hue: Theme.hue(modelData.ramp)
                        width: Capture.recording ? 220 : 104; height: 104
                        PixelBox {
                            anchors.fill: parent
                            step: 3
                            fill: tile.cur ? Theme.alpha(tile.hue, 0.2) : Theme.alpha(Theme.bg, 0.9)
                            stroke: tile.cur ? tile.hue : Theme.alpha(Theme.dim, 0.35)
                            title: tile.cur && !Capture.recording ? "[" + (tile.index + 1) + "]" : ""
                            titleColor: tile.hue
                        }
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: tile.modelData.icon; size: 32; color: tile.cur ? tile.hue : Theme.fg }
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: tile.modelData.label; color: tile.cur ? tile.hue : Theme.dim; font.bold: tile.cur }
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: menu.sel = tile.index
                            onClicked: menu.activate(tile.index)
                        }
                    }
                }
            }

            // options
            Row {
                visible: !Capture.recording
                spacing: 18
                Row {
                    spacing: 8
                    Switch { checked: Capture.edit; onToggled: v => Capture.edit = v; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "[e]dit after"; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                }
                Row {
                    spacing: 8
                    Switch { checked: Capture.audio; onToggled: v => Capture.audio = v; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "[a]udio"; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                }
                Row {
                    spacing: 8
                    Label { text: "[d]elay"; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                    Segmented {
                        options: [{ label: "0s", value: 0 }, { label: "3s", value: 3 }, { label: "5s", value: 5 }]
                        value: Capture.delay
                        onPicked: v => Capture.delay = v
                    }
                }
            }
        }
    }
}
