pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Counts time per focused app (niri app_id), per hour, per day. Pauses when
// you're idle. Stored in ~/.local/state/drift/screentime.json using the same
// layout as Noctalia's tracker, whose history is imported on first run:
//   { "YYYY-MM-DD": { apps: {app: s}, hourly: [24], app_hourly: {app: [24]} } }
Singleton {
    id: st

    readonly property string path: Quickshell.env("HOME") + "/.local/state/drift/screentime.json"
    readonly property string noctaliaPath: Quickshell.env("HOME") + "/.local/state/noctalia/screen_time.json"
    readonly property int tick: 5        // seconds per sample

    property var data: ({})
    property bool loaded: false
    property bool dirty: false
    property int version: 0              // bumps on every change, for bindings

    function key(d) {
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0")
    }
    function day(k) { version; return data[k] || { apps: {}, hourly: new Array(24).fill(0), app_hourly: {} } }
    function total(k) { return day(k).hourly.reduce((a, b) => a + b, 0) }

    readonly property string todayKey: { version; return key(new Date()) }
    // a fresh object on every tick: the stored one is mutated in place, and handing
    // bindings the same object again doesn't count as a change (the bar froze on that)
    readonly property var today: {
        version
        var d = day(todayKey)
        return { apps: Object.assign({}, d.apps), hourly: d.hourly.slice(), app_hourly: d.app_hourly }
    }
    readonly property real todayTotal: today.hourly.reduce((a, b) => a + b, 0)
    readonly property var todayApps: Object.keys(today.apps).map(a => ({ app: a, secs: today.apps[a] }))
        .sort((a, b) => b.secs - a.secs)
    // last 7 days, oldest first
    readonly property var week: {
        version
        var out = []
        for (var i = 6; i >= 0; i--) {
            var d = new Date()
            d.setDate(d.getDate() - i)
            out.push({ date: d, secs: total(key(d)) })
        }
        return out
    }

    IdleMonitor {
        id: idle
        timeout: Config.opts.idleMinutes * 60
        respectInhibitors: true
    }

    Timer {
        interval: st.tick * 1000
        running: st.loaded
        repeat: true
        onTriggered: {
            var w = Niri.focusedWindow
            if (idle.isIdle || !w || !w.app_id) return
            var now = new Date()
            var k = st.key(now), h = now.getHours(), app = w.app_id
            var d = st.data[k] || { apps: {}, hourly: new Array(24).fill(0), app_hourly: {} }
            d.apps[app] = (d.apps[app] || 0) + st.tick
            d.hourly[h] += st.tick
            if (!d.app_hourly[app]) d.app_hourly[app] = new Array(24).fill(0)
            d.app_hourly[app][h] += st.tick
            st.data[k] = d
            st.dirty = true
            st.version++
        }
    }

    // write at most once a minute
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: st.save()
    }
    function save() {
        if (!loaded || !dirty) return
        // keep 90 days
        var cutoff = new Date()
        cutoff.setDate(cutoff.getDate() - 90)
        var ck = key(cutoff)
        Object.keys(data).forEach(k => { if (k < ck) delete data[k] })
        file.setText(JSON.stringify(data))
        dirty = false
    }

    FileView {
        id: file
        path: st.path
        printErrors: false
        onLoaded: {
            try { st.data = JSON.parse(text()) } catch (e) { st.data = {} }
            st.loaded = true
            st.version++
        }
        onLoadFailed: importer.running = true
    }

    // first run: start from Noctalia's history if there is one
    Process {
        id: importer
        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")"; if [ -f "$2" ]; then cp "$2" "$1"; else echo "{}" > "$1"; fi', "sh", st.path, st.noctaliaPath]
        onExited: file.reload()
    }

    Component.onDestruction: save()
}
