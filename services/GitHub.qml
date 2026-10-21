pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Public contribution calendar, read straight from GitHub's own calendar page
// (no token needed; third-party APIs cache it and lag). Refreshed every 30 minutes.
Singleton {
    id: gh

    property var days: []                // [{ date, count, level }], oldest first
    property int totalYear: 0
    property bool ready: false
    readonly property bool loading: proc.running

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

    // github.com/users/<name>/contributions: a <td data-date data-level> per day,
    // with the count only in its <tool-tip for=id> ("No contributions" / "3 contributions")
    function parse(html) {
        var counts = {}, m
        var tipRe = /<tool-tip[^>]*\bfor="([^"]+)"[^>]*>\s*(No|\d+) contribution/g
        while ((m = tipRe.exec(html))) counts[m[1]] = m[2] === "No" ? 0 : Number(m[2])
        var out = [], tdRe = /<td\b[^>]*ContributionCalendar-day[^>]*>/g
        while ((m = tdRe.exec(html))) {
            var date = /data-date="([^"]+)"/.exec(m[0]), id = /\bid="([^"]+)"/.exec(m[0]), level = /data-level="(\d)"/.exec(m[0])
            if (!date || !id) continue
            out.push({ date: date[1], count: counts[id[1]] || 0, level: level ? Number(level[1]) : 0 })
        }
        return out.sort((a, b) => a.date < b.date ? -1 : 1)
    }

    Process {
        id: proc
        command: ["curl", "-sfL", "--max-time", "15",
                  "https://github.com/users/" + encodeURIComponent(Config.opts.githubUser) + "/contributions"]
        stdout: StdioCollector {
            onStreamFinished: {
                var d = gh.parse(this.text)
                if (d.length === 0) return            // network/markup failure: keep the last good data
                gh.days = d
                gh.totalYear = d.reduce((n, x) => n + x.count, 0)
                gh.ready = true
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
