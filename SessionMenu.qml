import QtQuick
import Quickshell
import Quickshell.Wayland
import "services"
import "components"

// Fullscreen session menu (Win+Z). Arrows/hjkl or hover to pick, Enter or click
// to run, the letter keys jump straight to an action, Esc closes. Log out,
// reboot and power off need a second press.
PanelWindow {
    id: menu
    signal close()

    screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) || Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "drift-session"
    color: "transparent"

    readonly property var actions: [
        { key: "l", icon: "lock", label: "lock", ramp: "down", cmd: System.lockCmd },
        { key: "m", icon: "monitor", label: "screen off", ramp: "gh", cmd: "sleep 0.6; niri msg action power-off-monitors" },
        { key: "s", icon: "sleep", label: "sleep", ramp: "mem", cmd: "systemctl suspend" },
        { key: "e", icon: "account", label: "log out", ramp: "time", cmd: "niri msg action quit --skip-confirmation", confirm: true },
        { key: "r", icon: "restart", label: "reboot", ramp: "cpu", cmd: "systemctl reboot", confirm: true },
        { key: "p", icon: "power", label: "power off", ramp: "temp", cmd: "systemctl poweroff", confirm: true }
    ]
    property int sel: 0
    property int armed: -1        // index waiting for its confirming second press

    function activate(i) {
        var a = actions[i]
        sel = i
        if (a.confirm && armed !== i) { armed = i; disarm.restart(); return }
        menu.close()
        System.run(a.cmd)
    }
    Timer { id: disarm; interval: 3000; onTriggered: menu.armed = -1 }

    // backdrop: dimmed, scanlined; click empty space to close
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Theme.alpha(Theme.surface, 0.93)
        opacity: 0
        NumberAnimation on opacity { to: 1; duration: Theme.dur(160) }
        MouseArea { anchors.fill: parent; onClicked: menu.close() }
    }
    Canvas {
        anchors.fill: parent
        visible: Config.opts.scanlines
        enabled: false
        onPaint: {
            var ctx = getContext("2d")
            ctx.fillStyle = "rgba(0,0,0,0.12)"
            for (var y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1)
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            var n = menu.actions.length
            if (e.key === Qt.Key_Escape || e.key === Qt.Key_Q) menu.close()
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_H || e.key === Qt.Key_Backtab) { menu.sel = (menu.sel + n - 1) % n; menu.armed = -1 }
            else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) { menu.sel = (menu.sel + 1) % n; menu.armed = -1 }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) menu.activate(menu.sel)
            else {
                var i = menu.actions.findIndex(a => a.key === e.text.toLowerCase())
                if (i >= 0) menu.activate(i)
            }
            e.accepted = true
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 34

        // header: clock + who/uptime/battery
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Clock { anchors.horizontalCenter: parent.horizontalCenter; pixelSize: 66 }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                color: Theme.dim
                text: Quickshell.env("USER") + " · up " + Theme.duration(Stats.uptime)
                    + (System.hasBattery ? " · battery " + System.batteryPct + "%" : "")
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 18
            Repeater {
                model: menu.actions
                Item {
                    id: tile
                    required property var modelData
                    required property int index
                    readonly property bool cur: menu.sel === index
                    readonly property bool hot: menu.armed === index
                    readonly property color hue: hot ? Theme.ramp("temp", 1) : Theme.hue(modelData.ramp)
                    width: 132; height: 150

                    // staggered pop-in
                    opacity: 0
                    scale: 0.85
                    Component.onCompleted: popIn.start()
                    SequentialAnimation {
                        id: popIn
                        PauseAnimation { duration: Theme.dur(40 * tile.index) }
                        ParallelAnimation {
                            NumberAnimation { target: tile; property: "opacity"; to: 1; duration: Theme.dur(160) }
                            NumberAnimation { target: tile; property: "scale"; to: 1; duration: Theme.dur(260); easing.type: Easing.OutBack; easing.overshoot: 2 }
                        }
                    }

                    PixelBox {
                        anchors.fill: parent
                        step: 4
                        fill: tile.hot ? Theme.alpha(tile.hue, 0.35) : tile.cur ? Theme.alpha(tile.hue, 0.18) : Theme.alpha(Theme.bg, 0.9)
                        stroke: tile.cur || tile.hot ? tile.hue : Theme.alpha(Theme.dim, 0.35)
                        title: tile.cur ? "[" + tile.modelData.key + "]" : ""
                        titleColor: tile.hue
                    }
                    Column {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: tile.cur ? -2 : 0
                        spacing: 14
                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: tile.modelData.icon
                            size: 46
                            color: tile.cur || tile.hot ? tile.hue : Theme.fg
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.hot ? "again?" : tile.modelData.label
                            font.bold: tile.cur
                            color: tile.cur || tile.hot ? tile.hue : Theme.dim
                        }
                    }
                    // segmented underline that fills on the selected tile
                    Meter {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 12
                        value: tile.cur ? 1 : 0
                        ramp: tile.hot ? "temp" : tile.modelData.ramp
                        segments: 14; segW: 6; segH: 3
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: if (menu.sel !== tile.index) { menu.sel = tile.index; menu.armed = -1 }
                        onClicked: menu.activate(tile.index)
                    }
                }
            }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            color: Theme.alpha(Theme.dim, 0.7)
            text: menu.armed >= 0 ? "press again to " + menu.actions[menu.armed].label + " · esc to cancel"
                : "←/→ pick · enter run · letter jumps · esc close"
        }
    }
}
