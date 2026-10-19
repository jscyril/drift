import QtQuick
import "../services"

// GitHub contribution grid: columns are weeks, rows Sun..Sat.
// Cells pop in column by column when the data arrives.
Row {
    id: hm
    property int weeks: 16
    property int cell: 3
    property int gap: 1
    property bool animate: true
    property var hovered: null           // the day under the pointer
    readonly property var cols: GitHub.grid(weeks)

    spacing: gap
    Repeater {
        model: hm.cols
        Column {
            id: col
            required property var modelData
            required property int index
            spacing: hm.gap
            Repeater {
                model: col.modelData
                Rectangle {
                    id: cellRect
                    required property var modelData
                    width: hm.cell
                    height: hm.cell
                    color: !modelData ? "transparent"
                        : modelData.level === 0 ? Theme.alpha(Theme.dim, 0.14)
                        : Theme.ramps.gh[Math.min(4, modelData.level)]
                    opacity: 0
                    Component.onCompleted: pop.start()
                    SequentialAnimation {
                        id: pop
                        PauseAnimation { duration: hm.animate ? Theme.dur(col.index * 18) : 0 }
                        NumberAnimation { target: cellRect; property: "opacity"; to: 1; duration: Theme.dur(160) }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: hm.cell > 5
                        onEntered: hm.hovered = parent.modelData
                        onExited: if (hm.hovered === parent.modelData) hm.hovered = null
                    }
                }
            }
        }
    }
}
