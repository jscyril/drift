pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Public contribution calendar via github-contributions-api.jogruber.de
// (no token needed). Refreshed every 30 minutes.
Singleton {
    id: gh

    property var days: []                // [{ date, count, level }], oldest first
    property int totalYear: 0
    property bool ready: false

    readonly property int streak: {
        var s = 0
        // today may still be empty; count back from yesterday in that case
        var i = days.length - 1
        if (i >= 0 && days[i].count === 0) i--
        for (; i >= 0 && days[i].count > 0; i--) s++
        return s
    }
    readonly property int bestStreak: {
        var best = 0, run = 0
        days.forEach(d => { run = d.count > 0 ? run + 1 : 0; best = Math.max(best, run) })
        return best
    }
    readonly property var bestDay: days.reduce((b, d) => !b || d.count > b.count ? d : b, null)
    readonly property int thisWeek: {
        var n = 0
        for (var i = days.length - 1; i >= 0 && i >= days.length - 7; i--) n += days[i].count
        return n
    }

    // last `weeks` columns, each 7 days Sun..Sat, aligned like GitHub
    function grid(weeks) {
        if (days.length === 0) return []
        var last = new Date(days[days.length - 1].date + "T00:00:00")
        var pad = 6 - last.getDay()                       // future cells to end the column on Saturday
        var need = weeks * 7 - pad
        var cells = days.slice(-need)
        while (cells.length < need) cells.unshift(null)   // keep weekday rows aligned
        for (var i = 0; i < pad; i++) cells.push(null)
        var cols = []
        for (var c = 0; c < cells.length; c += 7) cols.push(cells.slice(c, c + 7))
        return cols
    }

    function refresh() { if (Config.opts.githubUser !== "") proc.running = true }

    Process {
        id: proc
        command: ["curl", "-s", "--max-time", "15",
                  "https://github-contributions-api.jogruber.de/v4/" + encodeURIComponent(Config.opts.githubUser) + "?y=last"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var j = JSON.parse(this.text)
                    if (!j.contributions) return
                    gh.days = j.contributions
                    gh.totalYear = j.total.lastYear || 0
                    gh.ready = true
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 30 * 60 * 1000
        running: Config.opts.showGithub
        repeat: true
        triggeredOnStart: true
        onTriggered: gh.refresh()
    }
    Connections {
        target: Config.opts
        function onGithubUserChanged() { userChange.restart() }
    }
    Timer { id: userChange; interval: 1500; onTriggered: { gh.days = []; gh.ready = false; gh.refresh() } }
}
