import QtQuick
import Quickshell
import Quickshell.Wayland
import "services"
import "components"

// Volume / mic / brightness pop-up near the bottom of the focused screen.
// Click-through; the shell hides it after a moment.
PanelWindow {
    id: osd
    property string kind: "volume"          // volume | mic | brightness

    screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) || Quickshell.screens[0]
    anchors.bottom: true
    margins.bottom: 70
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "drift-osd"
    implicitWidth: 330
    implicitHeight: 62          // room above the box for its border title
    color: "transparent"
    mask: Region {}

    readonly property bool muted: kind === "volume" ? System.muted : kind === "mic" ? System.micMuted : false
    readonly property real value: kind === "volume" ? System.volume : kind === "mic" ? System.micVolume : System.brightness
    readonly property string ramp: kind === "volume" ? "mem" : kind === "mic" ? "temp" : "gpu"
    readonly property string icon: kind === "volume" ? System.volumeIcon : kind === "mic" ? (System.micMuted ? "mic-off" : "mic") : "brightness"

    PixelBox {
        id: box
        width: parent.width
        height: 52
        step: 3
        fill: Theme.alpha(Theme.surface, 0.96)
        stroke: Theme.hue(osd.ramp)
        title: osd.kind
        titleColor: Theme.hue(osd.ramp)
        // stepped drop-in
        y: 10
        Component.onCompleted: pop.start()
        SequentialAnimation {
            id: pop
            PropertyAction { target: box; property: "y"; value: 18 }
            PropertyAction { target: box; property: "opacity"; value: 0.4 }
            PauseAnimation { duration: 40 }
            PropertyAction { target: box; property: "y"; value: 13 }
            PropertyAction { target: box; property: "opacity"; value: 1 }
            PauseAnimation { duration: 40 }
            PropertyAction { target: box; property: "y"; value: 10 }
        }

        Row {
            anchors.centerIn: parent
            spacing: 12
            Icon { name: osd.icon; size: 20; color: osd.muted ? Theme.dim : Theme.hue(osd.ramp); anchors.verticalCenter: parent.verticalCenter }
            Meter {
                anchors.verticalCenter: parent.verticalCenter
                value: osd.muted ? 0 : osd.value
                ramp: osd.ramp
                segments: 40; segW: 4; segH: 12
            }
            Label {
                width: 40
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: osd.muted ? "mute" : Math.round(osd.value * 100) + "%"
                color: osd.muted ? Theme.dim : Theme.hue(osd.ramp)
                font.bold: true
            }
        }
    }
}
