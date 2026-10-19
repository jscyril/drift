import QtQuick
import "../services"

Item {
    id: chip
    property string text
    property string icon
    property bool on: false
    property bool danger: false
    signal clicked()

    readonly property color hue: danger ? Theme.ramp("temp", 1) : Theme.accent
    implicitWidth: row.implicitWidth + 20
    implicitHeight: 24

    PixelBox {
        anchors.fill: parent
        step: 1
        fill: chip.on ? chip.hue : ma.containsMouse ? Theme.alpha(chip.hue, 0.18) : "transparent"
        stroke: chip.on || ma.containsMouse ? chip.hue : Theme.alpha(Theme.dim, 0.4)
    }
    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Icon {
            visible: chip.icon !== ""
            name: chip.icon
            size: 13
            anchors.verticalCenter: parent.verticalCenter
            color: chip.on ? Theme.surface : chip.hue
        }
        Label {
            text: chip.text
            anchors.verticalCenter: parent.verticalCenter
            color: chip.on ? Theme.surface : Theme.fg
        }
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: chip.clicked()
    }
}
