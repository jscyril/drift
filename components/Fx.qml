import QtQuick
import "../services"

// Bar effects: faint CRT scanlines, a scan beam that sweeps every so often,
// and a pixel comet (sweep()) for new notifications.
Item {
    id: fx
    anchors.fill: parent
    clip: true

    function sweep() { comet.restart() }

    // scanlines
    Column {
        visible: Config.opts.scanlines
        Repeater {
            model: Math.ceil(fx.height / 2)
            Rectangle { width: fx.width; height: 2; color: index % 2 ? "transparent" : Theme.alpha("#000000", 0.10); required property int index }
        }
    }

    // slow beam
    Rectangle {
        id: beam
        visible: Config.opts.scanlines && !System.lowPower
        width: 3
        height: fx.height
        x: -10
        color: Theme.alpha(Theme.accent, 0.35)
        SequentialAnimation on x {
            running: Config.opts.scanlines && fx.width > 0 && !System.lowPower
            loops: Animation.Infinite
            PauseAnimation { duration: 9000 }
            NumberAnimation { from: -10; to: fx.width + 10; duration: 4500; easing.type: Easing.InOutQuad }
        }
    }

    // comet: a head with a trail of fading pixel blocks
    Row {
        id: tail
        x: -width
        anchors.verticalCenter: parent.verticalCenter
        opacity: 0
        spacing: 2
        Repeater {
            model: 12
            Rectangle {
                required property int index
                width: 4; height: 4
                color: Theme.ramp("time", index / 11)
                opacity: (index + 1) / 12
            }
        }
    }
    SequentialAnimation {
        id: comet
        PropertyAction { target: tail; property: "opacity"; value: 1 }
        NumberAnimation { target: tail; property: "x"; from: -tail.width; to: fx.width; duration: Theme.dur(1100); easing.type: Easing.InOutQuad }
        PropertyAction { target: tail; property: "opacity"; value: 0 }
    }
}
