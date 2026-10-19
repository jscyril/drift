pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Current weather from wttr.in, refreshed every 20 minutes.
Singleton {
    id: weather

    property bool ready: false
    property int tempC: 0
    property int feelsC: 0
    property int hiC: 0
    property int loC: 0
    property int humidity: 0
    property int windKmh: 0
    property int code: 113
    property string desc: ""
    property string area: ""

    readonly property bool f: Config.opts.fahrenheit
    function temp(c) { return Math.round(f ? c * 9 / 5 + 32 : c) + "°" }

    readonly property bool night: { var h = new Date().getHours(); return h < 6 || h >= 18 }
    readonly property string icon: {
        var c = code
        if (c === 113) return night ? "weather-night" : "weather-sunny"
        if (c === 116) return night ? "weather-night-partly-cloudy" : "weather-partly-cloudy"
        if (c === 119 || c === 122) return "weather-cloudy"
        if ([143, 248, 260].indexOf(c) >= 0) return "weather-fog"
        if ([200, 386, 389, 392, 395].indexOf(c) >= 0) return "weather-lightning"
        if ([179, 182, 185, 227, 230, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].indexOf(c) >= 0) return "weather-snowy"
        if ([305, 308, 356, 359].indexOf(c) >= 0) return "weather-pouring"
        return "weather-rainy"
    }

    function refresh() { proc.running = true }

    Process {
        id: proc
        command: ["curl", "-s", "--max-time", "10", "wttr.in/" + encodeURIComponent(Config.opts.weatherLocation) + "?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var j = JSON.parse(this.text)
                    var cur = j.current_condition[0]
                    weather.tempC = parseInt(cur.temp_C)
                    weather.feelsC = parseInt(cur.FeelsLikeC)
                    weather.humidity = parseInt(cur.humidity)
                    weather.windKmh = parseInt(cur.windspeedKmph)
                    weather.code = parseInt(cur.weatherCode)
                    weather.desc = cur.weatherDesc[0].value.trim()
                    weather.hiC = parseInt(j.weather[0].maxtempC)
                    weather.loC = parseInt(j.weather[0].mintempC)
                    // wttr's area is a neighbourhood; show the city: typed location, else ip lookup
                    var loc = Config.opts.weatherLocation.trim()
                    if (loc !== "") weather.area = loc.split(",")[0]
                    else { if (!cityProc.running) cityProc.running = true }
                    if (weather.area === "") weather.area = j.nearest_area[0].region[0].value
                    weather.ready = true
                } catch (e) {}   // offline or rate-limited: keep the last reading
            }
        }
    }

    Process {
        id: cityProc
        command: ["curl", "-s", "--max-time", "5", "https://ipinfo.io/city"]
        stdout: StdioCollector {
            onStreamFinished: {
                var c = this.text.trim()
                if (c !== "" && c.length < 60 && c.charAt(0) !== "{") weather.area = c
            }
        }
    }

    Timer {
        interval: 20 * 60 * 1000
        running: Config.opts.weather
        repeat: true
        triggeredOnStart: true
        onTriggered: weather.refresh()
    }

    Connections {
        target: Config.opts
        function onWeatherLocationChanged() { relocate.restart() }
    }
    Timer { id: relocate; interval: 1200; onTriggered: weather.refresh() }   // wait for typing to settle
}
