import QtQuick
import Quickshell
import Quickshell.Wayland
import "services"

// Wallpaper for niri's overview backdrop: dimmed and crushed to pixels so the
// (crisp) workspaces stand out. niri needs a layer-rule placing the
// "drift-backdrop" namespace within the backdrop; it's otherwise never seen.
PanelWindow {
    id: bd
    required property var modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "drift-backdrop"
    color: Theme.surface
    mask: Region {}

    Image {
        anchors.fill: parent
        source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
        sourceSize: Qt.size(192, 108)
        fillMode: Image.PreserveAspectCrop
        smooth: false
        asynchronous: true
    }
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.surface, 0.7) }
}
