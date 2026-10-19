import QtQuick
import "../services"

// Destructive session action: first click arms (turns tertiary), second runs.
RoundButton {
    id: cb
    property string command
    property var fn: null             // run this instead of a shell command
    danger: armed.running
    onClicked: {
        if (armed.running) { armed.stop(); if (cb.fn) cb.fn(); else System.run(cb.command) }
        else armed.start()
    }
    Timer { id: armed; interval: 2500 }
}
