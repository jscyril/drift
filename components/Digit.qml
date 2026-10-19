import QtQuick
import "../services"

// A digit on a vertical reel: changing value rolls it into place.
Item {
    id: d
    property int value: 0
    property color color: Theme.fg
    property int pixelSize: 13
    property int weight: Font.DemiBold

    width: probe.implicitWidth
    height: probe.implicitHeight
    clip: true

    Text {
        id: probe
        visible: false
        text: "0"
        font.family: Theme.font
        font.pixelSize: d.pixelSize
        font.weight: d.weight
        font.features: { "tnum": 1 }
    }
    // reel text renders unsmoothed like the rest of the pixel UI

    Column {
        y: -d.value * d.height
        Behavior on y { NumberAnimation { duration: Theme.dur(560); easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
        Repeater {
            model: 10
            Text {
                required property int index
                height: d.height
                text: index
                color: d.color
                font: probe.font
                renderType: Text.NativeRendering
            }
        }
    }
}
