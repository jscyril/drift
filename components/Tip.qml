import QtQuick
import Quickshell
import "../services"

// Hover pop-up under a bar item: a small pixel box in its own popup window.
// Set `target` and drive `show`; it appears after a short delay.
PopupWindow {
    id: tip
    property Item target
    property bool show: false
    property string title: ""
    property color hue: Theme.accent
    default property alias content: col.data

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 10
    implicitWidth: col.width + 28
    implicitHeight: col.height + 30
    color: "transparent"
    visible: wanted
    property bool wanted: false
    onShowChanged: show ? delay.restart() : (delay.stop(), wanted = false)
    Timer { id: delay; interval: 280; onTriggered: tip.wanted = true }

    PixelBox {
        anchors.fill: parent
        anchors.topMargin: 6           // room for the title in the border
        step: 2
        fill: Theme.alpha(Theme.surface, 0.97)
        stroke: tip.hue
        title: tip.title
        titleColor: tip.hue
        Column {
            id: col
            x: 14; y: 14
            spacing: 4
        }
    }
}
