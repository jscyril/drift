import QtQuick
import "../services"

// Pixel switch: a square knob that hops across, leaving the track lit.
Item {
    id: sw
    property bool checked: false
    signal toggled(bool value)

    implicitWidth: 38
    implicitHeight: 18

    PixelBox {
        anchors.fill: parent
        step: 1
        fill: sw.checked ? Theme.alpha(Theme.accent, 0.25) : "transparent"
        stroke: sw.checked ? Theme.accent : Theme.alpha(Theme.dim, 0.45)
    }
    // the trail of lit pixels behind the knob
    Row {
        x: 4; anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Repeater {
            model: 3
            Rectangle {
                required property int index
                width: 2; height: 2
                color: sw.checked ? Theme.accent : Theme.alpha(Theme.dim, 0.3)
                opacity: sw.checked ? 0.4 + index * 0.25 : 0
                Behavior on opacity { NumberAnimation { duration: Theme.dur(200 + index * 80) } }
            }
        }
    }
    Rectangle {
        width: 10; height: 10
        anchors.verticalCenter: parent.verticalCenter
        x: sw.checked ? sw.width - width - 4 : 4
        color: sw.checked ? Theme.accent : Theme.dim
        Behavior on x { NumberAnimation { duration: Theme.dur(240); easing.type: Easing.OutBack; easing.overshoot: 2.5 } }
        Behavior on color { ColorAnimation { duration: Theme.dur(200) } }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: sw.toggled(!sw.checked)
    }
}
