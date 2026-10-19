import QtQuick
import "../services"

// Quick-settings toggle in a pixel box: [■] title / subtitle.
Item {
    id: tile
    property bool on: false
    property string icon
    property string title
    property string subtitle
    property color hue: Theme.accent
    signal clicked()
    signal rightClicked()

    implicitHeight: 44

    PixelBox {
        anchors.fill: parent
        fill: tile.on ? Theme.alpha(tile.hue, 0.20) : ma.containsMouse ? Theme.alpha(Theme.fg, 0.05) : "transparent"
        stroke: tile.on ? tile.hue : Theme.alpha(Theme.dim, ma.containsMouse ? 0.6 : 0.3)
    }

    Icon {
        id: ic
        x: 10
        anchors.verticalCenter: parent.verticalCenter
        name: tile.icon
        size: 18
        color: tile.on ? tile.hue : Theme.dim
    }

    Column {
        anchors.left: ic.right
        anchors.leftMargin: 10
        anchors.right: led.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Label { width: parent.width; text: tile.title; font.bold: true; color: tile.on ? Theme.fg : Theme.dim }
        Label { width: parent.width; visible: text !== ""; text: tile.subtitle; color: tile.on ? tile.hue : Theme.alpha(Theme.dim, 0.7) }
    }

    // status LED
    Rectangle {
        id: led
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 6; height: 6
        color: tile.on ? tile.hue : Theme.alpha(Theme.dim, 0.3)
        SequentialAnimation on opacity {
            running: tile.on
            loops: Animation.Infinite
            NumberAnimation { to: 0.4; duration: 1200 }
            NumberAnimation { to: 1; duration: 1200 }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: e => e.button === Qt.RightButton ? tile.rightClicked() : tile.clicked()
    }
}
