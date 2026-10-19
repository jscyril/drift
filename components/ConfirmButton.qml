import QtQuick
import "../services"

// Destructive session action: first click arms (turns tertiary), second runs.
RoundButton {
    id: cb
    property string command
    danger: armed.running
    onClicked: {
        if (armed.running) { armed.stop(); System.run(cb.command) }
        else armed.start()
    }
    Timer { id: armed; interval: 2500 }
}
