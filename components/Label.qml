import QtQuick
import "../services"

// Pixel text: Departure Mono on its native 11px grid, unsmoothed.
Text {
    color: Theme.fg
    font.family: Theme.font
    font.pixelSize: Theme.fs
    renderType: Text.NativeRendering
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
}
