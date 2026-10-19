import QtQuick
import "../services"

// Three bouncing bars while music plays; flat when paused.
Row {
    id: eq
    property bool playing: false
    spacing: 2
    height: 12

    Repeater {
        model: 3
        Rectangle {
            required property int index
            width: 3
            anchors.bottom: parent.bottom
            color: Theme.ramp("time", index / 2)
            height: 3
            SequentialAnimation on height {
                running: eq.playing && !System.lowPower
                loops: Animation.Infinite
                NumberAnimation { to: 12; duration: 300 + index * 110; easing.type: Easing.InOutSine }
                NumberAnimation { to: 4; duration: 260 + index * 90; easing.type: Easing.InOutSine }
            }
            Behavior on height { enabled: !eq.playing; NumberAnimation { duration: 200 } }
            Connections {
                target: eq
                function onPlayingChanged() { if (!eq.playing) height = 3 }
            }
            // power saver: a still "playing" shape instead of bouncing
            Connections {
                target: System
                function onLowPowerChanged() { if (System.lowPower) height = eq.playing ? [9, 12, 6][index] : 3 }
            }
        }
    }
}
