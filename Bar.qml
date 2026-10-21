import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick
import "services"
import "components"
import "cards"

// One bar per monitor: a full-width pixel box. Cards open right under the
// module that was clicked, revealed in blocky steps.
Scope {
    id: bar
    required property var modelData            // ShellScreen
    readonly property string output: modelData.name
    readonly property int h: Config.opts.barHeight
    readonly property int m: Config.opts.barMargin
    readonly property bool docked: m === 0
    readonly property int cornerR: 18              // multiple of 3 (the pixel step)

    property string card: ""                   // "", quick, media, today, notif, system, screen, github
    property string shownCard: ""              // lags `card` so content stays while closing
    property real anchorX: 0
    property var peek: null
    readonly property bool modal: card !== "" && card !== "notif"

    readonly property var titles: ({
        quick: "control", media: "now playing", today: "today",
        notif: "notification", system: "system", screen: "screen time", github: "github", updates: "updates"
    })

    function open(name, fromItem) {
        if (card === name) { close(); return }
        anchorX = fromItem ? fromItem.mapToItem(null, fromItem.width / 2, 0).x : win.width / 2
        shownCard = name
        card = name
    }
    function close() {
        card = ""
        hideContent.restart()
    }
    Timer { id: hideContent; interval: Theme.dur(260); onTriggered: if (bar.card === "") bar.shownCard = "" }

    Connections {
        target: System
        function onRequestCard(name) {
            if (Niri.focusedOutput === "" || Niri.focusedOutput === bar.output) bar.open(name, null)
        }
        function onNotified(n) {
            if (Niri.focusedOutput !== "" && Niri.focusedOutput !== bar.output) return
            fx.sweep()
            if (!Config.opts.notifPopups || bar.modal) return
            bar.peek = n
            bar.anchorX = win.width / 2
            bar.shownCard = "notif"
            bar.card = "notif"
            peekTimer.restart()
        }
    }
    Timer {
        id: peekTimer
        interval: Config.opts.popupSeconds * 1000
        onTriggered: if (bar.card === "notif" && !dropHover.hovered) bar.close()
    }

    // sample processes only while the system card is open
    Binding { target: Stats; property: "wantProcs"; value: true; when: bar.card === "system" }

    // reserves the strip the bar sits in
    PanelWindow {
        screen: bar.modelData
        anchors { top: true; left: true; right: true }
        implicitHeight: bar.m + bar.h
        color: "transparent"
        mask: Region {}
        WlrLayershell.namespace: "drift-spacer"
    }

    PanelWindow {
        id: win
        screen: bar.modelData
        anchors { top: true; left: true; right: true; bottom: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "drift"
        WlrLayershell.keyboardFocus: bar.modal ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        mask: Region {
            item: bar.modal ? catcher : barBox
            Region { item: bar.card === "notif" ? drop : null }
        }

        MouseArea {
            id: catcher
            anchors.fill: parent
            onClicked: bar.close()
        }
        Item {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: bar.close()
        }

        // docked (edge gap 0): stepped concave corners under each end of the bar,
        // so the windows below look rounded where they meet it
        Repeater {
            model: bar.docked ? 2 : 0
            Item {
                id: corner
                required property int index
                x: index === 0 ? 0 : win.width - width
                y: bar.h
                width: bar.cornerR; height: bar.cornerR
                Repeater {
                    model: bar.cornerR / 3
                    Rectangle {
                        required property int index
                        readonly property real dy: bar.cornerR - index * 3 - 1.5
                        y: index * 3; height: 3
                        width: 3 * Math.round((bar.cornerR - Math.sqrt(bar.cornerR * bar.cornerR - dy * dy)) / 3)
                        x: corner.index === 0 ? 0 : bar.cornerR - width
                        color: barBox.fill
                    }
                }
            }
        }

        // ══ the bar ══
        PixelBox {
            id: barBox
            x: bar.m
            y: bar.m
            width: parent.width - 2 * bar.m
            height: bar.h
            step: bar.docked ? 0 : 3
            fill: Theme.alpha(Theme.surface, Config.opts.barOpacity)
            stroke: bar.docked ? "transparent" : Theme.alpha(Theme.accent, 0.5)

            Fx { id: fx; anchors.margins: 1 }

            // ── left: launcher, workspaces, system ──
            Row {
                x: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Module {
                    id: archMod
                    anchors.verticalCenter: parent.verticalCenter
                    padding: 6
                    active: bar.card === "quick"
                    onClicked: { spin.restart(); System.run(Config.opts.launcherCommand) }
                    onRightClicked: bar.open("quick", archMod)
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "arch"
                        size: 16
                        color: archMod.hovered ? Theme.accent2 : Theme.accent
                        RotationAnimation on rotation { id: spin; running: false; from: 0; to: 360; duration: Theme.dur(600); easing.type: Easing.OutBack }
                    }
                }

                Workspaces {
                    anchors.verticalCenter: parent.verticalCenter
                    output: bar.output
                }

                Sep {}

                Module {
                    id: cpuMod
                    visible: Config.opts.showCpu
                    anchors.verticalCenter: parent.verticalCenter
                    hue: Theme.hue("cpu")
                    active: bar.card === "system"
                    onClicked: bar.open("system", cpuMod)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Tag { text: "cpu"; hue: cpuMod.hue }
                        Graph { width: 44; height: 16; values: Stats.cpuHistory; ramp: "cpu"; anchors.verticalCenter: parent.verticalCenter }
                        Num { text: Math.round(Stats.cpu * 100) + "%"; width: 28; color: Theme.ramp("cpu", Stats.cpu) }
                    }
                }

                Module {
                    id: memMod
                    visible: Config.opts.showMem
                    anchors.verticalCenter: parent.verticalCenter
                    hue: Theme.hue("mem")
                    active: bar.card === "system"
                    onClicked: bar.open("system", memMod)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Tag { text: "mem"; hue: memMod.hue }
                        Meter { value: Stats.mem; ramp: "mem"; segments: 8; segH: 12; anchors.verticalCenter: parent.verticalCenter }
                        Num { text: Theme.bytes(Stats.memUsed); color: Theme.ramp("mem", Stats.mem) }
                    }
                }

                Module {
                    id: tempMod
                    visible: Config.opts.showTemp && Stats.tempC > 0
                    anchors.verticalCenter: parent.verticalCenter
                    hue: Theme.ramp("temp", Stats.tempC / 100)
                    active: bar.card === "system"
                    onClicked: bar.open("system", tempMod)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        Icon { name: "thermometer"; size: 14; color: tempMod.hue; anchors.verticalCenter: parent.verticalCenter }
                        Num { text: Math.round(Stats.tempC) + "°"; color: tempMod.hue }
                    }
                }

                Module {
                    id: gpuMod
                    visible: Config.opts.showGpu
                    anchors.verticalCenter: parent.verticalCenter
                    hue: Theme.hue("gpu")
                    active: bar.card === "system"
                    onClicked: bar.open("system", gpuMod)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Tag { text: "gpu"; hue: gpuMod.hue }
                        Meter { value: Stats.gpu; ramp: "gpu"; segments: 5; segH: 12; anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                Module {
                    id: netMod
                    visible: Config.opts.showNet
                    anchors.verticalCenter: parent.verticalCenter
                    hue: Theme.hue("down")
                    active: bar.card === "system"
                    onClicked: bar.open("system", netMod)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Graph { width: 30; height: 8; values: Stats.rxHistory; max: Stats.netPeak; ramp: "down" }
                            Graph { width: 30; height: 8; values: Stats.txHistory; max: Stats.netPeak; ramp: "up"; mirror: true }
                        }
                        Num { text: "↓" + Theme.bytes(Stats.rxRate); width: 46; color: Theme.hue("down") }
                        Num { text: "↑" + Theme.bytes(Stats.txRate); width: 46; color: Theme.hue("up") }
                    }
                }
            }

            // ── center: clock, date, weather ──
            Row {
                anchors.centerIn: parent
                spacing: 2

                Module {
                    id: clockMod
                    anchors.verticalCenter: parent.verticalCenter
                    active: bar.card === "today"
                    onClicked: bar.open("today", clockMod)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Clock { anchors.verticalCenter: parent.verticalCenter; pixelSize: Theme.fsBig }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Qt.formatDate(dateClock.date, "ddd dd MMM").toUpperCase()
                            color: Theme.dim
                            SystemClock { id: dateClock; precision: SystemClock.Minutes }
                        }
                    }
                }
                Module {
                    id: weatherMod
                    visible: Config.opts.weather && Weather.ready
                    anchors.verticalCenter: parent.verticalCenter
                    hue: Theme.accent2
                    active: bar.card === "today"
                    onClicked: bar.open("today", clockMod)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        Icon { name: Weather.icon; size: 15; color: Theme.accent2; anchors.verticalCenter: parent.verticalCenter }
                        Num { text: Weather.temp(Weather.tempC) }
                    }
                }
            }

            // ── right: screen time, github, media, notifications, status, settings ──
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                // privacy: who's using the mic, camera or screen
                Module {
                    id: privMod
                    visible: Privacy.mic || Privacy.camera || Privacy.screen
                    anchors.verticalCenter: parent.verticalCenter
                    hue: Theme.ramp("temp", 1)
                    onClicked: System.openSettings(Privacy.mic ? "sound" : "displays")
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Icon { visible: Privacy.mic; name: "mic"; size: 14; color: Theme.hue("temp"); anchors.verticalCenter: parent.verticalCenter }
                        Icon { visible: Privacy.camera; name: "webcam"; size: 14; color: Theme.hue("mem"); anchors.verticalCenter: parent.verticalCenter }
                        Icon { visible: Privacy.screen; name: "screen-share"; size: 14; color: Theme.ramp("temp", 1); anchors.verticalCenter: parent.verticalCenter }
                        Label {
                            visible: Privacy.mic
                            width: Math.min(implicitWidth, 110)
                            text: Privacy.micApps.join(", ").toLowerCase()
                            color: Theme.hue("temp")
                        }
                    }
                }

                // recording: red dot + timer, click to stop
                Module {
                    id: recMod
                    visible: Capture.recording
                    anchors.verticalCenter: parent.verticalCenter
                    hue: Theme.ramp("temp", 1)
                    onClicked: Capture.stop()
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Rectangle {
                            width: 8; height: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.ramp("temp", 1)
                            opacity: Capture.recSecs % 2 ? 0.35 : 1   // blinks with the 1s timer, no extra animation
                        }
                        Num { text: Theme.clockSecs(Capture.recSecs); color: Theme.ramp("temp", 1) }
                    }
                }

                Module {
                    id: screenMod
                    visible: Config.opts.showScreenTime && ScreenTime.loaded
                    anchors.verticalCenter: parent.verticalCenter
                    hue: Theme.hue("time")
                    active: bar.card === "screen"
                    onClicked: bar.open("screen", screenMod)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Icon { name: "timer"; size: 14; color: screenMod.hue; anchors.verticalCenter: parent.verticalCenter }
                        Num { text: Theme.duration(ScreenTime.todayTotal); color: screenMod.hue }
                        Graph {
                            width: 48; height: 14
                            anchors.verticalCenter: parent.verticalCenter
                            values: ScreenTime.today.hourly.slice(0, new Date().getHours() + 1)
                            max: 3600
                            ramp: "time"
                            cell: 2
                        }
                    }
                }

                Module {
                    id: ghMod
                    visible: Config.opts.showGithub && GitHub.ready
                    anchors.verticalCenter: parent.verticalCenter
                    hue: Theme.ramps.gh[3]
                    active: bar.card === "github"
                    onClicked: bar.open("github", ghMod)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Icon { name: "github"; size: 14; color: Theme.fg; anchors.verticalCenter: parent.verticalCenter }
                        Heatmap { weeks: 18; cell: 2; gap: 1; anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                Sep {}

                Module {
                    id: mediaMod
                    readonly property var p: System.player
                    visible: Config.opts.showMedia && p !== null && p.trackTitle !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    hue: Theme.hue("time")
                    active: bar.card === "media"
                    onClicked: bar.open("media", mediaMod)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Equalizer { anchors.verticalCenter: parent.verticalCenter; playing: mediaMod.p && mediaMod.p.isPlaying }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, 170)
                            text: mediaMod.p ? mediaMod.p.trackTitle : ""
                            color: Theme.dim
                        }
                    }
                }

                Module {
                    id: bellMod
                    visible: System.notifications.length > 0 || System.dnd
                    anchors.verticalCenter: parent.verticalCenter
                    hue: Theme.accent2
                    active: bar.card === "quick"
                    onClicked: bar.open("quick", bellMod)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Icon { name: System.dnd ? "bell-off" : "bell"; size: 14; color: System.dnd ? Theme.dim : Theme.accent2; anchors.verticalCenter: parent.verticalCenter }
                        Num { visible: System.notifications.length > 0; text: System.notifications.length; color: Theme.accent2 }
                    }
                }

                Module {
                    id: updMod
                    visible: Updates.count > 0
                    anchors.verticalCenter: parent.verticalCenter
                    hue: Theme.hue("gh")
                    active: bar.card === "updates"
                    onClicked: bar.open("updates", updMod)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Icon { name: "package-up"; size: 14; color: updMod.hue; anchors.verticalCenter: parent.verticalCenter }
                        Num { text: Updates.count; color: updMod.hue }
                    }
                }

                // system tray: left = activate, right = menu, middle = secondary, wheel = scroll
                Row {
                    id: tray
                    visible: SystemTray.items.values.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 4; rightPadding: 4
                    spacing: 6
                    Repeater {
                        model: SystemTray.items
                        MouseArea {
                            id: ti
                            required property var modelData
                            width: 16; height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            cursorShape: Qt.PointingHandCursor
                            function menu() {
                                var p = ti.mapToItem(null, 0, ti.height)
                                ti.modelData.display(win, p.x, p.y + 6)
                            }
                            onClicked: e => {
                                if (e.button === Qt.RightButton || (e.button === Qt.LeftButton && ti.modelData.onlyMenu)) { if (ti.modelData.hasMenu) menu() }
                                else if (e.button === Qt.MiddleButton) ti.modelData.secondaryActivate()
                                else ti.modelData.activate()
                            }
                            onWheel: e => ti.modelData.scroll(e.angleDelta.y / 120, false)
                            IconImage {
                                anchors.fill: parent
                                source: ti.modelData.icon
                                opacity: ti.containsMouse ? 1 : 0.85
                            }
                            Rectangle {   // pixel underline on hover
                                visible: ti.containsMouse
                                anchors.top: parent.bottom
                                anchors.topMargin: 2
                                width: parent.width; height: 2
                                color: Theme.accent
                            }
                        }
                    }
                }

                Module {
                    id: statusMod
                    anchors.verticalCenter: parent.verticalCenter
                    active: bar.card === "quick"
                    onClicked: bar.open("quick", statusMod)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        Icon { name: System.netIcon; size: 14; anchors.verticalCenter: parent.verticalCenter; color: Theme.hue("down") }
                        Icon {
                            visible: System.btEnabled
                            name: System.btConnected.length > 0 ? "bluetooth-connect" : "bluetooth"
                            size: 14; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter
                        }
                        Row {
                            spacing: 4
                            anchors.verticalCenter: parent.verticalCenter
                            Icon { name: System.volumeIcon; size: 14; color: Theme.hue("mem"); anchors.verticalCenter: parent.verticalCenter }
                            Meter { value: System.muted ? 0 : System.volume; ramp: "mem"; segments: 5; segW: 2; segH: 10; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Icon { visible: System.caffeine; name: "coffee"; size: 14; color: Theme.accent2; anchors.verticalCenter: parent.verticalCenter }
                        BatteryPill {
                            id: batPill
                            visible: System.hasBattery
                            anchors.verticalCenter: parent.verticalCenter
                            HoverHandler { id: batHover }
                        }
                    }
                }

                Module {
                    id: gearMod
                    anchors.verticalCenter: parent.verticalCenter
                    padding: 6
                    active: false
                    onClicked: { bar.close(); System.openSettings("") }
                    Icon {
                        id: gearIcon
                        anchors.verticalCenter: parent.verticalCenter
                        name: "cog"
                        size: 15
                        color: gearMod.active ? Theme.accent : Theme.fg
                        // ticks round in 45° jumps, like a sprite
                        property int frame: 0
                        rotation: frame * 45
                        Timer {
                            interval: 160
                            running: gearMod.hovered || gearMod.active
                            repeat: true
                            onTriggered: gearIcon.frame = (gearIcon.frame + 1) % 8
                        }
                    }
                }
            }
        }

        // ══ the card ══
        PixelBox {
            id: drop
            readonly property bool shown: bar.card !== ""
            readonly property int pad: 16
            readonly property real wantW: content.width + 2 * pad
            readonly property real wantH: content.height + 2 * pad + 4
            readonly property real edge: bar.m

            property real reveal: shown ? 1 : 0
            Behavior on reveal { NumberAnimation { duration: Theme.dur(drop.shown ? 360 : 180); easing.type: drop.shown ? Easing.OutQuad : Easing.InQuad } }

            visible: reveal > 0.01 && bar.shownCard !== ""
            x: Math.round(Math.max(edge, Math.min(win.width - edge - width, bar.anchorX - width / 2)))
            y: bar.m + bar.h + 6
            width: wantW
            // reveal in 8px steps — blocky on purpose
            height: Math.max(8, Math.round(wantH * reveal / 8) * 8)
            step: 3
            fill: Theme.surface   // opaque: busy windows behind would bleed through
            stroke: Theme.alpha(Theme.accent, 0.7)
            title: bar.titles[bar.shownCard] || ""
            titleColor: Theme.accent

            HoverHandler {
                id: dropHover
                onHoveredChanged: if (!hovered && bar.card === "notif") peekTimer.restart()
            }
            MouseArea { anchors.fill: parent }   // clicks on the card background stay in the card

            // leading edge glow while revealing
            Rectangle {
                visible: drop.reveal < 0.99 && drop.shown
                x: 1; width: drop.width - 2
                y: drop.height - 3; height: 2
                color: Theme.accent
            }

            Item {
                x: 1; y: 1
                width: drop.width - 2
                height: drop.height - 2
                clip: true
                Loader {
                    id: content
                    x: drop.pad - 1
                    y: drop.pad + 3
                    active: bar.shownCard !== ""
                    opacity: drop.reveal > 0.6 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(180) } }
                    sourceComponent: ({ quick: quickCard, media: mediaCard, today: todayCard,
                                        notif: notifCard, system: systemCard, screen: screenCard, github: githubCard,
                                        updates: updatesCard })[bar.shownCard] || null
                }
            }
        }

        // stem from bar to card
        Rectangle {
            visible: drop.visible
            x: Math.round(Math.max(drop.x + 12, Math.min(drop.x + drop.width - 14, bar.anchorX - 1)))
            y: bar.m + bar.h
            width: 2; height: 6
            color: Theme.alpha(Theme.accent, 0.7)
        }

        Component { id: quickCard; QuickCard { onClose: bar.close(); onOpenCard: name => name === "settings" ? (bar.close(), System.openSettings("")) : bar.open(name, gearMod) } }
        Component { id: mediaCard; MediaCard { onClose: bar.close() } }
        Component { id: todayCard; TodayCard { onClose: bar.close() } }
        Component { id: systemCard; SystemCard {} }
        Component { id: screenCard; ScreenCard {} }
        Component { id: githubCard; GithubCard {} }
        Component { id: updatesCard; UpdatesCard { onClose: bar.close() } }
        Component {
            id: notifCard
            NotifItem {
                implicitWidth: 380
                notif: bar.peek
                bodyLines: 3
                framed: false
                onActivated: bar.close()
                onNotifChanged: if (!notif) bar.close()   // dismissed elsewhere
            }
        }
    }

    // battery hover: power draw, time left, energy, health
    Tip {
        target: batPill
        show: batHover.hovered && bar.card === ""
        title: "battery"
        hue: Theme.ramp("mem", System.batteryPct / 100)
        Row {
            spacing: 10
            Label { text: System.batteryWatts.toFixed(1); font.pixelSize: Theme.fsBig; color: UPower.onBattery ? Theme.hue("temp") : Theme.hue("mem") }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label { text: UPower.onBattery ? "watts draw" : System.batteryWatts > 0.1 ? "watts charging" : "watts"; color: Theme.dim }
                Label { text: System.batteryPct + "% · " + (UPower.onBattery ? "on battery" : System.batteryWatts > 0.1 ? "charging" : System.batteryPct >= 99 ? "full" : "plugged in"); color: Theme.dim }
            }
        }
        Meter { value: System.batteryPct / 100; ramp: "mem"; segments: 30; segW: 5; segH: 8 }
        Label {
            visible: System.batterySecsLeft > 0
            text: Theme.duration(System.batterySecsLeft) + (UPower.onBattery ? " left at this rate" : " until full")
        }
        Label {
            visible: !!System.batteryDev
            color: Theme.dim
            text: System.batteryDev ? System.batteryDev.energy.toFixed(1) + " / " + System.batteryDev.energyCapacity.toFixed(1) + " Wh"
                + (System.batteryDev.healthSupported ? " · health " + Math.round(System.batteryDev.healthPercentage) + "%" : "") : ""
        }
    }

    IdleInhibitor {
        window: win
        enabled: System.caffeine
    }
}
