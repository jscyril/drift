import QtQuick
import "../services"
import "../components"

// btop-style dashboard: cpu, memory, network, sensors, processes, disks.
Column {
    id: card
    width: 740
    spacing: 14

    readonly property int boxPad: 12

    component Box: PixelBox {
        step: 2
        fill: Theme.alpha(Theme.fg, 0.025)
        stroke: Theme.alpha(titleColor, 0.55)
    }

    // ── cpu ──
    Box {
        width: card.width
        height: 168
        title: "cpu"
        titleColor: Theme.hue("cpu")
        badge: "load " + Stats.load

        Row {
            x: card.boxPad; y: card.boxPad + 2
            spacing: 14
            Column {
                spacing: 4
                Label {
                    text: Math.round(Stats.cpu * 100) + "%"
                    font.pixelSize: Theme.fsBig
                    color: Theme.ramp("cpu", Stats.cpu)
                }
                Graph {
                    width: 330; height: 100
                    values: Stats.cpuHistory
                    ramp: "cpu"
                    cell: 5; gap: 1
                    dimEmpty: true
                }
            }
            // per-core meters
            Grid {
                columns: 2
                columnSpacing: 18
                rowSpacing: 4
                Repeater {
                    model: Stats.cores
                    Row {
                        required property var modelData
                        required property int index
                        spacing: 6
                        Label { text: "c" + String(index).padStart(2, "0"); color: Theme.dim; width: 24 }
                        Meter { value: modelData; ramp: "cpu"; segments: 14; segW: 4; segH: 9; anchors.verticalCenter: parent.verticalCenter }
                        Num { text: String(Math.round(modelData * 100)).padStart(3, " ") + "%"; width: 30; color: Theme.ramp("cpu", modelData) }
                    }
                }
            }
        }
    }

    Row {
        spacing: 14

        // ── memory ──
        Box {
            width: 236; height: 132
            title: "mem"
            titleColor: Theme.hue("mem")
            badge: Theme.bytes(Stats.memTotal)
            Column {
                x: card.boxPad; y: card.boxPad + 2
                spacing: 6
                Row {
                    spacing: 6
                    Label { text: "used"; color: Theme.dim; width: 34 }
                    Meter { value: Stats.mem; ramp: "mem"; segments: 20; segW: 5; segH: 10; anchors.verticalCenter: parent.verticalCenter }
                }
                Label { text: Theme.bytes(Stats.memUsed) + " · " + Math.round(Stats.mem * 100) + "%"; color: Theme.ramp("mem", Stats.mem) }
                Row {
                    spacing: 6
                    Label { text: "swap"; color: Theme.dim; width: 34 }
                    Meter { value: Stats.swapTotal > 0 ? Stats.swapUsed / Stats.swapTotal : 0; ramp: "mem"; segments: 20; segW: 5; segH: 10; anchors.verticalCenter: parent.verticalCenter }
                }
                Graph { width: 210; height: 30; values: Stats.memHistory; ramp: "mem"; cell: 3 }
            }
        }

        // ── network ──
        Box {
            width: 236; height: 132
            title: "net"
            titleColor: Theme.hue("down")
            badge: "peak " + Theme.bytes(Stats.netPeak) + "/s"
            Column {
                x: card.boxPad; y: card.boxPad + 2
                spacing: 2
                Label { text: "↓ " + Theme.bytes(Stats.rxRate) + "/s"; color: Theme.hue("down") }
                Graph { width: 210; height: 36; values: Stats.rxHistory; max: Stats.netPeak; ramp: "down"; cell: 3 }
                Graph { width: 210; height: 36; values: Stats.txHistory; max: Stats.netPeak; ramp: "up"; cell: 3; mirror: true }
                Label { text: "↑ " + Theme.bytes(Stats.txRate) + "/s"; color: Theme.hue("up") }
            }
        }

        // ── sensors ──
        Box {
            width: 240; height: 132
            title: "sensors"
            titleColor: Theme.hue("temp")
            badge: "up " + Theme.duration(Stats.uptime)
            Column {
                x: card.boxPad; y: card.boxPad + 2
                spacing: 6
                Row {
                    spacing: 6
                    Label { text: "cpu°"; color: Theme.dim; width: 34 }
                    Meter { value: Stats.tempC / 100; ramp: "temp"; segments: 16; segW: 5; segH: 10; anchors.verticalCenter: parent.verticalCenter }
                    Num { text: Math.round(Stats.tempC) + "°"; color: Theme.ramp("temp", Stats.tempC / 100) }
                }
                Graph { width: 216; height: 26; values: Stats.tempHistory; ramp: "temp"; cell: 3 }
                Row {
                    spacing: 6
                    Label { text: "igpu"; color: Theme.dim; width: 34 }
                    Meter { value: Stats.gpu; ramp: "gpu"; segments: 16; segW: 5; segH: 10; anchors.verticalCenter: parent.verticalCenter }
                    Num { text: Math.round(Stats.gpu * 100) + "%"; color: Theme.ramp("gpu", Stats.gpu) }
                }
                Graph { width: 216; height: 20; values: Stats.gpuHistory; ramp: "gpu"; cell: 3 }
            }
        }
    }

    Row {
        spacing: 14

        // ── processes ──
        Box {
            width: 470; height: 200
            title: "proc"
            titleColor: Theme.accent
            badge: "by cpu"
            Column {
                x: card.boxPad; y: card.boxPad + 2
                width: parent.width - 2 * card.boxPad
                spacing: 3
                Row {
                    spacing: 0
                    Label { text: "pid"; width: 56; color: Theme.dim }
                    Label { text: "name"; width: 170; color: Theme.dim }
                    Label { text: "cpu"; width: 110; color: Theme.dim }
                    Label { text: "mem"; width: 60; color: Theme.dim }
                }
                Repeater {
                    model: Stats.procs
                    Item {
                        required property var modelData
                        width: parent.width; height: 18
                        Rectangle { anchors.fill: parent; color: rowMa.containsMouse ? Theme.alpha(Theme.accent, 0.10) : "transparent" }
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            Label { text: modelData.pid; width: 56; color: Theme.dim }
                            Label { text: modelData.name; width: 170 }
                            Row {
                                width: 110; spacing: 4
                                Meter { value: Math.min(1, modelData.cpu / 100); ramp: "cpu"; segments: 10; segW: 3; segH: 8; anchors.verticalCenter: parent.verticalCenter }
                                Num { text: modelData.cpu.toFixed(1); color: Theme.ramp("cpu", modelData.cpu / 100) }
                            }
                            Label { text: modelData.mem.toFixed(1) + "%"; width: 60; color: Theme.hue("mem") }
                        }
                        Label {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            visible: rowMa.containsMouse
                            text: "[kill]"
                            color: Theme.ramp("temp", 1)
                        }
                        MouseArea {
                            id: rowMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Stats.kill(modelData.pid)
                        }
                    }
                }
            }
        }

        // ── disks ──
        Box {
            width: 256; height: 200
            title: "disks"
            titleColor: Theme.hue("gpu")
            Column {
                x: card.boxPad; y: card.boxPad + 2
                spacing: 10
                Repeater {
                    model: Stats.disks.slice(0, 5)
                    Column {
                        required property var modelData
                        spacing: 3
                        Row {
                            spacing: 6
                            Label { text: modelData.mount; width: 120; elide: Text.ElideMiddle }
                            Label { text: Theme.bytes(modelData.used) + "/" + Theme.bytes(modelData.size); color: Theme.dim }
                        }
                        Meter { value: modelData.used / modelData.size; ramp: "gpu"; segments: 30; segW: 6; segH: 8 }
                    }
                }
            }
        }
    }
}
