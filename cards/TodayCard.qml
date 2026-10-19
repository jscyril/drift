import QtQuick
import "../services"
import "../components"

// Calendar on the left, weather on the right.
Row {
    id: card
    signal close()
    spacing: 20

    CalendarCard {}

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Repeater {
            model: 24
            Rectangle { width: 1; height: 6; color: index % 2 ? "transparent" : Theme.alpha(Theme.accent, 0.4); required property int index }
        }
    }

    Column {
        width: 200
        spacing: 6
        visible: Config.opts.weather

        Row {
            spacing: 4
            Icon { name: "pin"; size: 12; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
            Label { text: (Weather.area || "locating…").toLowerCase(); color: Theme.dim }
        }

        Item {
            width: parent.width
            height: 80
            Icon {
                id: bigIcon
                name: Weather.icon
                size: 60
                color: Theme.accent2
                anchors.verticalCenter: parent.verticalCenter
                // bob in 2px steps
                property int frame: 0
                anchors.verticalCenterOffset: [0, -2, -4, -2][frame]
                Timer { interval: 450; running: true; repeat: true; onTriggered: bigIcon.frame = (bigIcon.frame + 1) % 4 }
            }
            Label {
                anchors.left: bigIcon.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.temp(Weather.tempC)
                font.pixelSize: Theme.fsBig * 2
                color: Theme.ramp("temp", Weather.tempC / 40)
            }
        }

        Label { width: parent.width; text: Weather.desc.toLowerCase(); font.bold: true }
        Label { width: parent.width; text: "feels like " + Weather.temp(Weather.feelsC); color: Theme.dim }

        Item { width: 1; height: 6 }

        Repeater {
            model: [
                { icon: "thermometer", label: "hi/lo", value: Weather.temp(Weather.hiC) + " / " + Weather.temp(Weather.loC), ramp: "temp", v: Weather.hiC / 40 },
                { icon: "humidity", label: "humid", value: Weather.humidity + "%", ramp: "down", v: Weather.humidity / 100 },
                { icon: "weather-windy", label: "wind", value: Weather.windKmh + "km/h", ramp: "mem", v: Weather.windKmh / 50 }
            ]
            Row {
                required property var modelData
                spacing: 6
                Icon { name: modelData.icon; size: 12; color: Theme.hue(modelData.ramp); anchors.verticalCenter: parent.verticalCenter }
                Label { text: modelData.label; width: 42; color: Theme.dim }
                Meter { value: modelData.v; ramp: modelData.ramp; segments: 10; segW: 4; segH: 9; anchors.verticalCenter: parent.verticalCenter }
                Label { text: modelData.value }
            }
        }
    }
}
