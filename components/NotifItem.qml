import QtQuick
import Quickshell
import Quickshell.Widgets
import "../services"

// One notification in a pixel box. Click runs its default action.
Item {
    id: item
    required property var notif
    property int bodyLines: 2
    property bool framed: true
    signal activated()

    implicitHeight: row.implicitHeight + 20

    readonly property string iconSource: {
        var n = item.notif
        if (!n) return ""
        if (n.image) return n.image
        var ic = n.appIcon || ""
        if (ic.startsWith("/") || ic.startsWith("file:")) return ic
        return Theme.appIcon(ic || n.desktopEntry || n.appName)
    }

    PixelBox {
        visible: item.framed
        anchors.fill: parent
        fill: ma.containsMouse ? Theme.alpha(Theme.accent, 0.10) : Theme.alpha(Theme.fg, 0.03)
        stroke: ma.containsMouse ? Theme.accent : Theme.alpha(Theme.dim, 0.3)
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: { System.invoke(item.notif); item.activated() }
    }

    Row {
        id: row
        x: 10; y: 10
        width: parent.width - 20
        spacing: 10

        IconImage { width: 28; height: 28; source: item.iconSource; smooth: false }

        Column {
            width: parent.width - 28 - 10 - 24
            spacing: 3
            Label {
                width: parent.width
                text: (item.notif ? item.notif.appName : "").toUpperCase()
                color: Theme.accent2
            }
            Label {
                width: parent.width
                text: item.notif ? item.notif.summary : ""
                font.bold: true
            }
            Label {
                width: parent.width
                visible: text !== ""
                text: item.notif ? item.notif.body : ""
                wrapMode: Text.Wrap
                maximumLineCount: item.bodyLines
                color: Theme.dim
            }
        }

        RoundButton {
            implicitWidth: 20; implicitHeight: 20; iconSize: 11
            icon: "close"
            onClicked: if (item.notif) item.notif.dismiss()
        }
    }
}
