import QtQuick
import Quickshell
import Quickshell.Wayland
import "services"
import "components"

// Keybind cheatsheet (Mod+F1): every niri + shell bind, read live from
// ~/.config/niri/config.kdl (see services/Keybinds.qml). Type to filter, Esc closes.
PanelWindow {
    id: menu
    signal close()

    screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) || Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "drift-keybinds"
    color: "transparent"

    property string query: ""
    readonly property var shown: {
        var q = query.toLowerCase()
        if (q === "") return Keybinds.groups
        return Keybinds.groups
            .map(g => ({ name: g.name, binds: g.binds.filter(b => b.combo.toLowerCase().indexOf(q) >= 0 || b.title.toLowerCase().indexOf(q) >= 0) }))
            .filter(g => g.binds.length > 0)
    }
    readonly property int total: shown.reduce((n, g) => n + g.binds.length, 0)

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.surface, 0.75)
        MouseArea { anchors.fill: parent; onClicked: menu.close() }
    }

    PixelBox {
        id: panel
        anchors.centerIn: parent
        width: Math.min(1360, menu.width - 80)
        height: Math.min(720, menu.height - 80)
        step: 4
        fill: Theme.alpha(Theme.surface, 0.98)
        stroke: Theme.accent
        title: "keybinds"
        badge: menu.total + " binds"
        MouseArea { anchors.fill: parent }

        Item {
            anchors.fill: parent
            anchors.margins: 16
            Keys.onPressed: e => { if (e.key === Qt.Key_Escape) { menu.close(); e.accepted = true } }

            Field {
                id: search
                width: parent.width
                placeholder: "/ filter by key or action · esc close"
                onEdited: t => menu.query = t
                Component.onCompleted: grab()
            }

            Flickable {
                id: flick
                y: search.height + 12
                width: parent.width
                height: parent.height - y
                clip: true
                contentWidth: width
                contentHeight: flow.height
                boundsBehavior: Flickable.StopAtBounds

                Flow {
                    id: flow
                    width: flick.width
                    spacing: 14

                    Repeater {
                        model: menu.shown
                        Column {
                            id: col
                            required property var modelData
                            width: 320
                            spacing: 4

                            Label { text: col.modelData.name; color: Theme.accent; font.bold: true }
                            Repeater {
                                model: col.modelData.binds
                                Row {
                                    required property var modelData
                                    spacing: 8
                                    Label { width: 160; text: modelData.combo; color: Theme.accent2; elide: Text.ElideRight }
                                    Label { width: 152; text: modelData.title; color: Theme.dim; elide: Text.ElideRight }
                                }
                            }
                        }
                    }
                }
            }

            Label { visible: menu.total === 0; anchors.centerIn: flick; text: "no matches"; color: Theme.dim }
        }
    }
}
