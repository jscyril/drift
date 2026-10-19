import QtQuick
import "../services"

// Titled btop box that grows with its content; used by every settings page.
PixelBox {
    id: sec
    property color hue: Theme.accent
    default property alias content: col.data
    property alias spacing: col.spacing

    width: parent ? parent.width : 400
    height: col.height + 30
    fill: Theme.alpha(Theme.fg, 0.025)
    stroke: Theme.alpha(hue, 0.45)
    titleColor: hue

    Column {
        id: col
        x: 14; y: 16
        width: sec.width - 28
        spacing: 6
    }
}
