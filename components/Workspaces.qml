import QtQuick
import Quickshell
import "../services"

// Numbered workspace cells for one monitor. The active cell fills up from the
// bottom in 2px steps (and the one you left drains), like a loading block.
Row {
    id: ws
    required property string output

    readonly property var list: Niri.workspacesOn(output)
    readonly property bool outputFocused: Niri.focusedOutput === output
    readonly property int activeIdx: {
        var w = list.find(w => w.is_active)
        return w ? w.idx : 1
    }
    readonly property var occupied: {
        var o = {}
        list.forEach(w => { if (Niri.windowsIn(w.id).length > 0) o[w.idx] = true })
        return o
    }
    readonly property int count: Math.max(Config.opts.workspaceCount, activeIdx, ...Object.keys(occupied).map(Number))
    readonly property int size: Config.opts.barHeight - 8

    spacing: 3

    Repeater {
        model: ws.count
        delegate: Item {
            id: cell
            required property int index
            readonly property int idx: index + 1
            readonly property bool active: idx === ws.activeIdx
            readonly property bool busy: ws.occupied[idx] === true
            readonly property color hue: ws.outputFocused ? Theme.accent : Theme.accent3

            width: ws.size
            height: ws.size

            property real level: active ? 1 : 0
            Behavior on level { NumberAnimation { duration: Theme.dur(cell.active ? 340 : 220); easing.type: Easing.OutCubic } }

            PixelBox {
                anchors.fill: parent
                step: 1
                fill: ma.containsMouse && !cell.active ? Theme.alpha(cell.hue, 0.15) : "transparent"
                stroke: cell.active ? cell.hue : cell.busy ? Theme.alpha(Theme.fg, 0.55) : Theme.alpha(Theme.dim, 0.22)
            }
            Rectangle {
                x: 2
                width: parent.width - 4
                readonly property real full: parent.height - 4
                height: Math.round(cell.level * full / 2) * 2
                y: parent.height - 2 - height
                color: cell.hue
            }
            Label {
                anchors.centerIn: parent
                text: cell.idx
                font.bold: cell.active || cell.busy
                color: cell.level > 0.5 ? Theme.surface : cell.busy ? Theme.fg : Theme.alpha(Theme.dim, 0.5)
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Niri.focusWorkspace(ws.output, cell.idx)
            }
        }
    }

    WheelHandler {
        onWheel: e => Niri.focusWorkspace(ws.output, Math.max(1, Math.min(ws.count, ws.activeIdx + (e.angleDelta.y > 0 ? -1 : 1))))
    }
}
