pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Reads the live niri config so the cheatsheet always matches what's actually bound.
// Groups come from the `// #"Group Name"` comments above each block of binds;
// each bind needs a hotkey-overlay-title to show up (niri already wants those
// for its own overlay, so nothing extra to maintain).
Singleton {
    id: keybinds
    readonly property string path: Quickshell.env("HOME") + "/.config/niri/config.kdl"
    property var groups: []

    function parse(text) {
        var groups = [], cur = null
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            var header = line.match(/^\/\/\s*#"([^"]+)"/)
            if (header) { cur = { name: header[1], binds: [] }; groups.push(cur); continue }
            if (!cur || line.startsWith("//") || line === "") continue
            var bind = line.match(/^(\S+)\s+hotkey-overlay-title="([^"]+)"/)
            if (bind) cur.binds.push({ combo: bind[1].replace(/Mod/g, "Super").replace(/_/g, " "), title: bind[2] })
        }
        return groups.filter(g => g.binds.length > 0)
    }

    FileView {
        id: file
        path: keybinds.path
        watchChanges: true
        printErrors: false
        onLoaded: keybinds.groups = keybinds.parse(text())
        onFileChanged: reload()
    }
}
