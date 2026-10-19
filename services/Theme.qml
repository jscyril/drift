pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Pixel look: Departure Mono, stepped corners, neon meter ramps.
// Chrome colors come from matugen (wallpaper or custom accent).
// shortcut: the wallpaper path is polled from Noctalia; once drift owns the
// wallpaper, read it from drift's own state instead.
Singleton {
    id: theme

    // chrome palette (fallback until matugen answers)
    property color surface: "#0f1215"
    property color bg: "#161a1e"
    property color raised: "#262b31"
    property color fg: "#e1e2e8"
    property color dim: "#9aa0aa"
    property color accent: "#7ab8ff"
    property color accentText: "#00315c"
    property color accent2: "#ff8fd0"
    property color accent3: "#8ff0c8"
    property color outline: "#43474e"

    Behavior on surface { ColorAnimation { duration: 900 } }
    Behavior on bg { ColorAnimation { duration: 900 } }
    Behavior on raised { ColorAnimation { duration: 900 } }
    Behavior on fg { ColorAnimation { duration: 900 } }
    Behavior on dim { ColorAnimation { duration: 900 } }
    Behavior on accent { ColorAnimation { duration: 900 } }
    Behavior on accentText { ColorAnimation { duration: 900 } }
    Behavior on accent2 { ColorAnimation { duration: 900 } }
    Behavior on accent3 { ColorAnimation { duration: 900 } }
    Behavior on outline { ColorAnimation { duration: 900 } }

    readonly property string font: "Departure Mono"   // drawn on an 11px grid
    readonly property int fs: 11
    readonly property int fsBig: 22
    readonly property string iconFont: "Material Design Icons Desktop"

    function dur(ms) { return Math.round(ms / Math.max(0.25, Config.opts.animSpeed)) }
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }

    // ── meter ramps: neon (btop-ish) or derived from the wallpaper ──
    readonly property bool neon: Config.opts.meterColors === "neon"
    readonly property var ramps: neon ? ({
        cpu:  ["#3ddc84", "#c6e84a", "#ffb547", "#ff4f6d"],
        mem:  ["#45e0ff", "#5d8bff", "#b56bff", "#ff5fd2"],
        temp: ["#56d364", "#ffd23f", "#ff7a3d", "#ff3b5c"],
        gpu:  ["#ffe066", "#ff9f43", "#ff5e7e"],
        down: ["#4af2c8", "#2fb8ff", "#5d8bff"],
        up:   ["#ffb86b", "#ff6b9d", "#d66bff"],
        time: ["#9d7bff", "#ff6bd6", "#ffb86b"],
        gh:   ["#0e4f2c", "#127a3e", "#26a641", "#39d353", "#8bff9e"]
    }) : ({
        cpu:  [accent3, accent, accent2], mem: [accent, accent2], temp: [accent3, accent2],
        gpu:  [accent, accent2], down: [accent3, accent], up: [accent, accent2],
        time: [accent, accent2], gh: [mix(bg, accent, 0.25), mix(bg, accent, 0.5), mix(bg, accent, 0.75), accent, accent2]
    })
    // color at t (0..1) along a ramp
    function ramp(name, t) {
        var r = ramps[name] || [accent, accent2]
        t = Math.max(0, Math.min(1, t || 0)) * (r.length - 1)   // NaN -> start of ramp
        var i = Math.min(r.length - 2, Math.floor(t))
        return mix(Qt.color(r[i]), Qt.color(r[i + 1]), t - i)
    }
    // the "identity" color of a module (its ramp's middle)
    function hue(name) { return ramp(name, 0.5) }

    // Material Design Icons codepoints (checked against the installed font)
    readonly property var glyphs: ({
        "volume-high": 0xf057e, "volume-medium": 0xf0580, "volume-low": 0xf057f, "volume-off": 0xf0581,
        "wifi-1": 0xf091f, "wifi-2": 0xf0922, "wifi-3": 0xf0925, "wifi-4": 0xf0928, "wifi-off": 0xf05aa,
        "ethernet": 0xf0200,
        "bluetooth": 0xf00af, "bluetooth-off": 0xf00b2, "bluetooth-connect": 0xf00b1,
        "battery": 0xf0079, "battery-charging": 0xf0084,
        "brightness": 0xf00df, "play": 0xf040a, "pause": 0xf03e4, "next": 0xf04ad, "prev": 0xf04ae,
        "power": 0xf0425, "lock": 0xf033e, "restart": 0xf0709, "sleep": 0xf04b2,
        "bell": 0xf009a, "bell-off": 0xf009b, "coffee": 0xf0176, "coffee-outline": 0xf06ca,
        "close": 0xf0156, "left": 0xf0141, "right": 0xf0142, "music": 0xf0388, "sweep": 0xf05e9, "check": 0xf012c,
        "arch": 0xf08c7, "cog": 0xf0493,
        "weather-sunny": 0xf0599, "weather-night": 0xf0594, "weather-partly-cloudy": 0xf0595,
        "weather-night-partly-cloudy": 0xf0f31, "weather-cloudy": 0xf0590, "weather-fog": 0xf0591,
        "weather-rainy": 0xf0597, "weather-pouring": 0xf0596, "weather-snowy": 0xf0598,
        "weather-lightning": 0xf0593, "weather-windy": 0xf059d,
        "github": 0xf02a4, "timer": 0xf13ab, "chip": 0xf061a, "memory": 0xf035b, "thermometer": 0xf050f,
        "gpu": 0xf08ae, "arrow-down": 0xf0045, "arrow-up": 0xf005d, "humidity": 0xf058e, "pin": 0xf07d9,
        "fire": 0xf0238, "trophy": 0xf0538, "kill": 0xf0156,
        "palette": 0xf03d8, "image": 0xf02f9, "dashboard": 0xf056e, "clock": 0xf0150, "monitor": 0xf0379,
        "speaker": 0xf04c3, "mic": 0xf036c, "mic-off": 0xf036d, "database": 0xf01bc, "tune": 0xf062e, "info": 0xf02fd,
        "wifi-lock": 0xf16bf, "refresh": 0xf0450, "unlink": 0xf0338, "headphones": 0xf02cb, "keyboard": 0xf030c,
        "search": 0xf0349, "bolt": 0xf140b, "leaf": 0xf032a, "rocket": 0xf14de, "balance": 0xf05d1,
        "bell-ring": 0xf009e, "monitors": 0xf037a, "plus": 0xf0415, "minus": 0xf0374, "trash": 0xf0a79,
        "lan": 0xf0318, "phone": 0xf011c, "laptop": 0xf0322, "mouse": 0xf037d, "gamepad": 0xf0297,
        "devices": 0xf0fb0, "crop": 0xf019e, "window": 0xf10ac, "record": 0xf044a, "video": 0xf0567,
        "webcam": 0xf05a0, "screen-share": 0xf1483, "package-up": 0xf03d5, "clipboard": 0xf0a38,
        "unlock": 0xf0fc6, "account-circle": 0xf0009, "enter": 0xf0734, "pencil": 0xf03eb, "radar": 0xf0437, "rotate": 0xf0467, "cpu64": 0xf0ee0, "disk": 0xf02ca,
        "account": 0xf0004, "plug": 0xf06a5, "eye": 0xf0208
    })
    function glyph(name) {
        var c = glyphs[name]
        return c ? String.fromCodePoint(c) : ""
    }

    function appIcon(appId) {
        var e = appId ? DesktopEntries.heuristicLookup(appId) : null
        var p = Quickshell.iconPath(e ? e.icon : (appId || ""), true)
        return p !== "" ? p : Quickshell.iconPath("application-x-executable", true)
    }
    function appName(appId) {
        var e = appId ? DesktopEntries.heuristicLookup(appId) : null
        return e && e.name ? e.name : (appId || "unknown").split(".").pop()
    }

    // human formats
    function bytes(n) {
        var u = ["B", "K", "M", "G", "T"], i = 0
        while (n >= 1024 && i < u.length - 1) { n /= 1024; i++ }
        return (n >= 100 || i === 0 ? Math.round(n) : n.toFixed(1)) + u[i]
    }
    function clockSecs(s) { return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }
    function duration(s) {
        s = Math.round(s)
        var h = Math.floor(s / 3600), m = Math.floor((s % 3600) / 60)
        return h > 0 ? h + "h" + String(m).padStart(2, "0") : m + "m"
    }

    // ── palette generation ──
    property string wallpaper: ""
    function setWallpaper(path) {
        Quickshell.execDetached(["noctalia", "msg", "wallpaper-set", path])
        wallpaper = path
    }
    readonly property var matugenCmd: {
        var tail = ["--json", "hex", "--dry-run", "-m", "dark", "-t", Config.opts.scheme]
        if (Config.opts.colorMode === "custom")
            return ["matugen", "color", "hex", Config.opts.customAccent].concat(tail)
        if (wallpaper === "") return []
        return ["matugen", "image", wallpaper, "--prefer", "saturation", "--fallback-color", "#8aa4c8"].concat(tail)
    }
    onMatugenCmdChanged: regen.restart()
    Timer {
        id: regen
        interval: 150
        onTriggered: if (theme.matugenCmd.length > 0) { matugenProc.running = false; matugenProc.running = true }
    }

    Process {
        id: wallpaperProc
        command: ["noctalia", "msg", "wallpaper-get"]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = this.text.trim()
                if (p.charAt(0) === "/") theme.wallpaper = p
            }
        }
    }
    Timer {
        interval: System.lowPower ? 60000 : 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wallpaperProc.running = true
    }

    Process {
        id: matugenProc
        command: theme.matugenCmd
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var c = JSON.parse(this.text).colors
                    var get = n => c[n].dark.color
                    theme.surface = get("surface_container_lowest")
                    theme.bg = get("surface")
                    theme.raised = get("surface_container_high")
                    theme.fg = get("on_surface")
                    theme.dim = get("on_surface_variant")
                    theme.accent = get("primary")
                    theme.accentText = get("on_primary")
                    theme.accent2 = get("tertiary")
                    theme.accent3 = get("secondary")
                    theme.outline = get("outline_variant")
                } catch (e) {
                    console.warn("drift: matugen output unreadable:", e)
                }
            }
        }
    }
}
