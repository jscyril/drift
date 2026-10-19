pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Screenshots (grim/slurp, niri for windows) and recordings (gpu-screen-recorder).
// Shots go to ~/Pictures/Screenshots and the clipboard; recordings to ~/Videos.
Singleton {
    id: cap
    property bool edit: false            // open shots in swappy first
    property bool audio: true            // record desktop audio
    property int delay: 0                // seconds before a shot
    readonly property bool recording: rec.running
    property real recStart: 0
    property int recSecs: 0

    readonly property string shotDir: Quickshell.env("HOME") + "/Pictures/Screenshots"
    readonly property string vidDir: Quickshell.env("HOME") + "/Videos"
    function stamp() { return Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") }

    // mode: region | screen | window
    function shot(mode) {
        if (mode === "window") {
            // niri knows window geometry; it saves to its screenshot-path and copies
            Quickshell.execDetached(["sh", "-c", "sleep " + (0.3 + delay) + "; niri msg action screenshot-window"])
            return
        }
        var f = shotDir + "/shot_" + stamp() + ".png"
        var grab = mode === "region"
            ? 'g=$(slurp -d) || exit 0; sleep "$D"; grim -g "$g" "$F"'
            : 'sleep "$D"; grim -o "$(niri msg -j focused-output | jq -r .name)" "$F"'
        var post = (edit ? 'swappy -f "$F" -o "$F"; ' : '')
            + '[ -f "$F" ] && wl-copy < "$F" && notify-send -a drift -i "$F" "screenshot" "saved and copied"'
        // pass F and D through the environment
        Quickshell.execDetached(["env", "F=" + f, "D=" + delay, "sh", "-c", 'mkdir -p "$(dirname "$F")"; sleep 0.3; ' + grab + '; ' + post])
    }

    property string recFile: ""
    function record(mode) {
        if (rec.running) { stop(); return }
        recFile = vidDir + "/rec_" + stamp() + ".mp4"
        var a = audio ? ' -a default_output' : ''
        var target = mode === "region"
            ? 'g=$(slurp -f "%wx%h+%x+%y") || exit 0; set -- -w region -region "$g"'
            : 'set -- -w "$(niri msg -j focused-output | jq -r .name)"'
        rec.command = ["env", "F=" + recFile, "sh", "-c",
            'mkdir -p "$(dirname "$F")"; sleep 0.3; ' + target + '; exec gpu-screen-recorder "$@" -f 60 -k h264' + a + ' -o "$F"']
        rec.running = true
    }
    function stop() { Quickshell.execDetached(["pkill", "-INT", "-x", "gpu-screen-recorder"]) }

    Process {
        id: rec
        onRunningChanged: if (running) { cap.recStart = Date.now(); cap.recSecs = 0 }
        stderr: StdioCollector { id: recErr }
        onExited: code => {
            // saved file -> say so; nothing written and an error -> show it; cancelled selection -> silent
            Quickshell.execDetached(["sh", "-c", 'if [ -s "$1" ]; then notify-send -a drift "recording saved" "$1"; elif [ "$3" != 0 ]; then notify-send -a drift "recording failed" "$2"; fi',
                "sh", cap.recFile, recErr.text.trim().split("\n").pop() || "", String(code)])
        }
    }
    Timer { interval: 1000; running: rec.running; repeat: true; onTriggered: cap.recSecs = Math.round((Date.now() - cap.recStart) / 1000) }
}
