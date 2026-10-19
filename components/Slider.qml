import QtQuick
import "../services"

// Big block slider for quick settings: a row of gradient segments.
// Click or drag anywhere; scroll to nudge; click the icon for its action.
Item {
    id: slider
    property real value: 0          // 0..1
    property string icon
    property string ramp: "mem"
    signal moved(real value)
    signal iconClicked()
    signal rightClicked()

    implicitHeight: 28
    readonly property int segs: Math.max(8, Math.floor((width - 70) / 6))

    RoundButton {
        id: iconBtn
        anchors.verticalCenter: parent.verticalCenter
        icon: slider.icon
        hue: Theme.hue(slider.ramp)
        onClicked: slider.iconClicked()
        onRightClicked: slider.rightClicked()
    }

    Meter {
        id: meter
        anchors.left: iconBtn.right
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        value: slider.value
        ramp: slider.ramp
        segments: slider.segs
        segW: 5
        segH: 16
    }

    Label {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(slider.value * 100) + "%"
        color: Theme.hue(slider.ramp)
        font.bold: true
    }

    MouseArea {
        anchors.fill: meter
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        function set(mx) { slider.moved(Math.max(0, Math.min(1, mx / meter.width))) }
        onPressed: e => e.button === Qt.RightButton ? slider.rightClicked() : set(e.x)
        onPositionChanged: e => { if (pressed && (pressedButtons & Qt.LeftButton)) set(e.x) }
        onWheel: e => slider.moved(Math.max(0, Math.min(1, slider.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
