import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"
import "../../components"

// Wallpaper grid from a folder. Setting goes through noctalia (it still
// draws the wallpaper); colors follow automatically.
Column {
    id: pg
    spacing: 18
    Section {
        title: "current"
        hue: Theme.hue("time")
        Row {
            spacing: 16
            Item {
                width: 240; height: 135
                Image {
                    anchors.fill: parent
                    anchors.margins: 3
                    source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
                    sourceSize: Qt.size(480, 270)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
                PixelBox { anchors.fill: parent; step: 3; fill: "transparent"; stroke: Theme.hue("time") }
            }
            Column {
                width: parent.parent.width - 256
                spacing: 8
                Label { width: parent.width; text: Theme.wallpaper.split("/").pop(); elide: Text.ElideMiddle; font.bold: true }
                Label { width: parent.width; text: Theme.wallpaper; elide: Text.ElideMiddle; color: Theme.dim }
                Row {
                    spacing: 6
                    Chip { text: "random"; icon: "refresh"; onClicked: Wallpapers.random() }
                    Chip { text: "previous"; icon: "left"; onClicked: Wallpapers.step(-1) }
                    Chip { text: "next"; icon: "right"; onClicked: Wallpapers.step(1) }
                }
            }
        }
    }
    Section {
        title: "rotation"
        badge: Config.opts.wallpaperMinutes > 0 ? "every " + Config.opts.wallpaperMinutes + " min" : "off"
        hue: Theme.hue("time")
        Setting {
            title: "change every"
            Segmented {
                options: [{ label: "off", value: 0 }, { label: "5m", value: 5 }, { label: "15m", value: 15 },
                          { label: "30m", value: 30 }, { label: "1h", value: 60 }]
                value: Config.opts.wallpaperMinutes
                onPicked: v => Config.opts.wallpaperMinutes = v
            }
        }
        Setting {
            visible: Config.opts.wallpaperMinutes > 0
            title: "order"
            Segmented {
                options: [{ label: "shuffle", value: true }, { label: "in order", value: false }]
                value: Config.opts.wallpaperShuffle
                onPicked: v => Config.opts.wallpaperShuffle = v
            }
        }
    }

    Section {
        title: "library"
        badge: Wallpapers.files.length + " images"
        Setting {
            title: "folder"
            Field { width: 280; text: Config.opts.wallpaperDir; onCommitted: t => Config.opts.wallpaperDir = t.trim() }
        }
        Flow {
            id: grid
            width: parent.width
            spacing: 10
            readonly property int cols: Math.max(2, Math.floor((width + 10) / 190))
            readonly property real cw: (width - (cols - 1) * 10) / cols
            Repeater {
                model: Wallpapers.files
                Item {
                    id: thumb
                    required property string modelData
                    required property int index
                    readonly property bool cur: modelData === Theme.wallpaper
                    width: grid.cw; height: Math.round(grid.cw * 9 / 16)
                    Image {
                        anchors.fill: parent
                        anchors.margins: 3
                        source: "file://" + thumb.modelData
                        sourceSize: Qt.size(320, 180)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.dur(200) } }
                    }
                    PixelBox {
                        anchors.fill: parent
                        step: 3
                        fill: "transparent"
                        stroke: thumb.cur ? Theme.hue("time") : ma.containsMouse ? Theme.accent : Theme.alpha(Theme.dim, 0.3)
                        title: thumb.cur ? "current" : ""
                        titleColor: Theme.hue("time")
                    }
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Wallpapers.set(thumb.modelData) }
                }
            }
        }
        Label { visible: Wallpapers.files.length === 0; text: "no images in " + Wallpapers.dir; color: Theme.dim }
    }
}
