import QtQuick
import "../services"

// Pixel history graph: newest sample on the right, columns built from square
// cells colored by height along a ramp (btop's gradient graphs, but blocky).
Canvas {
    id: g
    property var values: []
    property real max: 1
    property string ramp: "cpu"
    property int cell: 2
    property int gap: 0
    property bool mirror: false          // grow downward (for upload under download)
    property bool dimEmpty: false        // faint cells where there's no value

    onValuesChanged: requestPaint()
    onMaxChanged: requestPaint()
    onRampChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    Connections {
        target: Theme
        function onAccentChanged() { g.requestPaint() }
        function onRampsChanged() { g.requestPaint() }
    }

    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var cols = Math.floor(width / cell), rows = Math.floor(height / cell)
        if (cols <= 0 || rows <= 0) return
        var data = values.slice(-cols)
        var x0 = width - data.length * cell
        var colors = []
        for (var r = 0; r < rows; r++) colors.push(String(Theme.ramp(ramp, rows > 1 ? r / (rows - 1) : 1)))
        if (dimEmpty) {
            ctx.fillStyle = String(Theme.alpha(Theme.dim, 0.08))
            for (var c0 = 0; c0 < cols; c0++)
                for (var r0 = 0; r0 < rows; r0++)
                    ctx.fillRect(c0 * cell, r0 * cell, cell - gap, cell - gap)
        }
        for (var i = 0; i < data.length; i++) {
            var n = Math.round(Math.max(0, Math.min(1, data[i] / max)) * rows)
            if (data[i] > 0 && n === 0) n = 1
            for (var k = 0; k < n; k++) {
                ctx.fillStyle = colors[k]
                var y = mirror ? k * cell : height - (k + 1) * cell
                ctx.fillRect(x0 + i * cell, y, cell - gap, cell - gap)
            }
        }
    }
}
