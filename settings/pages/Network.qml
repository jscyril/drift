import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"
import "../../components"

// Wi-Fi and wired via nmcli. Polls only while this page is open.
Column {
    id: pg
    spacing: 18

    property var networks: []        // [{ ssid, signal, secure, active, saved }]
    property var devices: []         // [{ dev, type, state, conn, ip }]
    property string expanded: ""     // ssid whose password row is open
    property string busy: ""         // ssid being connected
    property string message: ""

    // nmcli -t escapes ':' inside fields as '\:'
    function fields(line) {
        var out = [], cur = ""
        for (var i = 0; i < line.length; i++) {
            var c = line[i]
            if (c === "\\" && i + 1 < line.length) { cur += line[++i]; continue }
            if (c === ":") { out.push(cur); cur = ""; continue }
            cur += c
        }
        out.push(cur)
        return out
    }

    function refresh() { if (!scan.running) scan.running = true }
    Component.onCompleted: refresh()
    Timer { interval: 8000; running: true; repeat: true; onTriggered: pg.refresh() }

    Process {
        id: scan
        command: ["sh", "-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list; echo @SAVED; nmcli -t -f NAME,TYPE connection show;"
            + "echo @DEV; nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device; echo @IP; ip -4 -o addr show"]
        stdout: StdioCollector {
            onStreamFinished: {
                var sec = { WIFI: [] }, cur = "WIFI"
                this.text.split("\n").forEach(l => { if (l.charAt(0) === "@") { cur = l.slice(1); sec[cur] = [] } else if (l !== "") sec[cur].push(l) })

                var saved = (sec.SAVED || []).map(pg.fields).filter(f => f[1] === "802-11-wireless").map(f => f[0])
                var by = {}
                sec.WIFI.map(pg.fields).forEach(f => {
                    var ssid = f[1]
                    if (ssid === "") return
                    var n = { ssid: ssid, signal: parseInt(f[2]) || 0, secure: f[3] !== "" && f[3] !== "--", active: f[0] === "*", saved: saved.indexOf(ssid) >= 0 }
                    var old = by[ssid]
                    if (!old || n.active || (!old.active && n.signal > old.signal)) by[ssid] = n
                })
                pg.networks = Object.values(by).sort((a, b) => (b.active - a.active) || (b.saved - a.saved) || (b.signal - a.signal))

                var ips = {}
                ;(sec.IP || []).forEach(l => { var m = l.match(/^\d+:\s+(\S+)\s+inet\s+(\S+)/); if (m) ips[m[1]] = m[2] })
                pg.devices = (sec.DEV || []).map(pg.fields)
                    .filter(f => f[1] === "ethernet" || f[1] === "wifi")
                    .map(f => ({ dev: f[0], type: f[1], state: f[2], conn: f[3], ip: ips[f[0]] || "" }))
            }
        }
    }

    // one nmcli action at a time; report its outcome
    Process {
        id: act
        property string label
        stderr: StdioCollector { id: actErr }
        stdout: StdioCollector { id: actOut }
        onExited: code => {
            pg.message = code === 0 ? label + " ✓" : (actErr.text || actOut.text).trim().split("\n").pop()
            pg.busy = ""
            pg.refresh()
            System.refreshNet()
        }
    }
    function run(label, cmd) {
        message = label + "…"
        act.label = label
        act.command = cmd
        act.running = true
    }
    function connect(n, password) {
        busy = n.ssid
        expanded = ""
        if (n.saved) run("connecting to " + n.ssid, ["nmcli", "connection", "up", "id", n.ssid])
        else if (password) run("connecting to " + n.ssid, ["nmcli", "dev", "wifi", "connect", n.ssid, "password", password])
        else run("connecting to " + n.ssid, ["nmcli", "dev", "wifi", "connect", n.ssid])
    }

    Section {
        title: "wi-fi"
        badge: System.wifiEnabled ? (System.wifiSsid || "not connected") : "off"
        hue: Theme.hue("down")
        Setting {
            title: "wi-fi radio"
            hint: System.wifiEnabled ? "on" : "off"
            Switch { checked: System.wifiEnabled; onToggled: { System.toggleWifi(); rescanLater.start() } }
        }
        Timer { id: rescanLater; interval: 2500; onTriggered: pg.refresh() }
        Row {
            spacing: 8
            Chip { text: scan.running ? "scanning…" : "rescan"; icon: "radar"; onClicked: pg.run("rescan", ["nmcli", "dev", "wifi", "rescan"]) }
            Label { anchors.verticalCenter: parent.verticalCenter; text: pg.message; color: Theme.dim }
        }
    }

    Section {
        visible: System.wifiEnabled
        title: "networks"
        badge: pg.networks.length + " in range"
        hue: Theme.hue("down")
        spacing: 4

        Repeater {
            model: pg.networks
            Column {
                id: net
                required property var modelData
                width: parent.width
                spacing: 4
                readonly property bool open: pg.expanded === modelData.ssid

                Item {
                    width: parent.width
                    height: 34
                    PixelBox {
                        anchors.fill: parent
                        step: 2
                        fill: net.modelData.active ? Theme.alpha(Theme.hue("down"), 0.16) : rowMa.containsMouse ? Theme.alpha(Theme.fg, 0.05) : "transparent"
                        stroke: net.modelData.active ? Theme.hue("down") : Theme.alpha(Theme.dim, rowMa.containsMouse ? 0.5 : 0.15)
                    }
                    MouseArea {
                        id: rowMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var n = net.modelData
                            if (n.active) return
                            if (n.secure && !n.saved) { pg.expanded = net.open ? "" : n.ssid; return }
                            pg.connect(n, "")
                        }
                    }
                    Row {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Icon { name: "wifi-" + Math.max(1, Math.ceil(net.modelData.signal / 25)); size: 16; color: Theme.ramp("down", net.modelData.signal / 100); anchors.verticalCenter: parent.verticalCenter }
                        Label { width: 220; text: net.modelData.ssid; font.bold: net.modelData.active; anchors.verticalCenter: parent.verticalCenter }
                        Meter { value: net.modelData.signal / 100; ramp: "down"; segments: 10; segW: 4; segH: 8; anchors.verticalCenter: parent.verticalCenter }
                        Label { width: 40; text: net.modelData.signal + "%"; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                        Icon { visible: net.modelData.secure; name: "lock"; size: 12; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                        Tag {
                            visible: net.modelData.active || net.modelData.saved || pg.busy === net.modelData.ssid
                            text: pg.busy === net.modelData.ssid ? "connecting" : net.modelData.active ? "connected" : "saved"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        RoundButton {
                            visible: net.modelData.active
                            implicitWidth: 24; implicitHeight: 24; iconSize: 12
                            icon: "unlink"
                            onClicked: pg.run("disconnected", ["nmcli", "connection", "down", "id", net.modelData.ssid])
                        }
                        RoundButton {
                            visible: net.modelData.saved
                            implicitWidth: 24; implicitHeight: 24; iconSize: 12
                            icon: "trash"
                            hue: Theme.ramp("temp", 1)
                            onClicked: pg.run("forgot " + net.modelData.ssid, ["nmcli", "connection", "delete", "id", net.modelData.ssid])
                        }
                    }
                }

                // password row for new secured networks
                Row {
                    visible: net.open
                    x: 34
                    spacing: 6
                    Field {
                        id: pw
                        width: 260
                        password: true
                        placeholder: "password"
                        onCommitted: t => { if (t !== "" && net.open) pg.connect(net.modelData, t) }
                        Component.onCompleted: if (net.open) grab()
                    }
                    onVisibleChanged: if (visible) pw.grab()
                    Chip { text: "connect"; icon: "check"; onClicked: pg.connect(net.modelData, pw.textValue) }
                }
            }
        }
        Label { visible: pg.networks.length === 0; text: scan.running ? "scanning…" : "no networks found"; color: Theme.dim }
    }

    Section {
        title: "devices"
        hue: Theme.accent2
        Repeater {
            model: pg.devices
            Row {
                required property var modelData
                spacing: 10
                Icon { name: modelData.type === "wifi" ? "wifi-4" : "lan"; size: 15; color: modelData.state === "connected" ? Theme.accent2 : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                Label { width: 90; text: modelData.dev; font.bold: true }
                Label { width: 110; text: modelData.state; color: modelData.state === "connected" ? Theme.accent2 : Theme.dim }
                Label { width: 180; text: modelData.conn || "-" }
                Label { text: modelData.ip; color: Theme.dim }
            }
        }
    }
}
