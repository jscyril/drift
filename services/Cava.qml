pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Live audio levels from cava for the media card's visualizer.
// Only runs while something wants it and music is playing.
Singleton {
    id: cava
    property bool wanted: false
    readonly property int bars: 32
    readonly property int range: 8           // each bar is 0..range
    property var levels: []

    Process {
        id: proc
        running: cava.wanted && !System.lowPower && !!System.player && System.player.isPlaying
        command: ["sh", "-c", "exec cava -p /dev/stdin <<EOF\n[general]\nbars = " + cava.bars + "\nframerate = 30\n[output]\nmethod = raw\n"
            + "raw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = " + cava.range + "\nEOF"]
        stdout: SplitParser { onRead: l => cava.levels = l.split(";").slice(0, cava.bars).map(Number) }
        onRunningChanged: if (!running) cava.levels = []
    }
}
