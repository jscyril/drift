import QtQuick
import "../services"

// Column chart built from stacked blocks: one column per value, each block
// colored by its height along a ramp. `highlight` marks one column (e.g. now).
Canvas {
    id: b
    property var values: []
    property real max: 1
    property string ramp: "time"
    property int barW: 8
    property int gap: 2
    property int cellH: 3
    property int highlight: -1

    implicitWidth: values.length * (barW + gap) - gap
    onValuesChanged: requestPaint()
    onMaxChanged: requestPaint()
    onHighlightChanged: requestPaint()
    onHeightChanged: requestPaint()
    Connections {
        target: Theme
        function onRampsChanged() { b.requestPaint() }
        function onDimChanged() { b.requestPaint() }
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var rows = Math.floor(height / (cellH + 1))
        if (rows <= 0) return
        var colors = []
        for (var r = 0; r < rows; r++) colors.push(String(Theme.ramp(ramp, rows > 1 ? r / (rows - 1) : 1)))
        var empty = String(Theme.alpha(Theme.dim, 0.10))
        for (var i = 0; i < values.length; i++) {
            var n = Math.round(Math.max(0, Math.min(1, values[i] / Math.max(1e-9, max))) * rows)
            if (values[i] > 0 && n === 0) n = 1
            var x = i * (barW + gap)
            for (var k = 0; k < rows; k++) {
                ctx.fillStyle = k < n ? colors[k] : (i === highlight ? String(Theme.alpha(Theme.accent, 0.18)) : empty)
                ctx.fillRect(x, height - (k + 1) * (cellH + 1), barW, cellH)
            }
        }
    }
}
