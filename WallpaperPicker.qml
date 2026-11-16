import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "services"
import "components"

// Wallpaper picker: a filmstrip that swells toward the middle, under a big
// preview that resolves out of chunky pixels. The shell recolors to the
// highlighted image as you go. ←/→ or scroll to browse, R for a random one,
// Enter or click keeps it, Esc puts everything back.
// Tab switches the source to wallhaven.cc: type a search, Enter, browse the
// results the same way; keeping one downloads it into <library>/wallhaven.
PanelWindow {
    id: wp
    signal close()

    screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) || Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "drift-wallpapers"
    color: "transparent"

    // one entry per image: { name, thumb, big, path (library) | url (wallhaven) }
    property string source: "library"
    property var found: []                       // wallhaven results
    property string status: ""                   // wallhaven: what's happening
    readonly property var items: source === "library"
        ? Wallpapers.files.map(f => ({ name: f.split("/").pop(), thumb: "file://" + f, big: "file://" + f, path: f }))
        : found
    readonly property var cur: items[strip.currentIndex] || null
    readonly property bool isCurrent: !!cur && cur.path === Theme.wallpaper

    function setSource(s) {
        source = s
        strip.ready = false
        strip.currentIndex = s === "library" ? Math.max(0, Wallpapers.files.indexOf(Theme.wallpaper)) : 0
        strip.ready = true
        if (s === "wallhaven") { query.grab(); if (found.length === 0 && status === "") search("") }
        else keys.forceActiveFocus()
    }
    function search(q) {
        status = "searching…"
        find.running = false
        // safe-for-work only; an empty search shows the current top list
        find.command = ["curl", "-sfL", "--max-time", "15", "-G", "https://wallhaven.cc/api/v1/search", "-d", "purity=100",
            "-d", "atleast=1920x1080", "-d", "sorting=" + (q === "" ? "toplist" : "relevance"), "--data-urlencode", "q=" + q]
        find.running = true
    }
    function parse(text) {
        return JSON.parse(text).data.map(d => ({ name: "wallhaven-" + d.id + " · " + d.resolution, thumb: d.thumbs.small, big: d.thumbs.large, url: d.path }))
    }
    Process {
        id: find
        stdout: StdioCollector {
            onStreamFinished: {
                try { wp.found = wp.parse(this.text); wp.status = wp.found.length ? "" : "nothing found" }
                catch (e) { wp.found = []; wp.status = "couldn't reach wallhaven" }
                strip.currentIndex = 0
                if (wp.found.length) keys.forceActiveFocus()
            }
        }
    }
    Process {   // fetch the full image, then use it like any other
        id: fetch
        property string target
        onExited: code => {
            if (code !== 0) { wp.status = "download failed"; return }
            wp.kept = true
            Wallpapers.rescan()
            Wallpapers.set(target)
            wp.close()
        }
    }
    Component.onCompleted: console.assert(parse('{"data":[{"id":"x1","resolution":"1920x1080","path":"https://w/full.jpg","thumbs":{"small":"s","large":"l"}}]}')[0].url === "https://w/full.jpg")
    readonly property real pw: Math.round(Math.min(960, width * 0.5))    // preview size, 16:9
    readonly property real ph: Math.round(pw * 9 / 16)
    property bool kept: false
    property real intro: 0
    NumberAnimation on intro { to: 1; duration: Theme.dur(320); easing.type: Easing.OutCubic }

    onCurChanged: { resolve.restart(); recolor.restart() }
    // colors can only be previewed from images already on disk
    Timer { id: recolor; interval: 260; onTriggered: Theme.previewWallpaper = wp.cur && wp.cur.path && !wp.isCurrent ? wp.cur.path : "" }

    function keep() {
        if (!cur || fetch.running) return
        if (cur.path) { kept = true; Wallpapers.set(cur.path); close(); return }
        status = "downloading…"
        fetch.target = Wallpapers.dir + "/wallhaven/" + cur.url.split("/").pop()
        fetch.command = ["sh", "-c", 'mkdir -p "$(dirname "$1")" && { [ -s "$1" ] || curl -sfL --max-time 90 -o "$1" "$2" || { rm -f "$1"; false; }; }', "sh", fetch.target, cur.url]
        fetch.running = true
    }
    Component.onDestruction: if (!kept) { Theme.previewWallpaper = ""; Theme.revert() }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.surface, 0.86)
        opacity: wp.intro
        MouseArea { anchors.fill: parent; onClicked: wp.close() }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        // keys the search field doesn't use (Tab, Esc, arrows at the end of the text) land here too
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Escape) wp.close()
            else if (e.key === Qt.Key_Tab || e.key === Qt.Key_Backtab) wp.setSource(wp.source === "library" ? "wallhaven" : "library")
            else if (e.key === Qt.Key_Slash && wp.source === "wallhaven") query.grab()
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) wp.keep()
            else if (e.key === Qt.Key_Right || e.key === Qt.Key_L) strip.incrementCurrentIndex()
            else if (e.key === Qt.Key_Left || e.key === Qt.Key_H) strip.decrementCurrentIndex()
            else if (e.key === Qt.Key_Home) strip.currentIndex = 0
            else if (e.key === Qt.Key_End) strip.currentIndex = strip.count - 1
            else if (e.key === Qt.Key_R && strip.count > 1) {
                var i
                do { i = Math.floor(Math.random() * strip.count) } while (i === strip.currentIndex)
                strip.currentIndex = i
            }
            else return
            e.accepted = true
        }

        Label {
            visible: wp.items.length === 0
            anchors.centerIn: parent
            text: wp.source === "library" ? "no images in " + Wallpapers.dir : wp.status
            color: Theme.dim
        }

        // ── where the images come from ──
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: main.top
            anchors.bottomMargin: 18
            opacity: wp.intro
            spacing: 10
            Segmented {
                options: [{ label: "library", value: "library" }, { label: "wallhaven", value: "wallhaven" }]
                value: wp.source
                onPicked: v => wp.setSource(v)
            }
            Field {
                id: query
                visible: wp.source === "wallhaven"
                width: 300
                placeholder: "search wallhaven, enter"
                onAccepted: t => wp.search(t.trim())
            }
            Label {
                visible: wp.source === "wallhaven" && wp.status !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: wp.status
                color: Theme.accent2
            }
        }

        Column {
            id: main
            // stays put when a source has nothing to show yet
            opacity: wp.items.length > 0 ? 1 : 0
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 20
            spacing: 22

            // ── the big preview ──
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: wp.pw; height: wp.ph
                opacity: wp.intro
                scale: 0.94 + 0.06 * wp.intro

                Image {
                    anchors.fill: parent
                    anchors.margins: 4
                    source: wp.cur ? wp.cur.big : ""
                    sourceSize: Qt.size(wp.pw, wp.ph)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    retainWhileLoading: true
                }
                // the same image at 48px across: fades out to "develop" the sharp one
                Image {
                    id: mosaic
                    anchors.fill: parent
                    anchors.margins: 4
                    source: wp.cur ? wp.cur.big : ""
                    sourceSize: Qt.size(48, 27)
                    fillMode: Image.PreserveAspectCrop
                    smooth: false
                    asynchronous: true
                    retainWhileLoading: true
                    SequentialAnimation {
                        id: resolve
                        PropertyAction { target: mosaic; property: "opacity"; value: 1 }
                        PauseAnimation { duration: Theme.dur(140) }
                        NumberAnimation { target: mosaic; property: "opacity"; to: 0; duration: Theme.dur(420); easing.type: Easing.InQuad }
                    }
                }
                PixelBox {
                    anchors.fill: parent
                    step: 4
                    fill: "transparent"
                    stroke: Theme.accent
                    title: wp.cur ? wp.cur.name : ""
                    badge: (strip.currentIndex + 1) + " / " + strip.count + (wp.isCurrent ? " · current" : "")
                }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wp.keep() }
            }

            // ── filmstrip ──
            ListView {
                id: strip
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(wp.width - 80, wp.pw * 1.7)
                height: 132
                opacity: wp.intro
                transform: Translate { y: (1 - wp.intro) * 40 }
                orientation: ListView.Horizontal
                model: wp.items
                clip: true
                // keep the picked one dead center; everything else slides past it
                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: (width - 190) / 2
                preferredHighlightEnd: (width + 190) / 2
                highlightMoveVelocity: -1
                highlightMoveDuration: ready ? Theme.dur(300) : 0
                property bool ready: false
                Component.onCompleted: { currentIndex = Math.max(0, Wallpapers.files.indexOf(Theme.wallpaper)); ready = true }

                delegate: Item {
                    id: thumb
                    required property var modelData
                    required property int index
                    readonly property bool cur: ListView.isCurrentItem
                    // 0 at the middle of the strip, 1 one slot away, and so on
                    readonly property real d: Math.abs(x + width / 2 - strip.contentX - strip.width / 2) / width
                    width: 190; height: strip.height
                    z: 10 - Math.round(d)

                    Item {
                        anchors.centerIn: parent
                        width: 176; height: 99
                        scale: Math.max(0.6, 1.18 - 0.24 * thumb.d)
                        opacity: Math.max(0.3, 1 - 0.22 * thumb.d)
                        Image {
                            anchors.fill: parent
                            anchors.margins: 3
                            source: thumb.modelData.thumb
                            sourceSize: Qt.size(352, 198)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.dur(200) } }
                        }
                        PixelBox {
                            anchors.fill: parent
                            step: 3
                            fill: "transparent"
                            stroke: thumb.cur ? Theme.accent : thumb.modelData.path === Theme.wallpaper ? Theme.accent2 : Theme.alpha(Theme.dim, 0.4)
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: thumb.cur ? wp.keep() : strip.currentIndex = thumb.index
                        }
                    }
                }

                // scroll steps one image at a time
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: w => (w.angleDelta.y + w.angleDelta.x) < 0 ? strip.incrementCurrentIndex() : strip.decrementCurrentIndex()
                }
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: wp.intro
                text: "←→ browse · r random · enter keep · tab " + (wp.source === "library" ? "wallhaven" : "library · / search") + " · esc cancel"
                color: Theme.dim
            }
        }
    }
}
