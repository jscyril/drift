import QtQuick
import Quickshell.Widgets
import "../services"
import "../components"

// Screen time: today's total, an hour-by-hour chart, top apps, and the week.
Column {
    id: card
    width: 560
    spacing: 14

    readonly property real yesterday: ScreenTime.week.length > 1 ? ScreenTime.week[5].secs : 0
    readonly property int hourNow: new Date().getHours()

    Row {
        spacing: 16
        Column {
            spacing: 2
            Label { text: Theme.duration(ScreenTime.todayTotal); font.pixelSize: Theme.fsBig * 2; color: Theme.hue("time") }
            Label {
                text: card.yesterday > 0
                    ? (ScreenTime.todayTotal >= card.yesterday ? "▲ " : "▼ ") + Theme.duration(Math.abs(ScreenTime.todayTotal - card.yesterday)) + " vs yesterday"
                    : "today"
                color: Theme.dim
            }
        }
        Column {
            anchors.bottom: parent.bottom
            spacing: 4
            Bars {
                height: 64
                values: ScreenTime.today.hourly
                max: 3600
                ramp: "time"
                barW: 13; gap: 2; cellH: 3
                highlight: card.hourNow
            }
            Row {
                Repeater {
                    model: [0, 6, 12, 18]
                    Label { required property int modelData; width: 6 * 15; text: String(modelData).padStart(2, "0"); color: Theme.dim }
                }
            }
        }
    }

    PixelBox {
        width: card.width
        height: appsCol.height + 28
        step: 2
        fill: Theme.alpha(Theme.fg, 0.025)
        stroke: Theme.alpha(Theme.hue("time"), 0.5)
        title: "apps"
        titleColor: Theme.hue("time")
        badge: ScreenTime.todayApps.length + " today"

        Column {
            id: appsCol
            x: 12; y: 16
            width: parent.width - 24
            spacing: 6
            readonly property real topSecs: ScreenTime.todayApps.length > 0 ? ScreenTime.todayApps[0].secs : 1
            Repeater {
                model: ScreenTime.todayApps.slice(0, 7)
                Row {
                    required property var modelData
                    required property int index
                    spacing: 10
                    IconImage { width: 16; height: 16; source: Theme.appIcon(modelData.app); anchors.verticalCenter: parent.verticalCenter }
                    Label { text: Theme.appName(modelData.app); width: 140; anchors.verticalCenter: parent.verticalCenter }
                    Meter {
                        anchors.verticalCenter: parent.verticalCenter
                        value: modelData.secs / appsCol.topSecs
                        ramp: "time"
                        segments: 52; segW: 4; segH: 10
                    }
                    Num { text: Theme.duration(modelData.secs); color: Theme.ramp("time", index / 6) }
                }
            }
            Label { visible: ScreenTime.todayApps.length === 0; text: "nothing tracked yet today"; color: Theme.dim }
        }
    }

    // week
    Row {
        spacing: 12
        Repeater {
            model: ScreenTime.week
            Column {
                required property var modelData
                required property int index
                readonly property bool isToday: index === 6
                spacing: 4
                Bars {
                    height: 54
                    values: [modelData.secs]
                    max: Math.max(...ScreenTime.week.map(d => d.secs), 3600)
                    ramp: "time"
                    barW: 66; gap: 0; cellH: 3
                }
                Label {
                    width: 66
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDate(modelData.date, "ddd").toLowerCase() + " " + Theme.duration(modelData.secs)
                    color: isToday ? Theme.hue("time") : Theme.dim
                    font.bold: isToday
                }
            }
        }
    }
}
