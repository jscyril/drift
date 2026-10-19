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
    readonly property string dir: Config.opts.wallpaperDir.replace(/^~/, Quickshell.env("HOME"))
    property var files: []

    Process {
        id: ls
        running: true
        command: ["find", "-L", pg.dir, "-maxdepth", "2", "-type", "f", "(", "-iname", "*.png", "-o", "-iname", "*.jpg",
                  "-o", "-iname", "*.jpeg", "-o", "-iname", "*.webp", ")"]
        stdout: StdioCollector { onStreamFinished: pg.files = this.text.split("\n").filter(l => l !== "").sort() }
    }
    onDirChanged: { ls.running = false; ls.running = true }

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
                    Chip { text: "random"; icon: "refresh"; onClicked: if (pg.files.length) Theme.setWallpaper(pg.files[Math.floor(Math.random() * pg.files.length)]) }
                    Chip { text: "previous"; icon: "left"; onClicked: pg.step(-1) }
                    Chip { text: "next"; icon: "right"; onClicked: pg.step(1) }
                }
            }
        }
    }
    function step(d) {
        if (!files.length) return
        var i = files.indexOf(Theme.wallpaper)
        Theme.setWallpaper(files[(i + d + files.length) % files.length])
    }

    Section {
        title: "library"
        badge: pg.files.length + " images"
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
                model: pg.files
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
                    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Theme.setWallpaper(thumb.modelData) }
                }
            }
        }
        Label { visible: pg.files.length === 0; text: "no images in " + pg.dir; color: Theme.dim }
    }
}
