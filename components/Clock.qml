import QtQuick
import Quickshell
import "../services"

// Rolling-digit clock with a breathing colon.
Row {
    id: clock
    property int pixelSize: 13
    readonly property date now: sys.date
    readonly property int hours: Config.opts.clock24h ? now.getHours() : ((now.getHours() + 11) % 12) + 1
    spacing: 0

    SystemClock {
        id: sys
        precision: Config.opts.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    component Colon: Text {
        text: ":"
        color: Theme.accent
        font.family: Theme.font
        font.pixelSize: clock.pixelSize
        renderType: Text.NativeRendering
        anchors.verticalCenter: parent.verticalCenter
        // hard terminal blink. A Timer, not a looping animation: a running
        // animation keeps the whole bar redrawing every frame, even while it pauses.
        property bool lit: true
        opacity: lit ? 1 : 0.2
        Timer {
            interval: 1000; repeat: true
            running: !Config.opts.showSeconds && !System.lowPower
            onTriggered: parent.lit = !parent.lit
            onRunningChanged: if (!running) parent.lit = true
        }
    }

    Digit { value: Math.floor(clock.hours / 10); pixelSize: clock.pixelSize }
    Digit { value: clock.hours % 10; pixelSize: clock.pixelSize }
    Colon {}
    Digit { value: Math.floor(clock.now.getMinutes() / 10); pixelSize: clock.pixelSize }
    Digit { value: clock.now.getMinutes() % 10; pixelSize: clock.pixelSize }
    Colon { visible: Config.opts.showSeconds }
    Digit { visible: Config.opts.showSeconds; value: Math.floor(clock.now.getSeconds() / 10); pixelSize: clock.pixelSize; color: Theme.dim }
    Digit { visible: Config.opts.showSeconds; value: clock.now.getSeconds() % 10; pixelSize: clock.pixelSize; color: Theme.dim }
    Text {
        visible: !Config.opts.clock24h
        leftPadding: 4
        anchors.verticalCenter: parent.verticalCenter
        text: clock.now.getHours() < 12 ? "AM" : "PM"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: Theme.fs
        renderType: Text.NativeRendering
    }
}
