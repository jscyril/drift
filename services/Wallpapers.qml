pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The wallpaper library (Config.wallpaperDir) and the rotation timer.
// Setting a wallpaper goes through Theme.setWallpaper, so colors follow.
Singleton {
    id: wp
    readonly property string dir: Config.opts.wallpaperDir.replace(/^~/, Quickshell.env("HOME"))
    property var files: []

    function rescan() { ls.running = false; ls.running = true }
    onDirChanged: rescan()
    Process {
        id: ls
        running: true
        command: ["find", "-L", wp.dir, "-maxdepth", "2", "-type", "f", "(", "-iname", "*.png", "-o", "-iname", "*.jpg",
                  "-o", "-iname", "*.jpeg", "-o", "-iname", "*.webp", ")"]
        stdout: StdioCollector { onStreamFinished: wp.files = this.text.split("\n").filter(l => l !== "").sort() }
    }

    // a manual pick restarts the countdown
    function set(path) { Theme.setWallpaper(path); rotate.restart() }
    function step(d) {
        if (!files.length) return
        var i = files.indexOf(Theme.wallpaper)
        Theme.setWallpaper(files[(i + d + files.length) % files.length])
        rotate.restart()
    }
    function random() {
        if (files.length < 2) return step(1)
        var pick
        do { pick = files[Math.floor(Math.random() * files.length)] } while (pick === Theme.wallpaper)
        Theme.setWallpaper(pick)
        rotate.restart()
    }

    // rotation: every N minutes (0 = off), shuffled or in folder order
    Timer {
        id: rotate
        interval: Math.max(1, Config.opts.wallpaperMinutes) * 60 * 1000
        running: Config.opts.wallpaperMinutes > 0
        repeat: true
        onTriggered: { wp.rescan(); Config.opts.wallpaperShuffle ? wp.random() : wp.step(1) }
    }
}
