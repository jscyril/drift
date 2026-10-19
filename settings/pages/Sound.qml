import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "../../services"
import "../../components"

Column {
    id: pg
    spacing: 18

    readonly property var nodes: Pipewire.nodes.values.filter(n => n.audio)
    readonly property var outputs: nodes.filter(n => n.isSink && !n.isStream)
    readonly property var inputs: nodes.filter(n => !n.isSink && !n.isStream)
    readonly property var apps: nodes.filter(n => n.isSink && n.isStream)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    PwObjectTracker { objects: pg.nodes }

    function nodeName(n) { return n.description || n.nickname || n.name }

    // master volume + live level for one default node
    component Master: Column {
        id: m
        property var node
        property string ramp
        property string label
        width: parent.width
        spacing: 8
        PwNodePeakMonitor { id: peak; node: m.node; enabled: !!m.node }
        Row {
            spacing: 10
            RoundButton {
                icon: !m.node || m.node.audio.muted ? (m.label === "input" ? "mic" : "volume-off") : (m.label === "input" ? "mic" : "volume-high")
                filled: !!m.node && !m.node.audio.muted
                hue: Theme.hue(m.ramp)
                onClicked: if (m.node) m.node.audio.muted = !m.node.audio.muted
            }
            MiniSlider {
                width: m.width - 38
                anchors.verticalCenter: parent.verticalCenter
                from: 0; to: 1.5; step: 0.01
                value: m.node ? m.node.audio.volume : 0
                ramp: m.ramp
                format: v => Math.round(v * 100) + "%"
                onMoved: v => { if (m.node) { m.node.audio.muted = false; m.node.audio.volume = v } }
            }
        }
        // the level, bouncing live
        Row {
            spacing: 10
            Label { width: 28; text: "lvl"; color: Theme.dim }
            Meter {
                anchors.verticalCenter: parent.verticalCenter
                value: m.node && !m.node.audio.muted ? Math.min(1, peak.peak) : 0
                ramp: m.ramp
                segments: Math.max(1, Math.floor((m.width - 94) / 5))
                segW: 4; segH: 6
            }
        }
    }

    component DeviceList: Column {
        id: dl
        property var list
        property var current
        property string ramp
        property bool isOut
        width: parent.width
        spacing: 4
        Repeater {
            model: dl.list
            Item {
                id: dev
                required property var modelData
                readonly property bool sel: dl.current === modelData
                width: dl.width
                height: 30
                PixelBox {
                    anchors.fill: parent
                    step: 2
                    fill: dev.sel ? Theme.alpha(Theme.hue(dl.ramp), 0.16) : dma.containsMouse ? Theme.alpha(Theme.fg, 0.05) : "transparent"
                    stroke: dev.sel ? Theme.hue(dl.ramp) : Theme.alpha(Theme.dim, 0.18)
                }
                Row {
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10
                    Label { text: dev.sel ? "(*)" : "( )"; color: dev.sel ? Theme.hue(dl.ramp) : Theme.dim }
                    Label { width: dl.width - 60; text: dev.modelData.description || dev.modelData.nickname || dev.modelData.name; font.bold: dev.sel }
                }
                MouseArea {
                    id: dma
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (dl.isOut) Pipewire.preferredDefaultAudioSink = dev.modelData
                        else Pipewire.preferredDefaultAudioSource = dev.modelData
                    }
                }
            }
        }
    }

    Section {
        title: "output"
        badge: pg.sink ? pg.nodeName(pg.sink) : "none"
        hue: Theme.hue("gpu")
        Master { node: pg.sink; ramp: "gpu"; label: "output" }
        Label { text: "devices"; color: Theme.dim; topPadding: 6 }
        DeviceList { list: pg.outputs; current: pg.sink; ramp: "gpu"; isOut: true }
    }

    Section {
        title: "input"
        badge: pg.source ? pg.nodeName(pg.source) : "none"
        hue: Theme.hue("temp")
        Master { node: pg.source; ramp: "temp"; label: "input" }
        Label { text: "devices"; color: Theme.dim; topPadding: 6 }
        DeviceList { list: pg.inputs; current: pg.source; ramp: "temp"; isOut: false }
    }

    Section {
        title: "apps"
        badge: pg.apps.length + " playing"
        hue: Theme.hue("time")
        Repeater {
            model: pg.apps
            Row {
                id: app
                required property var modelData
                readonly property string appName: modelData.properties["application.name"] || modelData.name
                readonly property string appId: modelData.properties["application.process.binary"] || appName
                spacing: 10
                IconImage { width: 18; height: 18; source: Theme.appIcon(app.appId.toLowerCase()); anchors.verticalCenter: parent.verticalCenter }
                Label { width: 150; text: app.appName; anchors.verticalCenter: parent.verticalCenter }
                RoundButton {
                    implicitWidth: 24; implicitHeight: 24; iconSize: 12
                    icon: app.modelData.audio.muted ? "volume-off" : "volume-high"
                    hue: Theme.hue("time")
                    onClicked: app.modelData.audio.muted = !app.modelData.audio.muted
                }
                MiniSlider {
                    width: 340
                    anchors.verticalCenter: parent.verticalCenter
                    from: 0; to: 1.5; step: 0.01
                    value: app.modelData.audio.volume
                    ramp: "time"
                    format: v => Math.round(v * 100) + "%"
                    onMoved: v => app.modelData.audio.volume = v
                }
            }
        }
        Label { visible: pg.apps.length === 0; text: "nothing is playing sound"; color: Theme.dim }
    }
}
