import QtQuick
import Quickshell
import Quickshell.Widgets
import "../services"
import "../components"

// Notification center: everything that arrived, newest first. Ones still
// waiting are lit and clickable (runs their action); the rest are history.
// Rows slide in and out as they come and go.
Column {
    id: card
    signal close()
    width: 420
    spacing: 10

    Row {
        width: parent.width
        spacing: 6
        Label {
            width: parent.width - quiet.width - dnd.width - clear.width - 18
            anchors.verticalCenter: parent.verticalCenter
            text: System.dnd ? "> " + System.dndText + "_"
                : System.history.length === 0 ? "> nothing yet_" : "> " + System.notifications.length + " new · " + System.history.length + " kept"
            color: System.dnd ? Theme.accent2 : Theme.dim
        }
        // focus: quiet for a while (dnd alone stays on until you turn it off)
        Row {
            id: quiet
            spacing: 4
            Repeater {
                model: [{ label: "30m", m: 30 }, { label: "1h", m: 60 }, { label: "2h", m: 120 }]
                Chip { required property var modelData; text: modelData.label; onClicked: System.quiet(modelData.m) }
            }
        }
        Chip { id: dnd; text: "dnd"; icon: System.dnd ? "bell-off" : "bell"; on: System.dnd; onClicked: System.dnd = !System.dnd }
        Chip { id: clear; text: "clear"; icon: "sweep"; danger: true; opacity: System.history.length > 0 ? 1 : 0.35; onClicked: System.clearHistory() }
    }

    ListView {
        id: lv
        width: parent.width
        height: Math.min(contentHeight, 440)
        Behavior on height { NumberAnimation { duration: Theme.dur(220); easing.type: Easing.OutCubic } }
        clip: true
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds
        // ScriptModel turns array changes into row inserts/removes, so the transitions below can run
        model: ScriptModel { values: System.history; objectProp: "key" }

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; from: 60; to: 0; duration: Theme.dur(260); easing.type: Easing.OutCubic }
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dur(200) }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "x"; to: lv.width; duration: Theme.dur(220); easing.type: Easing.InCubic }
                NumberAnimation { property: "opacity"; to: 0; duration: Theme.dur(220) }
            }
        }
        displaced: Transition { NumberAnimation { properties: "x,y"; duration: Theme.dur(240); easing.type: Easing.OutCubic } }

        delegate: Item {
            id: row
            required property var modelData
            readonly property var live: System.liveOf(modelData)
            width: lv.width
            height: text.height + 18

            PixelBox {
                anchors.fill: parent
                fill: ma.containsMouse ? Theme.alpha(Theme.accent, 0.10) : Theme.alpha(Theme.fg, row.live ? 0.05 : 0.02)
                stroke: ma.containsMouse && row.live ? Theme.accent : Theme.alpha(Theme.dim, row.live ? 0.45 : 0.2)
            }
            // lit edge: still waiting
            Rectangle { visible: !!row.live; x: 3; y: 4; width: 2; height: parent.height - 8; color: Theme.accent2 }

            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: row.live ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: if (row.live) { System.invoke(row.live); card.close() }
            }

            IconImage {
                x: 12; y: 9; width: 24; height: 24
                smooth: false
                opacity: row.live ? 1 : 0.6
                source: {
                    var ic = row.modelData.icon || ""
                    return ic.startsWith("/") ? "file://" + ic : ic.startsWith("file:") ? ic : Theme.appIcon(ic)
                }
            }
            Column {
                id: text
                x: 46; y: 9
                width: parent.width - 46 - 34
                spacing: 3
                Label {
                    width: parent.width
                    text: (row.modelData.app || "").toUpperCase() + " · " + System.ago(row.modelData.time)
                    color: row.live ? Theme.accent2 : Theme.alpha(Theme.dim, 0.7)
                }
                Label { width: parent.width; text: row.modelData.summary; font.bold: true; color: row.live ? Theme.fg : Theme.dim }
                Label {
                    width: parent.width
                    visible: text !== ""
                    text: row.modelData.body
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    color: Theme.alpha(Theme.dim, row.live ? 1 : 0.7)
                }
                Flow {
                    width: parent.width
                    spacing: 6
                    topPadding: 3
                    visible: acts.count > 0
                    Repeater {
                        id: acts
                        model: row.live ? row.live.actions.filter(a => a.identifier !== "default" && a.text !== "") : []
                        Chip {
                            required property var modelData
                            text: modelData.text.toLowerCase()
                            onClicked: { modelData.invoke(); card.close() }
                        }
                    }
                }
            }
            RoundButton {
                anchors.right: parent.right
                anchors.rightMargin: 8
                y: 8
                implicitWidth: 20; implicitHeight: 20; iconSize: 11
                icon: "close"
                onClicked: System.forget(row.modelData)
            }
        }
    }
}
