pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// One scratchpad of text, saved to ~/.config/drift/notes.txt as you type.
Singleton {
    id: notes
    property string text: ""
    readonly property int lines: text.trim() === "" ? 0 : text.trim().split("\n").length

    function save(t) { text = t; file.setText(t) }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/drift/notes.txt"
        printErrors: false
        onLoaded: notes.text = text()
    }
}
