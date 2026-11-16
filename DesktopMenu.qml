import QtQuick
import "services"
import "components"

// The menu that pops up where you right-click the bare desktop
// (WallpaperLayer.qml). Closes on a pick, a click elsewhere, when the pointer
// wanders off, or when a window takes focus.
PixelBox {
    id: menu
    property bool shown: false
    function openAt(mx, my) {
        x = Math.round(Math.max(8, Math.min(parent.width - width - 8, mx)))
        y = Math.round(Math.max(8, Math.min(parent.height - height - 8, my)))
        shown = true
    }
    function overlay(name) { return () => System.overlayRequested(name) }

    readonly property var items: [
        { icon: "search", label: "search the web", fn: overlay("search") },
        { icon: "rocket", label: "apps", fn: () => System.run(Config.opts.launcherCommand) },
        { icon: "keyboard", label: "terminal", fn: () => System.run(Config.opts.terminalCommand) },
        null,
        { icon: "image", label: "pick a wallpaper", fn: overlay("wallpapers") },
        { icon: "refresh", label: "random wallpaper", keep: true, fn: () => Wallpapers.random() },
        { icon: "palette", label: "pick a theme", fn: overlay("themes") },
        null,
        { icon: "crop", label: "screenshot", fn: overlay("capture") },
        { icon: "cog", label: "settings", fn: () => System.openSettings("") },
        { icon: "power", label: "session", fn: overlay("session") }
    ]

    width: 216
    height: col.height + 16
    step: 3
    fill: Theme.alpha(Theme.surface, 0.97)
    stroke: Theme.accent
    title: "drift"

    // unfolds from the corner under the pointer
    property real reveal: shown ? 1 : 0
    Behavior on reveal { NumberAnimation { duration: Theme.dur(menu.shown ? 200 : 120); easing.type: Easing.OutCubic } }
    visible: reveal > 0.01
    opacity: reveal
    scale: 0.88 + 0.12 * reveal
    transformOrigin: Item.TopLeft

    MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }   // clicks on the frame stay in the menu
    HoverHandler { id: hover; onHoveredChanged: hovered ? leave.stop() : leave.restart() }
    Timer { id: leave; interval: 900; onTriggered: menu.shown = false }
    onShownChanged: leave.stop()
    Connections {
        target: Niri
        function onFocusedWindowIdChanged() { menu.shown = false }
    }

    Column {
        id: col
        x: 6; y: 10
        width: parent.width - 12
        Repeater {
            model: menu.items
            Item {
                id: row
                required property var modelData
                required property int index
                width: col.width
                height: modelData ? 26 : 9
                // rows trail in one after another
                opacity: Math.max(0, Math.min(1, menu.reveal * 2 - index * 0.08))
                transform: Translate { x: (1 - row.opacity) * -10 }

                Rectangle { visible: !row.modelData; y: 4; width: parent.width; height: 1; color: Theme.alpha(Theme.dim, 0.3) }
                Rectangle { visible: ma.containsMouse; anchors.fill: parent; color: Theme.accent }
                Row {
                    visible: !!row.modelData
                    x: 8
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Icon { name: row.modelData ? row.modelData.icon : ""; size: 13; color: ma.containsMouse ? Theme.surface : Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: row.modelData ? row.modelData.label : ""; color: ma.containsMouse ? Theme.surface : Theme.fg; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea {
                    id: ma
                    anchors.fill: parent
                    enabled: !!row.modelData
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { if (!row.modelData.keep) menu.shown = false; row.modelData.fn() }
                }
            }
        }
    }
}
