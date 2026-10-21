.pragma library

// Due dates for the to-do list. Dates are "YYYY-MM-DD" strings in local time
// (Google Tasks stores a day, not a time).

var DAYS = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
var MONTHS = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]

function pad(n) { return (n < 10 ? "0" : "") + n }
function iso(d) { return d.getFullYear() + "-" + pad(d.getMonth() + 1) + "-" + pad(d.getDate()) }
function parseIso(s) { var p = s.split("-"); return new Date(Number(p[0]), Number(p[1]) - 1, Number(p[2])) }

// a real calendar day (no 31 feb), else null
function make(y, m, d) {
    var dt = new Date(y, m, d)
    return dt.getMonth() === m && dt.getDate() === d ? iso(dt) : null
}
// day + month with no year: this year, or next year if that day already passed
function upcoming(m, d, now) {
    var s = make(now.getFullYear(), m, d)
    return s && s >= iso(now) ? s : make(now.getFullYear() + 1, m, d)
}
function monthOf(w) { return w.length >= 3 ? MONTHS.indexOf(w.slice(0, 3)) : -1 }

// one word -> date: today tomorrow tmr | mon..sunday (next one, today counts) |
// +3 3d (days) 2w (weeks) | 2026-10-25 | 25/10 (day/month) | 25oct oct25
function dueFrom(word, now) {
    var w = word.toLowerCase(), m
    var y = now.getFullYear(), mo = now.getMonth(), d = now.getDate()
    var at = n => iso(new Date(y, mo, d + n))
    if (w === "today" || w === "tod") return at(0)
    if (w === "tomorrow" || w === "tmr" || w === "tom") return at(1)
    if ((m = /^\+(\d+)$/.exec(w)) || (m = /^(\d+)d$/.exec(w))) return at(Number(m[1]))
    if ((m = /^(\d+)w$/.exec(w))) return at(7 * Number(m[1]))
    if (w.length >= 3) {
        var day = DAYS.findIndex(x => x.startsWith(w))
        if (day >= 0) return at((day - now.getDay() + 7) % 7)
    }
    if ((m = /^(\d{4})-(\d{1,2})-(\d{1,2})$/.exec(w))) return make(Number(m[1]), Number(m[2]) - 1, Number(m[3]))
    if ((m = /^(\d{1,2})\/(\d{1,2})$/.exec(w))) return upcoming(Number(m[2]) - 1, Number(m[1]), now)
    if ((m = /^(\d{1,2})([a-z]{3,})$/.exec(w)) && monthOf(m[2]) >= 0) return upcoming(monthOf(m[2]), Number(m[1]), now)
    if ((m = /^([a-z]{3,})(\d{1,2})$/.exec(w)) && monthOf(m[1]) >= 0) return upcoming(monthOf(m[1]), Number(m[2]), now)
    return null
}

// "5pm" "5:30pm" "9am" "17:30" -> "HH:MM" (24h); a bare "5" is not a time
function timeFrom(word) {
    var m = /^(\d{1,2})(?::(\d{2}))?(am|pm)?$/.exec(word.toLowerCase())
    if (!m || (!m[2] && !m[3])) return null
    var h = Number(m[1]), min = m[2] ? Number(m[2]) : 0
    if (min > 59) return null
    if (m[3]) {
        if (h < 1 || h > 12) return null
        h = h % 12 + (m[3] === "pm" ? 12 : 0)
    } else if (h > 23) return null
    return pad(h) + ":" + pad(min)
}
function hm(now) { return pad(now.getHours()) + ":" + pad(now.getMinutes()) }

// "fri" | "fri 5pm" | "5pm" -> { due, time } (time "" if none), else null.
// A time alone means today, or tomorrow if that time already passed.
function when(s, now) {
    var w = s.trim().split(/\s+/), d, t
    if (w.length === 1) {
        if ((d = dueFrom(w[0], now))) return { due: d, time: "" }
        if ((t = timeFrom(w[0]))) return { due: iso(new Date(now.getFullYear(), now.getMonth(), now.getDate() + (t > hm(now) ? 0 : 1))), time: t }
        return null
    }
    if (w.length === 2 && (d = dueFrom(w[0], now)) && (t = timeFrom(w[1]))) return { due: d, time: t }
    return null
}

// "pay rent @fri 5pm" -> { text: "pay rent", due: "2026-10-23", time: "17:00" }.
// Without a valid trailing @when the text is kept whole and due/time are "".
function parse(input, now) {
    now = now || new Date()
    var s = input.trim(), m = /^(.*\S)\s+@(\S+(?:\s+\S+)?)$/.exec(s)
    var w = m ? when(m[2], now) : null
    return w ? { text: m[1], due: w.due, time: w.time } : { text: s, due: "", time: "" }
}

// "17:30" -> "17:30" or "5:30pm"
function fmtTime(t, h24) {
    if (h24) return t
    var h = Number(t.slice(0, 2)), min = t.slice(3)
    return (h % 12 || 12) + (min === "00" ? "" : ":" + min) + (h < 12 ? "am" : "pm")
}

// past due: an earlier day, or today with its time gone by. Plain strings, so cheap to bind.
function isLate(due, time, today, nowHM) {
    return !!due && (due < today || (due === today && !!time && time <= nowHM))
}

// whole days from today to due (negative = late)
function daysUntil(due, now) {
    var t = new Date(now.getFullYear(), now.getMonth(), now.getDate())
    return Math.round((parseIso(due) - t) / 86400000)
}

// label plus the time, if any: "today 5pm", "fri 17:30"
function whenLabel(due, time, now, h24) {
    return label(due, now) + (time ? " " + fmtTime(time, h24) : "")
}

// short label: "3d late" / "yesterday" / "today" / "tomorrow" / "fri" / "25 oct" / "25 oct 2027"
function label(due, now) {
    var n = daysUntil(due, now), d = parseIso(due)
    if (n < -1) return -n + "d late"
    if (n === -1) return "yesterday"
    if (n === 0) return "today"
    if (n === 1) return "tomorrow"
    if (n < 7) return DAYS[d.getDay()].slice(0, 3)
    return plain(due, now)
}

// "25 oct", or "25 oct 2027" outside this year
function plain(due, now) {
    var d = parseIso(due)
    return d.getDate() + " " + MONTHS[d.getMonth()] + (d.getFullYear() !== now.getFullYear() ? " " + d.getFullYear() : "")
}
