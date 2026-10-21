import QtQuick
import "../../services"
import "../../components"

Column {
    id: pg
    spacing: 18
    readonly property var o: Config.opts

    Section {
        title: "shape"
        Setting {
            title: "height"
            below: true
            MiniSlider {
                width: parent.width
                from: 24; to: 36; step: 1
                value: pg.o.barHeight
                format: v => Math.round(v) + "px"
                onMoved: v => pg.o.barHeight = Math.round(v)
            }
        }
        Setting {
            title: "edge gap"
            hint: "space between the bar and the screen edge; 0 docks it with rounded corners"
            below: true
            MiniSlider {
                width: parent.width
                from: 0; to: 12; step: 1
                value: pg.o.barMargin
                ramp: "cpu"
                format: v => Math.round(v) + "px"
                onMoved: v => pg.o.barMargin = Math.round(v)
            }
        }
        Setting {
            title: "workspaces"
            hint: "cells per monitor"
            Stepper { value: pg.o.workspaceCount; from: 1; to: 9; onMoved: v => pg.o.workspaceCount = v }
        }
    }

    Section {
        title: "modules"
        badge: "left → right"
        hue: Theme.hue("cpu")
        Toggle { key: "showCpu"; title: "cpu graph" }
        Toggle { key: "showMem"; title: "memory meter" }
        Toggle { key: "showTemp"; title: "cpu temperature" }
        Toggle { key: "showGpu"; title: "gpu meter" }
        Toggle { key: "showNet"; title: "network graph" }
        Toggle { key: "showScreenTime"; title: "screen time" }
        Toggle { key: "showGithub"; title: "github heatmap" }
        Toggle { key: "showMedia"; title: "now playing" }
    }

    Section {
        title: "arch button"
        hue: Theme.accent2
        Setting {
            title: "click runs"
            hint: "right-click opens the quick settings card"
            Field {
                width: 240
                text: pg.o.launcherCommand
                onCommitted: t => { if (t.trim() !== "") pg.o.launcherCommand = t.trim() }
            }
        }
    }
}
