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
            property string colorMode: "wallpaper"        // "wallpaper" | "custom"
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
            property int popupSeconds: 5
            property string launcherCommand: "vicinae toggle"
            // wallpaper
            property string wallpaperDir: "~/Pictures/Wallpapers"
            property int wallpaperMinutes: 0               // rotate every N minutes, 0 = off
            property bool wallpaperShuffle: true
        }
    }

    Timer { id: firstWrite; interval: 300; onTriggered: file.writeAdapter() }
}
