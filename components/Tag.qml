import QtQuick
import "../services"

// Module label, btop style: lowercase in the module's hue.
Label {
    property color hue: Theme.accent
    color: hue
    font.bold: true
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
}
