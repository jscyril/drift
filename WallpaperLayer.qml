import QtQuick
import Quickshell
import Quickshell.Wayland
import "services"

// The desktop wallpaper (Theme.wallpaper), drawn on the background layer.
// Two stacked images crossfade on change instead of cutting abruptly.
PanelWindow {
    id: layer
    required property var modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "drift-wallpaper"
    color: Theme.surface

    readonly property string path: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
    property bool aIsFront: true   // which image is the one fading in
    onPathChanged: if (path !== "") (aIsFront ? imgB : imgA).source = path

    Image {
        id: imgA
        anchors.fill: parent
        sourceSize: Qt.size(parent.width, parent.height)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        opacity: layer.aIsFront ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        onStatusChanged: if (status === Image.Ready && !layer.aIsFront && source == layer.path) layer.aIsFront = true
    }
    Image {
        id: imgB
        anchors.fill: parent
        sourceSize: Qt.size(parent.width, parent.height)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        opacity: layer.aIsFront ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        onStatusChanged: if (status === Image.Ready && layer.aIsFront && source == layer.path) layer.aIsFront = false
    }

    // right-click the bare desktop (an empty workspace, or a gap between windows) for a menu
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: e => e.button === Qt.RightButton ? menu.openAt(e.x, e.y) : menu.shown = false
    }
    DesktopMenu { id: menu }
}
