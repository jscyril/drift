import QtQuick
import Quickshell
import "../services"
import "../components"

// drift settings: a real window (tiled by niri like any app). Sidebar of
// pages on the left, the page on the right; pages live in ./pages and load
// on demand.
FloatingWindow {
    id: win
    property string page: "look"

    title: "drift settings"
    implicitWidth: 1080
    implicitHeight: 720
    minimumSize: Qt.size(820, 520)
    color: Theme.surface

    readonly property var groups: [
        { name: "personal", pages: [
            { key: "look", file: "Look", label: "appearance", icon: "palette", hue: "gh", words: "color accent theme scheme matugen transparency crt scanline animation" },
            { key: "wallpaper", file: "Wallpaper", label: "wallpaper", icon: "image", hue: "time", words: "background image" },
            { key: "bar", file: "BarPage", label: "bar", icon: "dashboard", hue: "cpu", words: "modules height gap workspaces launcher arch vicinae" },
            { key: "clock", file: "Clock", label: "clock & weather", icon: "clock", hue: "temp", words: "time date 24 seconds weather location units celsius" },
            { key: "notifications", file: "Notifications", label: "notifications", icon: "bell", hue: "up", words: "popup dnd disturb history swaync" }
        ] },
        { name: "hardware", pages: [
            { key: "network", file: "Network", label: "network", icon: "wifi-4", hue: "down", words: "wifi wireless ethernet internet password ssid" },
            { key: "bluetooth", file: "BluetoothPage", label: "bluetooth", icon: "bluetooth", hue: "mem", words: "pair device headphones" },
            { key: "sound", file: "Sound", label: "sound", icon: "speaker", hue: "gpu", words: "audio volume output input microphone speaker apps" },
            { key: "displays", file: "Displays", label: "displays", icon: "monitors", hue: "cpu", words: "monitor screen resolution refresh scale rotate brightness" },
            { key: "power", file: "Power", label: "power", icon: "bolt", hue: "temp", words: "battery profile performance saver caffeine suspend shutdown" }
        ] },
        { name: "system", pages: [
            { key: "data", file: "Data", label: "data", icon: "database", hue: "gh", words: "github screen time idle" },
            { key: "about", file: "About", label: "about", icon: "info", hue: "mem", words: "system version reload reset" }
        ] }
    ]
    readonly property var allPages: groups.reduce((a, g) => a.concat(g.pages), [])
    readonly property var current: allPages.find(p => p.key === page) || allPages[0]

    function matches(p) {
        var q = search.query.toLowerCase().trim()
        return q === "" || (p.label + " " + p.words).indexOf(q) >= 0
    }

    // faint scanlines over everything, drawn once
    Canvas {
        anchors.fill: parent
        z: 10
        visible: Config.opts.scanlines
        enabled: false
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = "rgba(0,0,0,0.07)"
            for (var y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1)
        }
    }

    // ── sidebar ──
    Rectangle {
        id: side
        width: 232
        height: parent.height
        color: Theme.bg

        Column {
            x: 14; y: 16
            width: side.width - 28
            spacing: 14

            Row {
                spacing: 10
                Icon { name: "arch"; size: 30; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Label { text: "drift"; font.pixelSize: Theme.fsBig; color: Theme.fg }
                    Label { text: "settings"; color: Theme.accent2 }
                }
            }

            Field {
                id: search
                property string query: ""
                width: parent.width
                placeholder: "/ search"
                onEdited: t => query = t
            }

            Repeater {
                model: win.groups
                Column {
                    id: grp
                    required property var modelData
                    readonly property var shown: modelData.pages.filter(p => win.matches(p))
                    visible: shown.length > 0
                    width: parent.width
                    spacing: 2

                    Label { text: "── " + grp.modelData.name; color: Theme.alpha(Theme.dim, 0.7); bottomPadding: 4 }
                    Repeater {
                        model: grp.shown
                        Item {
                            id: nav
                            required property var modelData
                            readonly property bool sel: win.page === nav.modelData.key
                            width: parent.width
                            height: 30

                            Rectangle {
                                anchors.fill: parent
                                color: nav.sel ? Theme.hue(nav.modelData.hue) : ma.containsMouse ? Theme.alpha(Theme.fg, 0.06) : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
                            }
                            // hover tick
                            Rectangle {
                                width: 3; height: parent.height
                                color: Theme.hue(nav.modelData.hue)
                                visible: ma.containsMouse && !nav.sel
                            }
                            Row {
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                Icon { name: nav.modelData.icon; size: 15; color: nav.sel ? Theme.surface : Theme.hue(nav.modelData.hue); anchors.verticalCenter: parent.verticalCenter }
                                Label { text: nav.modelData.label; font.bold: nav.sel; color: nav.sel ? Theme.surface : Theme.fg; anchors.verticalCenter: parent.verticalCenter }
                            }
                            Label {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                visible: nav.sel
                                text: "<"
                                color: Theme.surface
                                font.bold: true
                            }
                            MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.page = nav.modelData.key }
                        }
                    }
                }
            }
        }

        // footer: who's driving
        Label {
            x: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            text: Quickshell.env("USER") + " · niri"
            color: Theme.alpha(Theme.dim, 0.6)
        }
        // dotted divider
        Column {
            anchors.right: parent.right
            spacing: 2
            Repeater {
                model: Math.floor(side.height / 4)
                Rectangle { width: 1; height: 2; color: Theme.alpha(Theme.accent, 0.35) }
            }
        }
    }

    // ── page ──
    Item {
        id: main
        x: side.width + 28
        y: 18
        width: win.width - x - 20
        height: win.height - y

        // header
        Row {
            id: header
            spacing: 14
            Item {
                width: 44; height: 44
                PixelBox { anchors.fill: parent; step: 3; fill: Theme.alpha(Theme.hue(win.current.hue), 0.18); stroke: Theme.hue(win.current.hue) }
                Icon { anchors.centerIn: parent; name: win.current.icon; size: 24; color: Theme.hue(win.current.hue) }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Label { text: win.current.label; font.pixelSize: Theme.fsBig; color: Theme.fg }
                Label { text: "drift://settings/" + win.current.key; color: Theme.alpha(Theme.dim, 0.8) }
            }
        }
        // gradient rule under the header, in the page's ramp
        Row {
            id: rule
            y: header.height + 12
            spacing: 1
            Repeater {
                model: Math.floor(main.width / 5)
                Rectangle {
                    required property int index
                    width: 4; height: 2
                    color: Theme.ramp(win.current.hue, index / Math.max(1, Math.floor(main.width / 5) - 1))
                }
            }
        }

        Flickable {
            id: flick
            y: rule.y + 18
            width: main.width
            height: main.height - y
            contentHeight: loader.height + 38
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Loader {
                id: loader
                y: 8
                width: flick.width - 14
                source: "pages/" + win.current.file + ".qml"
                onLoaded: { flick.contentY = 0; enter.restart() }
            }
            // pages "type in": a short stepped slide
            SequentialAnimation {
                id: enter
                PropertyAction { target: loader; property: "opacity"; value: 0 }
                PropertyAction { target: loader; property: "x"; value: 14 }
                PauseAnimation { duration: Theme.dur(50) }
                PropertyAction { target: loader; property: "opacity"; value: 0.5 }
                PropertyAction { target: loader; property: "x"; value: 7 }
                PauseAnimation { duration: Theme.dur(50) }
                PropertyAction { target: loader; property: "opacity"; value: 1 }
                PropertyAction { target: loader; property: "x"; value: 0 }
            }
        }

        // pixel scrollbar
        Rectangle {
            visible: flick.contentHeight > flick.height
            x: main.width - 4
            y: flick.y + flick.visibleArea.yPosition * flick.height
            width: 4
            height: Math.max(20, flick.visibleArea.heightRatio * flick.height)
            color: Theme.alpha(Theme.hue(win.current.hue), 0.6)
        }
    }
}
