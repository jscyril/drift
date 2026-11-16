pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Night light: warms the screen with gammastep for as long as it is on.
// The schedule flips Config.nightLight at its two times, so a manual toggle
// in between holds until the next one.
Singleton {
    id: nl
    readonly property var o: Config.opts
    property bool available: false               // is gammastep installed?
    readonly property bool on: o.nightLight
    function toggle() { o.nightLight = !o.nightLight }

    // "HH:MM" -> minutes since midnight, -1 if it isn't a time
    function mins(t) {
        var m = /^(\d{1,2}):(\d{2})$/.exec(t)
        return m && m[1] < 24 && m[2] < 60 ? m[1] * 60 + Number(m[2]) : -1
    }
    function within(now, from, to) { return from <= to ? now >= from && now < to : now >= from || now < to }

    SystemClock { id: clock; precision: SystemClock.Minutes }
    readonly property bool inWindow: {
        var a = mins(o.nightFrom), b = mins(o.nightTo)
        return a >= 0 && b >= 0 && within(clock.hours * 60 + clock.minutes, a, b)
    }
    onInWindowChanged: follow()
    readonly property bool scheduled: o.nightSchedule
    onScheduledChanged: follow()
    function follow() { if (scheduled) o.nightLight = inWindow }

    // gammastep holds the tint while it runs; quitting it clears the tint
    readonly property var want: on && available ? ["gammastep", "-P", "-O", String(o.nightTemp)] : []
    onWantChanged: apply.restart()
    Timer {   // also coalesces slider drags
        id: apply
        interval: 200
        onTriggered: {
            tint.running = false
            if (nl.want.length > 0) { tint.command = nl.want; tint.running = true }
        }
    }
    Process { id: tint }
    Process {
        running: true
        command: ["sh", "-c", "command -v gammastep"]
        onExited: code => nl.available = code === 0
    }

    Component.onCompleted: {
        console.assert(mins("20:00") === 1200 && mins("7:05") === 425 && mins("24:00") === -1 && mins("x") === -1)
        console.assert(within(1300, 1200, 420) && within(60, 1200, 420) && !within(600, 1200, 420))   // over midnight
        console.assert(within(600, 420, 1200) && !within(1300, 420, 1200))
        follow()
    }
}
