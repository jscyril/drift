pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

// What's watching or listening: mic capture streams and niri screencasts come
// from PipeWire; cameras are often opened directly, so /dev/video* is checked too.
Singleton {
    id: pv
    readonly property var nodes: Pipewire.nodes.values
    // capture streams, minus drift's own level meters
    readonly property var micApps: nodes.filter(n => n.type === PwNodeType.AudioInStream && !/quickshell|drift/i.test(n.name + n.description))
        .map(n => n.description || n.name)
    readonly property bool mic: micApps.length > 0
    readonly property bool screen: nodes.some(n => n.type === PwNodeType.VideoSource && /niri|xdg|portal/i.test(n.name))
    property bool camera: false

    Process {
        id: cam
        command: ["sh", "-c", "fuser -s /dev/video* 2>/dev/null"]
        onExited: code => pv.camera = code === 0
    }
    Timer {
        interval: System.lowPower ? 15000 : 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: cam.running = true
    }
}
