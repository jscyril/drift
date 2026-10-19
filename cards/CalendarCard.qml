import QtQuick
import "../services"
import "../components"

Column {
    id: card
    signal close()
    width: 280
    spacing: 8

    readonly property date today: new Date()
    property int monthOffset: 0
    readonly property date shown: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)

    // 42 cells starting on the Monday on/before the 1st
    readonly property var cells: {
        var first = new Date(shown.getFullYear(), shown.getMonth(), 1)
        var start = new Date(first)
        start.setDate(1 - ((first.getDay() + 6) % 7))
        var out = []
        for (var i = 0; i < 42; i++) {
            var d = new Date(start)
            d.setDate(start.getDate() + i)
            out.push(d)
        }
        return out
    }

    Item {
        width: parent.width
        height: 28
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDate(card.shown, "MMMM yyyy").toLowerCase()
            font.pixelSize: Theme.fsBig
            color: Theme.accent
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            RoundButton { implicitWidth: 22; implicitHeight: 22; iconSize: 12; icon: "left"; onClicked: card.monthOffset-- }
            RoundButton { implicitWidth: 22; implicitHeight: 22; iconSize: 12; icon: "right"; onClicked: card.monthOffset++ }
        }
    }

    Grid {
        columns: 7
        width: parent.width
        readonly property real cell: width / 7

        Repeater {
            model: ["mo", "tu", "we", "th", "fr", "sa", "su"]
            Label {
                required property string modelData
                required property int index
                width: parent.cell; height: 18
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: index >= 5 ? Theme.accent2 : Theme.dim
            }
        }

        Repeater {
            model: card.cells
            Item {
                required property var modelData
                readonly property bool isToday: modelData.toDateString() === card.today.toDateString()
                readonly property bool inMonth: modelData.getMonth() === card.shown.getMonth()
                width: parent.cell; height: 28
                PixelBox {
                    anchors.centerIn: parent
                    width: 30; height: 24
                    step: 2
                    visible: parent.isToday
                    fill: Theme.accent
                    stroke: Theme.accent
                }
                Label {
                    anchors.centerIn: parent
                    text: parent.modelData.getDate()
                    font.bold: parent.isToday
                    color: parent.isToday ? Theme.surface : parent.inMonth ? Theme.fg : Theme.alpha(Theme.dim, 0.35)
                }
            }
        }
    }
}
