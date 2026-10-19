import QtQuick
import "../services"

// Pixel segmented picker; the highlight block slides to the chosen option.
Item {
    id: seg
    property var options: []        // [{ label, value }]
    property var value
    signal picked(var value)

    readonly property int current: Math.max(0, options.findIndex(o => o.value === value))

    implicitWidth: row.implicitWidth + 6
    implicitHeight: 24

    PixelBox { anchors.fill: parent; fill: "transparent"; stroke: Theme.alpha(Theme.dim, 0.4) }

    Rectangle {
        readonly property Item target: rep.count > seg.current ? rep.itemAt(seg.current) : null
        x: target ? target.x + 3 : 3
        width: target ? target.width : 0
        y: 3
        height: seg.height - 6
        color: Theme.accent
        Behavior on x { NumberAnimation { duration: Theme.dur(300); easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
        Behavior on width { NumberAnimation { duration: Theme.dur(300) } }
    }

    Row {
        id: row
        x: 3
        anchors.verticalCenter: parent.verticalCenter
        Repeater {
            id: rep
            model: seg.options
            delegate: Item {
                required property var modelData
                required property int index
                width: lbl.implicitWidth + 18
                height: seg.height - 6
                Label {
                    id: lbl
                    anchors.centerIn: parent
                    text: modelData.label
                    color: index === seg.current ? Theme.surface : Theme.dim
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: seg.picked(modelData.value)
                }
            }
        }
    }
}
