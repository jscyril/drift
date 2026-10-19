import QtQuick
import "../../services"
import "../../components"

Column {
    id: pg
    spacing: 18
    readonly property var o: Config.opts

    Section {
        title: "clock"
        hue: Theme.hue("temp")
        Item {
            width: parent.width; height: 56
            Clock { anchors.centerIn: parent; pixelSize: 33 }
        }
        Toggle { key: "clock24h"; title: "24-hour clock" }
        Toggle { key: "showSeconds"; title: "seconds"; hint: "watch the reels roll" }
    }

    Section {
        title: "weather"
        badge: Weather.ready ? Weather.area.toLowerCase() : "wttr.in"
        hue: Theme.hue("down")
        Row {
            visible: Weather.ready && pg.o.weather
            spacing: 14
            Icon { name: Weather.icon; size: 34; color: Theme.hue("temp") }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label { text: Weather.temp(Weather.tempC); font.pixelSize: Theme.fsBig }
                Label { text: Weather.desc.toLowerCase(); color: Theme.dim }
            }
        }
        Toggle { key: "weather"; title: "show weather" }
        Setting {
            visible: pg.o.weather
            title: "location"
            hint: "city name; empty = detect from ip"
            Field {
                text: pg.o.weatherLocation
                placeholder: "auto"
                onCommitted: t => pg.o.weatherLocation = t.trim()
            }
        }
        Setting {
            visible: pg.o.weather
            title: "units"
            Segmented {
                options: [{ label: "°c", value: false }, { label: "°f", value: true }]
                value: pg.o.fahrenheit
                onPicked: v => pg.o.fahrenheit = v
            }
        }
    }
}
