import QtQuick
import Quickshell
import Quickshell.Wayland
import "services"
import "components"
import "services/themes.js" as Themes

// Theme picker: a wall of little terminals, one per preset (plus "from
// wallpaper"). Moving over one repaints the whole shell in it; Enter or click
// keeps it, Esc puts the old colors back. A toggles theming kitty and GTK too.
PanelWindow {
    id: tp
    signal close()

    screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) || Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "drift-themes"
    color: "transparent"

    // key "" = colors from the wallpaper
    readonly property var entries: [{ key: "", name: "from wallpaper" }].concat(Themes.list)
    readonly property int cols: 4
    property int sel: Math.max(0, entries.findIndex(e => e.key === Theme.presetKey))
    readonly property var cur: entries[sel]
    property bool kept: false

    onSelChanged: preview.restart()
    Timer {   // let fast arrow/hover sweeps pass before repainting everything
        id: preview
        interval: 90
        onTriggered: {
            var p = tp.cur.key === "" ? Theme.generated : tp.cur
            if (p) Theme.show(p)
        }
    }
    function keep() {
        kept = true
        if (cur.key === "") {
            Config.opts.colorMode = "wallpaper"
        } else {
            Config.opts.themeName = cur.key
            Config.opts.colorMode = "theme"
        }
        close()
    }
    Component.onDestruction: if (!kept) Theme.revert()

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.surface, 0.82)
        opacity: 0
        NumberAnimation on opacity { to: 1; duration: Theme.dur(160) }
        MouseArea { anchors.fill: parent; onClicked: tp.close() }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            var n = tp.entries.length, c = tp.cols
            if (e.key === Qt.Key_Escape) tp.close()
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) tp.keep()
            else if (e.key === Qt.Key_Right || e.key === Qt.Key_L) tp.sel = (tp.sel + 1) % n
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_H) tp.sel = (tp.sel + n - 1) % n
            else if (e.key === Qt.Key_Down || e.key === Qt.Key_J) tp.sel = Math.min(n - 1, tp.sel + c)
            else if (e.key === Qt.Key_Up || e.key === Qt.Key_K) tp.sel = Math.max(0, tp.sel - c)
            else if (e.key === Qt.Key_A) Config.opts.themeApps = !Config.opts.themeApps
            else return
            e.accepted = true
        }

        Column {
            anchors.centerIn: parent
            spacing: 18

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "> " + tp.cur.name + "_"
                font.pixelSize: Theme.fsBig
                color: Theme.accent
            }

            Grid {
                id: grid
                columns: tp.cols
                spacing: 14
                Repeater {
                    model: tp.entries
                    Item {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool cur: tp.sel === index
                        readonly property bool active: modelData.key === Theme.presetKey
                        // the wallpaper tile wears whatever matugen last made
                        readonly property var t: modelData.key !== "" ? modelData : Theme.generated || Theme.palette || Themes.list[0]
                        width: 208; height: 136
                        z: cur ? 1 : 0

                        // staggered pop-in, then the picked one lifts
                        opacity: 0
                        property real pop: 0.85
                        scale: pop * (cur ? 1.07 : 1)
                        Behavior on scale { NumberAnimation { duration: Theme.dur(220); easing.type: Easing.OutBack; easing.overshoot: 2 } }
                        Component.onCompleted: popIn.start()
                        SequentialAnimation {
                            id: popIn
                            PauseAnimation { duration: Theme.dur(28 * tile.index) }
                            ParallelAnimation {
                                NumberAnimation { target: tile; property: "opacity"; to: 1; duration: Theme.dur(160) }
                                NumberAnimation { target: tile; property: "pop"; to: 1; duration: Theme.dur(40) }
                            }
                        }

                        PixelBox {
                            anchors.fill: parent
                            step: 4
                            fill: tile.t.bg
                            stroke: tile.cur ? tile.t.accent : tile.t.outline
                            title: tile.modelData.name
                            titleColor: tile.cur ? tile.t.accent : tile.t.dim
                            badge: tile.active ? "current" : ""
                        }
                        // wallpaper tile: the wallpaper itself, crushed to pixels
                        Image {
                            visible: tile.modelData.key === ""
                            x: 6; y: 12; width: parent.width - 12; height: 44
                            source: visible && Theme.wallpaper ? "file://" + Theme.wallpaper : ""
                            sourceSize: Qt.size(48, 12)
                            fillMode: Image.PreserveAspectCrop
                            smooth: false
                            asynchronous: true
                        }
                        // a few lines of "code" in the theme's terminal colors
                        Column {
                            x: 14; y: tile.modelData.key === "" ? 66 : 20
                            spacing: 6
                            Repeater {
                                model: tile.modelData.key === "" ? [[4, 2], [5, 3, 6]] : [[4, 2], [5, 3, 6], [1, 4], [2, 6, 3], [5, 1]]
                                Row {
                                    id: line
                                    required property var modelData
                                    required property int index
                                    spacing: 5
                                    Rectangle { width: 4; height: 6; color: tile.t.dim; opacity: 0.5 }
                                    Repeater {
                                        model: line.modelData
                                        Rectangle {
                                            required property int modelData
                                            required property int index
                                            width: 18 + (modelData * 7 + line.index * 11 + index * 5) % 34
                                            height: 6
                                            color: tile.t.ansi[modelData]
                                        }
                                    }
                                }
                            }
                        }
                        // chrome swatches
                        Row {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 12
                            x: 14
                            spacing: 3
                            Repeater {
                                model: ["accent", "accent2", "accent3", "fg", "dim", "raised", "surface"]
                                Rectangle { required property string modelData; width: 12; height: 12; color: tile.t[modelData] }
                            }
                        }
                        // cursor block on the picked tile
                        Rectangle {
                            visible: tile.cur
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 12
                            width: 7; height: 12
                            color: tile.t.accent
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: tp.sel = tile.index
                            onClicked: { tp.sel = tile.index; tp.keep() }
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14
                Label { anchors.verticalCenter: parent.verticalCenter; text: "←↑↓→ look · enter keep · esc cancel"; color: Theme.dim }
                Chip {
                    text: "a · theme kitty and gtk too"
                    icon: "palette"
                    on: Config.opts.themeApps
                    onClicked: Config.opts.themeApps = !Config.opts.themeApps
                }
            }
        }
    }
}
