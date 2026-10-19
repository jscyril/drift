import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "services"
import "components"

// Clipboard history (cliphist). Type to filter, ↑/↓ to pick, Enter or click
// copies it back, Esc closes. Images get a preview on the right.
PanelWindow {
    id: cm
    signal close()

    screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) || Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "drift-clipboard"
    color: "transparent"

    property var entries: []          // [{ id, text, image }]
    property string query: ""
    readonly property var shown: {
        var q = query.toLowerCase()
        return q === "" ? entries : entries.filter(e => e.text.toLowerCase().indexOf(q) >= 0)
    }
    property int sel: 0
    readonly property var cur: shown[Math.min(sel, shown.length - 1)] || null
    readonly property string tmp: Quickshell.env("XDG_RUNTIME_DIR") + "/drift-clip"

    Process {
        id: list
        running: true
        command: ["sh", "-c", "cliphist list | head -n 300"]
        stdout: StdioCollector {
            onStreamFinished: {
                cm.entries = this.text.split("\n").filter(l => l !== "").map(l => {
                    var i = l.indexOf("\t"), t = l.slice(i + 1)
                    var m = t.match(/^\[\[ binary data (.+) (png|jpeg|jpg|webp|gif|bmp) (\d+x\d+) \]\]$/)
                    return { id: l.slice(0, i), text: m ? "image " + m[3] + " · " + m[1] : t, image: !!m }
                })
            }
        }
    }

    function copy(e) {
        if (!e) return
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", e.id])
        close()
    }
    function remove(e) {
        Quickshell.execDetached(["sh", "-c", 'cliphist list | grep -m1 "^$1	" | cliphist delete', "sh", e.id])
        entries = entries.filter(x => x.id !== e.id)
    }
    Component.onDestruction: Quickshell.execDetached(["sh", "-c", 'rm -f "$1"-*', "sh", tmp])

    // preview for the selected image
    property string preview: ""
    onCurChanged: {
        preview = ""
        if (cur && cur.image) { decode.target = tmp + "-" + cur.id + ".png"; decode.running = false; decode.command = ["sh", "-c", 'cliphist decode "$1" > "$2"', "sh", cur.id, decode.target]; decode.running = true }
    }
    Process {
        id: decode
        property string target
        onExited: code => { if (code === 0) cm.preview = "file://" + target }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.surface, 0.75)
        MouseArea { anchors.fill: parent; onClicked: cm.close() }
    }

    PixelBox {
        id: panel
        anchors.centerIn: parent
        width: 760; height: 520
        step: 4
        fill: Theme.alpha(Theme.surface, 0.98)
        stroke: Theme.accent
        title: "clipboard"
        badge: cm.shown.length + " / " + cm.entries.length
        MouseArea { anchors.fill: parent }   // keep clicks inside from closing

        Item {
            anchors.fill: parent
            anchors.margins: 16
            Keys.onPressed: e => {
                if (e.key === Qt.Key_Escape) cm.close()
                else if (e.key === Qt.Key_Down || (e.key === Qt.Key_J && e.modifiers & Qt.ControlModifier)) cm.sel = Math.min(cm.shown.length - 1, cm.sel + 1)
                else if (e.key === Qt.Key_Up || (e.key === Qt.Key_K && e.modifiers & Qt.ControlModifier)) cm.sel = Math.max(0, cm.sel - 1)
                else return
                e.accepted = true
            }

            Field {
                id: search
                width: parent.width
                placeholder: "/ search history   ↑↓ pick · enter copy · esc close"
                onEdited: t => { cm.query = t; cm.sel = 0 }
                onCommitted: if (cm.visible) cm.copy(cm.cur)
                Component.onCompleted: grab()
            }

            ListView {
                id: lv
                y: search.height + 12
                width: cm.cur && cm.cur.image ? parent.width - 260 : parent.width
                height: parent.height - y
                clip: true
                model: cm.shown
                currentIndex: cm.sel
                highlightMoveDuration: 0
                boundsBehavior: Flickable.StopAtBounds
                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool cur: index === cm.sel
                    width: lv.width
                    height: 26
                    Rectangle {
                        anchors.fill: parent
                        color: row.cur ? Theme.accent : rma.containsMouse ? Theme.alpha(Theme.fg, 0.06) : "transparent"
                    }
                    Row {
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Icon { name: row.modelData.image ? "image" : "pencil"; size: 12; color: row.cur ? Theme.surface : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                        Label {
                            width: row.width - 70
                            text: row.modelData.text.replace(/\s+/g, " ")
                            color: row.cur ? Theme.surface : row.modelData.image ? Theme.accent2 : Theme.fg
                        }
                    }
                    MouseArea {
                        id: rma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: cm.sel = row.index
                        onClicked: cm.copy(row.modelData)
                    }
                    RoundButton {
                        visible: row.cur || rma.containsMouse
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: 20; implicitHeight: 20; iconSize: 11
                        icon: "trash"
                        hue: Theme.ramp("temp", 1)
                        onClicked: cm.remove(row.modelData)
                    }
                }
                Label { visible: cm.shown.length === 0; text: list.running ? "loading…" : "nothing here"; color: Theme.dim }
            }

            // image preview
            Item {
                visible: !!cm.cur && cm.cur.image
                x: parent.width - 244
                y: lv.y
                width: 244; height: 244
                PixelBox { anchors.fill: parent; step: 3; fill: Theme.alpha(Theme.fg, 0.03); stroke: Theme.alpha(Theme.accent2, 0.6); title: "preview"; titleColor: Theme.accent2 }
                Image {
                    anchors.fill: parent
                    anchors.margins: 10
                    source: cm.preview
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                }
            }
        }
    }
}
