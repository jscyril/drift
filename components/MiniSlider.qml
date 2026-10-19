import QtQuick
import "../services"

// Settings slider: segment bar + value. Emits moved(value) snapped to step.
Item {
    id: s
    property real from: 0
    property real to: 1
    property real step: 0.01
    property real value: 0
    property var format: v => v.toFixed(2)
    property string ramp: "mem"
    signal moved(real value)

    implicitWidth: 300
    implicitHeight: 20

    Meter {
        id: meter
        anchors.verticalCenter: parent.verticalCenter
        value: (s.value - s.from) / (s.to - s.from)
        ramp: s.ramp
        segments: Math.max(8, Math.floor((s.width - 56) / 5))
        segW: 4
        segH: 12
    }
    Label {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: s.format(s.value)
        color: Theme.hue(s.ramp)
        font.bold: true
    }
    MouseArea {
        anchors.fill: meter
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        function set(mx) {
            var t = Math.max(0, Math.min(1, (mx - 4) / meter.width))
            var v = Math.round((s.from + t * (s.to - s.from)) / s.step) * s.step
            if (Math.abs(v - s.value) > 1e-9) s.moved(Number(v.toFixed(4)))
        }
        onPressed: e => set(e.x)
        onPositionChanged: e => { if (pressed) set(e.x) }
    }
}
