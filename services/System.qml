pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Services.Notifications
import Quickshell.Bluetooth
import QtQuick

// Everything the island shows that isn't niri: audio, media, battery,
// network, bluetooth, brightness, notifications, caffeine.
Singleton {
    id: sys

    // ── audio ──
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: !sink || !sink.audio || sink.audio.muted
    function setVolume(v) { if (sink && sink.audio) { sink.audio.muted = false; sink.audio.volume = Math.max(0, Math.min(1, v)) } }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted }
    readonly property string volumeIcon: muted || volume < 0.01 ? "volume-off"
        : volume < 0.34 ? "volume-low" : volume < 0.67 ? "volume-medium" : "volume-high"
    PwObjectTracker { objects: [sys.sink, sys.source] }

    // ── microphone ──
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool hasMic: !!source && !!source.audio
    readonly property real micVolume: hasMic ? source.audio.volume : 0
    readonly property bool micMuted: !hasMic || source.audio.muted
    function setMicVolume(v) { if (hasMic) { source.audio.muted = false; source.audio.volume = Math.max(0, Math.min(1, v)) } }
    function toggleMicMute() { if (hasMic) source.audio.muted = !source.audio.muted }

    // ── media: the pinned player, else a playing one ──
    readonly property var players: Mpris.players.values
    property var pinnedPlayer: null              // picked in the media card
    readonly property var player: players.indexOf(pinnedPlayer) >= 0 ? pinnedPlayer
        : players.find(p => p.isPlaying) || players[0] || null

    // ── power saver: slower polling, no idle animations ──
    readonly property bool lowPower: Config.opts.powerSaver === "on" || (Config.opts.powerSaver === "auto" && UPower.onBattery)

    // ── battery ──
    // the physical battery: has the live power draw, energy and health
    readonly property var batteryDev: UPower.devices.values.find(d => d.isLaptopBattery) || null
    readonly property real batteryWatts: batteryDev ? Math.abs(batteryDev.changeRate) : 0
    readonly property string batteryPowerText: !hasBattery ? ""
        : UPower.onBattery ? batteryWatts.toFixed(1) + " W draw"
        : batteryWatts > 0.1 ? batteryWatts.toFixed(1) + " W charging"
        : "plugged in"
    readonly property real batterySecsLeft: !battery ? 0 : UPower.onBattery ? battery.timeToEmpty : battery.timeToFull
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isLaptopBattery
    // UPower reports 0..1 on current Quickshell; older builds used 0..100
    readonly property int batteryPct: !battery ? 0 : Math.round(battery.percentage > 1 ? battery.percentage : battery.percentage * 100)
    readonly property bool charging: battery && (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged)
    readonly property string batteryIcon: charging ? "battery-charging"
        : batteryPct <= 5 ? "battery-alert"
        : batteryPct >= 95 ? "battery"
        : "battery-" + Math.max(10, Math.round(batteryPct / 10) * 10)

    // ── network (nmcli; Quickshell.Networking is still young) ──
    property string wifiSsid: ""
    property int wifiSignal: 0
    property bool wifiEnabled: true
    property bool wired: false
    readonly property string netIcon: wired ? "ethernet"
        : (!wifiEnabled || wifiSsid === "") ? "wifi-off"
        : "wifi-" + Math.max(1, Math.ceil(wifiSignal / 25))
    function refreshNet() { netPoll.restart() }
    function toggleWifi() {
        Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"])
        wifiEnabled = !wifiEnabled
        netPoll.restart()
    }
    Process {
        id: netProc
        command: ["sh", "-c", "nmcli -t -f WIFI radio; nmcli -t -f TYPE,STATE device | grep -q '^ethernet:connected' && echo WIRED || echo NOWIRE; nmcli -t -f ACTIVE,SIGNAL,SSID dev wifi | grep '^yes' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.trim().split("\n")
                sys.wifiEnabled = lines[0] === "enabled"
                sys.wired = lines[1] === "WIRED"
                var parts = (lines[2] || "").split(":")
                sys.wifiSignal = parseInt(parts[1]) || 0
                sys.wifiSsid = parts.slice(2).join(":")
            }
        }
    }
    Timer { id: netPoll; interval: sys.lowPower ? 30000 : 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: netProc.running = true }

    // ── bluetooth ──
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool btEnabled: adapter ? adapter.enabled : false
    readonly property var btConnected: adapter ? adapter.devices.values.filter(d => d.connected) : []
    function toggleBluetooth() { if (adapter) adapter.enabled = !adapter.enabled }

    // ── brightness (brightnessctl) ──
    property real brightness: 0.5
    property bool hasBacklight: false
    function setBrightness(v) {
        brightness = Math.max(0.02, Math.min(1, v))
        brightnessSet.restart()
    }
    Timer {   // coalesce slider drags into one call
        id: brightnessSet
        interval: 40
        onTriggered: Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(sys.brightness * 100) + "%"])
    }
    Process {
        id: brightnessGet
        command: ["brightnessctl", "-m", "-c", "backlight"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var f = this.text.trim().split(",")
                sys.hasBacklight = f.length >= 5
                if (sys.hasBacklight) sys.brightness = parseInt(f[2]) / parseInt(f[4])
            }
        }
    }
    function refreshBrightness() { if (!brightnessSet.running) brightnessGet.running = true }

    // ── caffeine: islands inhibit idle while on ──
    property bool caffeine: false

    // ── low battery: one warning each time it drops through 20, 10 and 5% ──
    function batteryStep(pct) { return pct <= 5 ? 5 : pct <= 10 ? 10 : pct <= 20 ? 20 : 101 }
    property int warnedAt: 101
    readonly property bool discharging: hasBattery && UPower.onBattery
    onDischargingChanged: warnedAt = 101
    onBatteryPctChanged: {
        var step = batteryStep(batteryPct)
        if (!discharging || !Config.opts.lowBatteryWarn || step >= warnedAt) return
        warnedAt = step
        Quickshell.execDetached(["notify-send", "-a", "drift", "-u", step <= 10 ? "critical" : "normal", "-i", "battery-caution",
            "battery at " + batteryPct + "%", step <= 5 ? "plug in now" : batterySecsLeft > 0 ? Theme.duration(batterySecsLeft) + " left" : "plug in soon"])
    }
    Component.onCompleted: console.assert(batteryStep(100) === 101 && batteryStep(20) === 20 && batteryStep(11) === 20
        && batteryStep(10) === 10 && batteryStep(5) === 5 && batteryStep(0) === 5)

    // ── notifications ──
    property bool dnd: false
    // focus mode: do not disturb for a while, or by the clock
    property double dndUntil: 0                  // ms since epoch, 0 = no timer
    function quiet(minutes) { dnd = true; dndUntil = Date.now() + minutes * 60000 }
    onDndChanged: if (!dnd) dndUntil = 0
    Timer {
        interval: 15000
        repeat: true
        running: sys.dndUntil > 0
        onTriggered: if (Date.now() >= sys.dndUntil) sys.dnd = false
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property bool dndWindow: {
        var a = NightLight.mins(Config.opts.dndFrom), b = NightLight.mins(Config.opts.dndTo)
        return a >= 0 && b >= 0 && NightLight.within(clock.hours * 60 + clock.minutes, a, b)
    }
    readonly property bool dndScheduled: Config.opts.dndSchedule
    // like the night light: the schedule flips it at its two times, a manual toggle holds until the next one
    function followDnd() { if (dndScheduled) dnd = dndWindow }
    onDndWindowChanged: followDnd()
    onDndScheduledChanged: followDnd()
    readonly property string dndText: !dnd ? "alerts on"
        : dndUntil > 0 ? "quiet until " + Qt.formatTime(new Date(dndUntil), "hh:mm")
        : dndScheduled && dndWindow ? "quiet until " + Config.opts.dndTo : "silenced"
    readonly property var notifications: server.trackedNotifications.values.slice().reverse()
    signal notified(var n)
    function clearNotifications() { server.trackedNotifications.values.slice().forEach(n => n.dismiss()) }
    function invoke(n) {
        if (!n) return
        var act = n.actions.find(a => a.identifier === "default") || n.actions[0]
        if (act) act.invoke()
        n.dismiss()
    }

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodyMarkupSupported: false
        onNotification: n => {
            n.tracked = true
            sys.remember(n)
            if (!sys.dnd) sys.notified(n)
        }
    }

    // ── notification history: everything that arrived, kept after it is dismissed ──
    property var history: []                     // newest first: [{ key, nid, app, icon, summary, body, time }]
    readonly property int historyMax: 100
    function same(e, nid, summary, body) { return e.nid === nid && e.summary === summary && e.body === body }
    function remember(n) {
        // a reload hands the waiting notifications over again: those are already in here
        if (history.some(e => same(e, n.id, n.summary, n.body))) return
        saveHistory([{ key: Date.now() + "-" + n.id, nid: n.id, app: n.appName, icon: n.appIcon || n.desktopEntry || n.appName,
                       summary: n.summary, body: n.body, time: Date.now() }].concat(history).slice(0, historyMax))
    }
    // the notification behind a history entry, while it is still waiting to be dismissed
    function liveOf(e) { return notifications.find(n => n.id === e.nid && n.summary === e.summary) || null }
    function forget(e) {
        var n = liveOf(e)
        if (n) n.dismiss()
        saveHistory(history.filter(x => x.key !== e.key))
    }
    function clearHistory() { clearNotifications(); saveHistory([]) }
    function saveHistory(h) { history = h; historyFile.setText(JSON.stringify(h) + "\n") }
    function ago(t) {
        var s = Math.max(0, (Date.now() - t) / 1000)
        return s < 60 ? "now" : s < 3600 ? Math.floor(s / 60) + "m" : s < 86400 ? Math.floor(s / 3600) + "h" : Math.floor(s / 86400) + "d"
    }
    FileView {
        id: historyFile
        path: Quickshell.env("HOME") + "/.config/drift/notifications.json"
        printErrors: false
        // anything that arrived before the file was read stays on top
        onLoaded: {
            try {
                var old = JSON.parse(text()).filter(o => !sys.history.some(e => sys.same(e, o.nid, o.summary, o.body)))
                sys.history = sys.history.concat(old).slice(0, sys.historyMax)
            } catch (e) {}
        }
    }

    signal requestCard(string name)   // from IPC; the focused monitor's island opens it
    signal openSettings(string page)  // "" = last page

    // ── session ──
    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    // lock screen lives in shell.qml; ask it directly (works however drift was launched)
    signal lockRequested()
    function lock() { lockRequested() }
    // keybind cheatsheet lives in shell.qml too
    signal keybindsRequested()
    function toggleKeybinds() { keybindsRequested() }
    // so do the other overlays: "wallpapers" | "themes" | "search" | "capture" | "session"
    signal overlayRequested(string which)
}
