import QtQuick
import "../services"

Text {
    property string name
    property real size: 16
    text: Theme.glyph(name)
    color: Theme.fg
    font.family: Theme.iconFont
    font.pixelSize: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    Behavior on color { ColorAnimation { duration: 200 } }
}
