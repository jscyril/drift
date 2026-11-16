pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// User settings, persisted to ~/.config/drift/config.json.
// Edit from the settings panel or by hand; both apply live.
Singleton {
    id: config
    readonly property alias opts: adapter
    readonly property string path: Quickshell.env("HOME") + "/.config/drift/config.json"

    function reset() {
        Quickshell.execDetached(["rm", "-f", path])
        Qt.callLater(() => Quickshell.reload(false))
    }

    FileView {
        id: file
        path: config.path
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.config/drift"])
                firstWrite.start()
            }
        }

        JsonAdapter {
            id: adapter
            // look
            property string colorMode: "wallpaper"        // "wallpaper" | "custom" | "theme"
            property string themeName: "catppuccin"       // preset used when colorMode is "theme" (services/themes.js)
            property bool themeApps: false                // also write the palette to kitty and GTK
            property string customAccent: "#8aa4c8"
            property string scheme: "scheme-vibrant"      // matugen scheme type
            property string meterColors: "neon"           // "neon" | "wallpaper"
            property real barOpacity: 0.88
            property bool scanlines: true
            property real animSpeed: 1.0                  // >1 faster, <1 slower
            property string powerSaver: "auto"            // "auto" (on battery) | "on" | "off"
            // bar
            property int barHeight: 28
            property int barMargin: 4
            property int workspaceCount: 5
            property bool showCpu: true
            property bool showMem: true
            property bool showTemp: true
            property bool showGpu: true
            property bool showNet: true
            property bool showScreenTime: true
            property bool showGithub: true
            property bool showMedia: true
            property bool showTodo: true
            property bool showNotes: true
            property bool todoGoogle: false               // sync the to-do list with Google Tasks
            property string todoSort: "order"             // "order" | "date"
            property bool todoNotify: true                // reminders for timed tasks + a 09:00 summary
            // time & weather
            property bool clock24h: true
            property bool showSeconds: false
            property bool weather: true
            property string weatherLocation: ""            // empty = detect from IP
            property bool fahrenheit: false
            // data
            property string githubUser: ""                 // public GitHub profile for the heatmap
            property int idleMinutes: 3                    // screen time pauses after this
            // behavior
            property bool notifPopups: true
            property bool dndSchedule: false               // do not disturb by the clock
            property string dndFrom: "22:00"
            property string dndTo: "08:00"
            property bool lowBatteryWarn: true             // a notification at 20, 10 and 5%
            property string aiProvider: "claude"           // search overlay: "claude" | "chatgpt" | "gemini"
            property string terminalCommand: "kitty"       // desktop menu
            property int popupSeconds: 5
            property string launcherCommand: "vicinae toggle"
            // wallpaper
            property string wallpaperDir: "~/Pictures/Wallpapers"
            property int wallpaperMinutes: 0               // rotate every N minutes, 0 = off
            property bool wallpaperShuffle: true
            // night light (gammastep)
            property bool nightLight: false
            property int nightTemp: 4000                   // kelvin
            property bool nightSchedule: false             // switch on and off by the clock
            property string nightFrom: "20:00"
            property string nightTo: "07:00"
        }
    }

    Timer { id: firstWrite; interval: 300; onTriggered: file.writeAdapter() }
}
