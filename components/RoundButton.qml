import QtQuick
import "../services"

// Square pixel icon button (name kept so cards don't need renaming).
Item {
    id: btn
    property string icon
    property real iconSize: 14
    property bool filled: false
    property bool danger: false          // armed state for confirm-twice buttons
    property color hue: Theme.accent
    signal clicked()
    signal rightClicked()

    implicitWidth: 28
    implicitHeight: 28
    opacity: enabled ? 1 : 0.35

    PixelBox {
        anchors.fill: parent
        fill: btn.danger ? Theme.ramp("temp", 1) : btn.filled ? btn.hue : ma.containsMouse ? Theme.alpha(btn.hue, 0.18) : "transparent"
        stroke: btn.danger ? Theme.ramp("temp", 1) : ma.containsMouse || btn.filled ? btn.hue : Theme.alpha(Theme.dim, 0.35)
    }
    Icon {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: ma.pressed ? 1 : 0
        name: btn.icon
        size: btn.iconSize
        color: btn.filled || btn.danger ? Theme.surface : ma.containsMouse ? btn.hue : Theme.fg
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? btn.rightClicked() : btn.clicked()
    }
}
