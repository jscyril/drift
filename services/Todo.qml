pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "dates.js" as Dates

// To-do list as [{ id, text, done, due?, notes? }]; due is "YYYY-MM-DD".
// Local mode saves to ~/.config/drift/todos.json. Google mode mirrors your default
// Google Tasks list through bin/drift-gtasks, cached in todos-google.json so the
// local list is never overwritten. Changes show instantly and then sync.
//
// Times ("HH:MM") live in todo-meta.json keyed by task id, because Google Tasks
// only stores a day. The same file remembers which reminders already went out.
Singleton {
    id: todo
    property var items: []
    property bool loaded: false
    property bool metaLoaded: false      // reminders wait for both, so a restart never re-sends
    readonly property int pending: items.filter(t => !t.done).length
    readonly property bool google: Config.opts.todoGoogle

    // local clock as strings, ticking every 30s, so bindings and reminders stay current
    property string today: Dates.iso(new Date())
    property string nowHM: Dates.hm(new Date())
    Timer {
        interval: 30 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            todo.today = Dates.iso(d)
            todo.nowHM = Dates.hm(d)
            todo.remind()
        }
    }

    property var meta: ({ times: {}, notified: {} })
    function timeOf(t) { return (t.id && meta.times[t.id]) || t.time || "" }
    function late(t) { return !t.done && Dates.isLate(t.due, timeOf(t), today, nowHM) }
    readonly property int overdue: { nowHM; meta; return items.filter(t => late(t)).length }

    // the list as shown: open tasks first, then done; "date" puts the soonest due first
    // (no date last), "order" keeps your own order. Each entry carries its index in items.
    function view(sortBy) {
        var key = t => t.due ? t.due + " " + (timeOf(t) || "99:99") : ""
        var v = items.map((t, i) => ({ t: t, i: i }))
        return v.sort((a, b) => {
            if (a.t.done !== b.t.done) return a.t.done ? 1 : -1
            var ka = key(a.t), kb = key(b.t)
            if (sortBy === "date" && ka !== kb) return !ka ? 1 : !kb ? -1 : ka < kb ? -1 : 1
            return a.i - b.i
        })
    }

    function save(list) { items = list; file.setText(JSON.stringify(list, null, 2) + "\n") }
    function saveMeta(m) { meta = m; metaFile.setText(JSON.stringify(m, null, 2) + "\n") }
    function setTime(id, time) {
        var times = Object.assign({}, meta.times)
        if (time) times[id] = time; else delete times[id]
        saveMeta({ times: times, notified: meta.notified })
    }
    function newId() { return "local-" + Date.now().toString(36) + Math.random().toString(36).slice(2, 6) }

    // "pay rent @fri 5pm" sets a due date and time; see dates.js for what @ understands
    function add(input) {
        var p = Dates.parse(input)
        if (p.text === "") return
        var t = { text: p.text, done: false }
        if (p.due) t.due = p.due
        if (google) {
            if (p.time) t.time = p.time            // shown until Google hands back the real id
            save(items.concat([t]))
            run(["add", p.text, p.due], p.time)
        } else {
            t.id = newId()
            save(items.concat([t]))
            if (p.time) setTime(t.id, p.time)
        }
    }
    // due: "YYYY-MM-DD" or "" to clear (clears the time too); time: "HH:MM", "" or undefined to keep
    function setDue(i, due, time) {
        var t = items[i]
        save(items.map((x, j) => {
            if (j !== i) return x
            var y = Object.assign({}, x)
            if (due) y.due = due; else delete y.due
            if (!due || time !== undefined) delete y.time
            return y
        }))
        if (t.id && (!due || time !== undefined)) setTime(t.id, due ? time : "")
        if (google && t.id) run(["due", t.id, due || "none"])
    }
    function toggle(i) {
        var t = items[i]
        save(items.map((x, j) => j === i ? Object.assign({}, x, { done: !x.done }) : x))
        if (google && t.id) run([t.done ? "undone" : "done", t.id])
    }
    function remove(i) {
        var t = items[i]
        save(items.filter((x, j) => j !== i))
        if (t.id && meta.times[t.id]) setTime(t.id, "")
        if (google && t.id) run(["delete", t.id])
    }
    function clearDone() { save(items.filter(t => !t.done)) }   // local only; Google's done tasks drop off after a day

    // ── reminders ──
    // a task with a time: at that time (if drift was off then, up to an hour late).
    // date-only tasks: one summary at 09:00, or at login if later, with anything overdue.
    function notify(title, body) { Quickshell.execDetached(["notify-send", "-a", "drift", title, body]) }
    function remind() {
        if (!Config.opts.todoNotify || !loaded || !metaLoaded) return
        var sent = Object.assign({}, meta.notified), changed = false
        var nowMin = Number(nowHM.slice(0, 2)) * 60 + Number(nowHM.slice(3))
        items.forEach(t => {
            var time = timeOf(t)
            if (t.done || t.due !== today || !time || time > nowHM) return
            var key = "t|" + (t.id || t.text) + "|" + t.due + "|" + time
            if (sent[key]) return
            sent[key] = today
            changed = true
            if (nowMin - (Number(time.slice(0, 2)) * 60 + Number(time.slice(3))) <= 60)
                notify(t.text, "due " + Dates.fmtTime(time, Config.opts.clock24h))
        })
        if (nowHM >= "09:00" && !sent["s|" + today]) {
            sent["s|" + today] = today
            changed = true
            var dueToday = items.filter(t => !t.done && t.due === today && !timeOf(t))
            var lateOnes = items.filter(t => !t.done && t.due && t.due < today)
            if (dueToday.length + lateOnes.length > 0)
                notify("to-do: " + [dueToday.length ? dueToday.length + " due today" : "", lateOnes.length ? lateOnes.length + " overdue" : ""].filter(s => s).join(" · "),
                       dueToday.concat(lateOnes).slice(0, 6).map(t => "• " + t.text).join("\n"))
        }
        if (!changed) return
        for (var k in sent) if (sent[k] < Dates.iso(new Date(Date.now() - 3 * 86400000))) delete sent[k]   // forget old ones
        saveMeta({ times: meta.times, notified: sent })
    }

    // ── Google sync ──
    property string syncError: ""
    property bool needsSignIn: false
    readonly property bool syncing: proc.running
    function sync() { if (google) run(["pull"]) }
    function signIn() { run(["login"]) }

    // one helper call at a time; changes made meanwhile wait their turn
    property var queue: []
    property var current: null
    function run(args, time) {
        queue = queue.concat([{ args: args, time: time || "" }])
        if (!proc.running) next()
    }
    function next() {
        if (queue.length === 0) return
        current = queue[0]
        queue = queue.slice(1)
        proc.command = ["python3", Quickshell.shellDir + "/bin/drift-gtasks"].concat(current.args)
        proc.running = true
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                var r = null
                try { r = JSON.parse(this.text) } catch (e) {}
                if (!r) todo.syncError = "sync helper failed (is python installed?)"
                else if (r.ok) {
                    todo.syncError = ""
                    todo.needsSignIn = false
                    if (r.created && todo.current && todo.current.time) todo.setTime(r.created, todo.current.time)
                    // a newer change is still queued: its result will be fresher
                    if (todo.queue.length === 0 && todo.google) todo.save(r.items)
                } else {
                    todo.syncError = r.error
                    todo.needsSignIn = r.signin
                }
                Qt.callLater(todo.next)
            }
        }
    }

    Timer {
        interval: 2 * 60 * 1000
        running: todo.google && Config.opts.showTodo
        repeat: true
        triggeredOnStart: true
        onTriggered: todo.sync()
    }
    Connections {
        target: Config.opts
        // turning sync on signs in if needed (opens the browser once)
        function onTodoGoogleChanged() {
            todo.syncError = ""
            todo.needsSignIn = false
            if (Config.opts.todoGoogle) todo.signIn()
        }
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/drift/" + (todo.google ? "todos-google.json" : "todos.json")
        watchChanges: true
        onFileChanged: reload()
        onPathChanged: { todo.items = []; todo.loaded = false }
        onLoaded: {
            try {
                var l = JSON.parse(text())
                if (Array.isArray(l)) todo.items = l.filter(t => t && typeof t.text === "string")
            } catch (e) {}   // half-written or hand-broken file: keep what we have
            // local tasks need an id to carry a time
            if (!todo.google && todo.items.some(t => !t.id)) todo.save(todo.items.map(t => t.id ? t : Object.assign({ id: todo.newId() }, t)))
            todo.loaded = true
        }
        onLoadFailed: todo.loaded = true   // no file yet: an empty list is the truth
    }
    FileView {
        id: metaFile
        path: Quickshell.env("HOME") + "/.config/drift/todo-meta.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                var m = JSON.parse(text())
                todo.meta = { times: m.times || {}, notified: m.notified || {} }
            } catch (e) {}
            todo.metaLoaded = true
        }
        onLoadFailed: todo.metaLoaded = true
    }
}
