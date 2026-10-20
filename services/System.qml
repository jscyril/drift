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

    // ── media: prefer a playing player ──
    readonly property var player: {
        var ps = Mpris.players.values
        return ps.find(p => p.isPlaying) || ps[0] || null
    }

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

    // ── notifications ──
    property bool dnd: false
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
            if (!sys.dnd) sys.notified(n)
        }
    }

    signal requestCard(string name)   // from IPC; the focused monitor's island opens it
    signal openSettings(string page)  // "" = last page

    // ── session ──
    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }
    // lock screen lives in shell.qml; ask it directly (works however drift was launched)
    signal lockRequested()
    function lock() { lockRequested() }
}
