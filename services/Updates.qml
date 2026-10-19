pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Pending pacman + AUR updates. checkupdates uses its own db copy, so this
// never locks pacman. Hourly (3h in power saver).
Singleton {
    id: up
    property var repo: []        // [{ name, from, to }]
    property var aur: []
    property bool checking: false
    property date lastCheck
    readonly property int count: repo.length + aur.length

    function parse(lines) {
        return lines.filter(l => l.trim() !== "").map(l => {
            var f = l.trim().split(/\s+/)
            return { name: f[0], from: f[1] || "", to: f[3] || "" }
        })
    }
    function refresh() { if (!proc.running) { checking = true; proc.running = true } }
    // paru does the whole -Syu in a terminal; recheck once it closes
    function upgrade() {
        Quickshell.execDetached(["sh", "-c", "kitty --class drift-update -e sh -c 'paru -Syu; echo; read -p \"done - press enter to close \" _'; qs -c drift ipc call drift updatesRefresh"])
    }

    Process {
        id: proc
        command: ["sh", "-c", "checkupdates 2>/dev/null; echo @AUR; paru -Qua 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.split("@AUR")
                up.repo = up.parse((parts[0] || "").split("\n"))
                up.aur = up.parse((parts[1] || "").split("\n"))
                up.lastCheck = new Date()
                up.checking = false
            }
        }
    }
    Timer {
        interval: (System.lowPower ? 3 : 1) * 3600 * 1000
        running: true
        repeat: true
        onTriggered: up.refresh()
    }
    Timer { interval: 90 * 1000; running: true; onTriggered: up.refresh() }   // first check once the session settles
}
