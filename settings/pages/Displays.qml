import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"
import "../../components"

// Monitors through niri IPC. Changes apply right away but last only until
// niri restarts; "copy as kdl" gives the block to paste into niri's config.
Column {
    id: pg
    spacing: 18

    property var outputs: []
    property string selName: ""
    readonly property var sel: outputs.find(o => o.name === selName) || outputs[0] || null
    readonly property var live: outputs.filter(o => o.logical)

    function refresh() { if (!proc.running) proc.running = true }
    Process {
        id: proc
        running: true
        command: ["niri", "msg", "-j", "outputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var j = JSON.parse(this.text)
                    pg.outputs = (Array.isArray(j) ? j : Object.values(j)).sort((a, b) => (a.logical ? a.logical.x : 1e9) - (b.logical ? b.logical.x : 1e9))
                } catch (e) {}
            }
        }
    }
    function set() {
        var args = ["niri", "msg", "output", sel.name].concat(Array.from(arguments).map(String))
        Quickshell.execDetached(args)
        later.restart()
    }
    Timer { id: later; interval: 400; onTriggered: pg.refresh() }

    function rate(mhz) { return (mhz / 1000).toFixed(3) }
    function modeStr(m) { return !m ? "" : m.width + "x" + m.height + "@" + rate(m.refresh_rate) }
    readonly property var curMode: sel && sel.current_mode !== null ? sel.modes[sel.current_mode] : null
    readonly property string rot: sel && sel.logical ? sel.logical.transform.toLowerCase().replace(/^_/, "").replace(/^flipped_?(\d+)/, "flipped-$1") : "normal"
    readonly property string kdl: !sel || !sel.logical || !curMode ? "" :
        'output "' + sel.name + '" {\n    mode "' + modeStr(curMode) + '"\n    scale ' + sel.logical.scale
        + '\n    transform "' + rot + '"\n    position x=' + sel.logical.x + ' y=' + sel.logical.y + '\n}'

    // ── layout map ──
    Section {
        title: "layout"
        badge: pg.outputs.length + " connected"
        hue: Theme.hue("cpu")
        Item {
            id: map
            width: parent.width
            height: 170
            readonly property var box: {
                var r = { x0: 1e9, y0: 1e9, x1: -1e9, y1: -1e9 }
                pg.live.forEach(o => { var l = o.logical; r.x0 = Math.min(r.x0, l.x); r.y0 = Math.min(r.y0, l.y); r.x1 = Math.max(r.x1, l.x + l.width); r.y1 = Math.max(r.y1, l.y + l.height) })
                return r
            }
            readonly property real k: pg.live.length ? Math.min((width - 20) / (box.x1 - box.x0), (height - 20) / (box.y1 - box.y0)) : 1
            readonly property real ox: (width - (box.x1 - box.x0) * k) / 2
            readonly property real oy: (height - (box.y1 - box.y0) * k) / 2

            Repeater {
                model: pg.live
                Item {
                    id: scr
                    required property var modelData
                    required property int index
                    readonly property bool picked: pg.sel && pg.sel.name === modelData.name
                    x: map.ox + (modelData.logical.x - map.box.x0) * map.k + 3
                    y: map.oy + (modelData.logical.y - map.box.y0) * map.k + 3
                    width: modelData.logical.width * map.k - 6
                    height: modelData.logical.height * map.k - 6
                    PixelBox {
                        anchors.fill: parent
                        step: 3
                        fill: scr.picked ? Theme.alpha(Theme.hue("cpu"), 0.22) : smma.containsMouse ? Theme.alpha(Theme.fg, 0.06) : Theme.alpha(Theme.fg, 0.03)
                        stroke: scr.picked ? Theme.hue("cpu") : Theme.alpha(Theme.dim, 0.5)
                    }
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: String(scr.index + 1); font.pixelSize: Theme.fsBig * 2; color: scr.picked ? Theme.hue("cpu") : Theme.dim }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: scr.modelData.name; font.bold: true }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: scr.modelData.logical.width + "x" + scr.modelData.logical.height; color: Theme.dim }
                    }
                    MouseArea { id: smma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pg.selName = scr.modelData.name }
                }
            }
        }
        // off outputs can't sit on the map
        Row {
            spacing: 6
            Repeater {
                model: pg.outputs.filter(o => !o.logical)
                Chip { required property var modelData; text: modelData.name + " (off)"; on: pg.sel && pg.sel.name === modelData.name; onClicked: pg.selName = modelData.name }
            }
        }
    }

    Section {
        visible: !!pg.sel
        title: pg.sel ? pg.sel.name : ""
        badge: pg.sel ? (pg.sel.make + " " + pg.sel.model).slice(0, 40) : ""
        hue: Theme.hue("cpu")

        Setting {
            title: "enabled"
            hint: pg.live.length === 1 && pg.sel && pg.sel.logical ? "can't turn off the last screen" : ""
            Switch {
                checked: !!(pg.sel && pg.sel.logical)
                enabled: !(pg.live.length === 1 && pg.sel && pg.sel.logical)
                onToggled: v => pg.set(v ? "on" : "off")
            }
        }
        Setting {
            visible: !!pg.curMode
            title: "resolution & refresh"
            below: true
            Flow {
                width: parent.width
                spacing: 6
                Repeater {
                    // keep the best few modes, preferred first
                    model: pg.sel ? pg.sel.modes.map((m, i) => ({ m: m, i: i }))
                        .filter((e, i, a) => a.findIndex(o => o.m.width === e.m.width && o.m.height === e.m.height && Math.round(o.m.refresh_rate / 1000) === Math.round(e.m.refresh_rate / 1000)) === i)
                        : []
                    Chip {
                        required property var modelData
                        text: modelData.m.width + "x" + modelData.m.height + " " + Math.round(modelData.m.refresh_rate / 1000) + "hz" + (modelData.m.is_preferred ? " *" : "")
                        on: pg.sel.current_mode === modelData.i
                        onClicked: pg.set("mode", pg.modeStr(modelData.m))
                    }
                }
            }
        }
        Setting {
            visible: !!pg.sel && !!pg.sel.logical
            title: "scale"
            Segmented {
                options: [1, 1.25, 1.5, 1.75, 2].map(v => ({ label: v + "x", value: v }))
                value: pg.sel && pg.sel.logical ? pg.sel.logical.scale : 1
                onPicked: v => pg.set("scale", v)
            }
        }
        Setting {
            visible: !!pg.sel && !!pg.sel.logical
            title: "rotation"
            Segmented {
                options: [{ label: "0°", value: "normal" }, { label: "90°", value: "90" }, { label: "180°", value: "180" }, { label: "270°", value: "270" }]
                value: pg.rot
                onPicked: v => pg.set("transform", v)
            }
        }
        Setting {
            visible: !!pg.sel && pg.sel.vrr_supported
            title: "variable refresh rate"
            Switch { checked: !!pg.sel && pg.sel.vrr_enabled; onToggled: v => pg.set("vrr", v ? "on" : "off") }
        }
        Setting {
            visible: pg.sel && pg.sel.name.indexOf("eDP") === 0 && System.hasBacklight
            title: "brightness"
            below: true
            MiniSlider {
                width: parent.width
                from: 0.02; to: 1; step: 0.01
                value: System.brightness
                ramp: "temp"
                format: v => Math.round(v * 100) + "%"
                onMoved: v => System.setBrightness(v)
            }
        }
        Row {
            visible: pg.kdl !== ""
            spacing: 8
            Chip { text: "copy as kdl"; icon: "pencil"; onClicked: Quickshell.execDetached(["wl-copy", pg.kdl]) }
            Label { width: parent.parent.width - 130; wrapMode: Text.Wrap; anchors.verticalCenter: parent.verticalCenter; text: "changes last until niri restarts. paste this into config.kdl to keep them"; color: Theme.dim }
        }
    }

    Section {
        title: "night light"
        hue: Theme.hue("temp")
        Setting {
            title: "warm the screen"
            hint: "uses noctalia's night light"
            Chip { text: "toggle"; icon: "weather-night"; onClicked: Quickshell.execDetached(["noctalia", "msg", "nightlight-force-toggle"]) }
        }
    }
}
