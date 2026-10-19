import QtQuick
import "../services"

// Pixel battery: outline with a nub, block cells inside; cells chase while charging.
Row {
    id: bp
    spacing: 5

    readonly property int cells: 5
    readonly property int lit: Math.ceil(System.batteryPct / 100 * cells)
    readonly property color hue: !System.charging && System.batteryPct <= 15 ? Theme.ramp("temp", 1) : Theme.ramp("cpu", System.batteryPct / 100 * 0.3)
    property int chase: 0

    Timer {
        interval: 350
        running: System.charging
        repeat: true
        onTriggered: bp.chase = (bp.chase + 1) % (bp.cells + 1)
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        Item {
            width: bp.cells * 4 + 5
            height: 10
            PixelBox { anchors.fill: parent; step: 1; fill: "transparent"; stroke: Theme.alpha(Theme.fg, 0.6) }
            Row {
                x: 2; y: 2
                spacing: 1
                Repeater {
                    model: bp.cells
                    Rectangle {
                        required property int index
                        width: 3; height: 6
                        color: (System.charging ? index < Math.max(bp.lit, bp.chase) : index < bp.lit) ? bp.hue : "transparent"
                    }
                }
            }
        }
        Rectangle { width: 2; height: 4; anchors.verticalCenter: parent.verticalCenter; color: Theme.alpha(Theme.fg, 0.6) }
    }
    Label {
        anchors.verticalCenter: parent.verticalCenter
        text: System.batteryPct + "%"
        color: bp.hue
    }
}
