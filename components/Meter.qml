import QtQuick
import "../services"

// Segmented gradient meter, btop style. Segments light up one by one as the
// value rises.
Row {
    id: meter
    property real value: 0               // 0..1
    property string ramp: "cpu"
    property int segments: 10
    property int segW: 3
    property int segH: 10

    property real shown: value
    Behavior on shown { enabled: !System.lowPower; NumberAnimation { duration: Theme.dur(500); easing.type: Easing.OutCubic } }

    spacing: 1
    Repeater {
        model: meter.segments
        Rectangle {
            required property int index
            readonly property bool lit: index < Math.round(meter.shown * meter.segments)
            width: meter.segW
            height: meter.segH
            color: lit ? Theme.ramp(meter.ramp, meter.segments > 1 ? index / (meter.segments - 1) : 1)
                       : Theme.alpha(Theme.dim, 0.16)
        }
    }
}
