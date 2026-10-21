import QtQuick
import "../services"
import "../components"

// A year of GitHub contributions with streak stats. Hover a cell for its day.
Column {
    id: card
    spacing: 14

    readonly property var cols: GitHub.grid(53)
    readonly property color green: Theme.ramps.gh[3]

    Row {
        spacing: 26
        Column {
            spacing: 2
            Label { text: GitHub.totalYear; font.pixelSize: Theme.fsBig * 2; color: card.green }
            Label { text: "contributions · @" + Config.opts.githubUser; color: Theme.dim }
        }
        Repeater {
            model: [
                { icon: "fire", label: "streak", value: GitHub.streak + "d" },
                { icon: "trophy", label: "best streak", value: GitHub.bestStreak + "d" },
                { icon: "github", label: "this week", value: GitHub.thisWeek },
                { icon: "chip", label: "best day", value: GitHub.bestDay ? GitHub.bestDay.count : 0 }
            ]
            Column {
                required property var modelData
                anchors.bottom: parent.bottom
                spacing: 2
                Row {
                    spacing: 4
                    Icon { name: modelData.icon; size: 13; color: card.green; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: modelData.label; color: Theme.dim }
                }
                Label { text: modelData.value; font.pixelSize: Theme.fsBig; color: Theme.fg }
            }
        }
        Chip {
            anchors.bottom: parent.bottom
            text: GitHub.loading ? "refreshing…" : "refresh"
            icon: "refresh"
            onClicked: if (!GitHub.loading) GitHub.refresh()
        }
    }

    Column {
        spacing: 4
        // month labels above the first week of each month
        Item {
            x: 30
            width: hm.width; height: 12
            Repeater {
                model: card.cols
                Label {
                    required property var modelData
                    required property int index
                    readonly property var first: modelData.find(d => d !== null)
                    readonly property bool starts: first && Number(first.date.slice(8)) <= 7
                    visible: starts && index < card.cols.length - 2
                    x: index * 11
                    text: first ? Qt.formatDate(new Date(first.date + "T00:00:00"), "MMM").toLowerCase() : ""
                    color: Theme.dim
                }
            }
        }
        Row {
            spacing: 6
            // pinned to the heatmap's rows (row 0 = sunday)
            Item {
                width: 24; height: hm.height
                Repeater {
                    model: [1, 3, 5]
                    Label {
                        required property int modelData
                        y: modelData * (hm.cell + hm.gap)
                        height: hm.cell
                        text: ["mon", "wed", "fri"][(modelData - 1) / 2]
                        color: Theme.dim; font.pixelSize: 8
                    }
                }
            }
            Heatmap { id: hm; weeks: 53; cell: 9; gap: 2 }
        }
    }

    Item {
        width: parent.width
        height: 14
        Label {
            text: hm.hovered ? hm.hovered.count + " contributions on " + Qt.formatDate(new Date(hm.hovered.date + "T00:00:00"), "ddd d MMM yyyy").toLowerCase()
                             : "hover a day"
            color: hm.hovered ? card.green : Theme.dim
        }
        Row {
            anchors.right: parent.right
            spacing: 3
            Label { text: "less"; color: Theme.dim }
            Rectangle { width: 9; height: 9; color: Theme.alpha(Theme.dim, 0.14); anchors.verticalCenter: parent.verticalCenter }
            Repeater {
                model: 4
                Rectangle { required property int index; width: 9; height: 9; color: Theme.ramps.gh[index + 1]; anchors.verticalCenter: parent.verticalCenter }
            }
            Label { text: "more"; color: Theme.dim }
        }
    }
}
