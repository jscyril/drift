import QtQuick
import Quickshell.Bluetooth
import "../../services"
import "../../components"

Column {
    id: pg
    spacing: 18
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var all: adapter ? adapter.devices.values : []
    readonly property var mine: all.filter(d => d.paired || d.connected).sort((a, b) => b.connected - a.connected)
    // nearby: only named devices, unnamed ones are mostly noise
    readonly property var nearby: all.filter(d => !d.paired && !d.connected && d.name && d.name !== d.address.replace(/:/g, "-"))

    // scan while the page is open and bluetooth is on
    Component.onCompleted: if (adapter && adapter.enabled) adapter.discovering = true
    Component.onDestruction: if (adapter) adapter.discovering = false


    Section {
        title: "adapter"
        badge: pg.adapter ? pg.adapter.name : "none"
        hue: Theme.hue("mem")
        Label {
            visible: !pg.adapter
            width: parent.width
            wrapMode: Text.Wrap
            text: "no adapter. the bluetooth service may be stopped: sudo systemctl enable --now bluetooth, then reload drift"
            color: Theme.dim
        }
        Setting {
            visible: !!pg.adapter
            title: "bluetooth"
            hint: pg.adapter && pg.adapter.enabled ? (System.btConnected.length + " connected") : "off"
            Switch {
                checked: pg.adapter ? pg.adapter.enabled : false
                onToggled: v => { pg.adapter.enabled = v; if (v) pg.adapter.discovering = true }
            }
        }
        Setting {
            visible: pg.adapter && pg.adapter.enabled
            title: "visible to others"
            hint: "let other devices find this laptop"
            Switch { checked: pg.adapter ? pg.adapter.discoverable : false; onToggled: v => pg.adapter.discoverable = v }
        }
        Setting {
            visible: pg.adapter && pg.adapter.enabled
            title: "scanning"
            hint: pg.adapter && pg.adapter.discovering ? "looking for devices…" : "paused"
            Switch { checked: pg.adapter ? pg.adapter.discovering : false; onToggled: v => pg.adapter.discovering = v }
        }
    }

    Section {
        visible: pg.adapter && pg.adapter.enabled
        title: "my devices"
        badge: pg.mine.length + ""
        hue: Theme.hue("mem")
        spacing: 4
        Repeater { model: pg.mine; DeviceRow { required property var modelData; dev: modelData } }
        Label { visible: pg.mine.length === 0; text: "no paired devices"; color: Theme.dim }
    }

    Section {
        visible: pg.adapter && pg.adapter.enabled
        title: "nearby"
        badge: pg.adapter && pg.adapter.discovering ? "scanning" : ""
        hue: Theme.accent2
        spacing: 4
        Repeater { model: pg.nearby; DeviceRow { required property var modelData; dev: modelData } }
        Label { visible: pg.nearby.length === 0; text: pg.adapter && pg.adapter.discovering ? "looking…" : "turn on scanning to find devices"; color: Theme.dim }
    }

    component DeviceRow: Item {
        id: row
        property var dev
        readonly property bool busy: dev.pairing || dev.state === BluetoothDeviceState.Connecting || dev.state === BluetoothDeviceState.Disconnecting
        width: parent.width
        height: 38
        function glyph(icon) {
            if (/headset|headphone|audio-card/.test(icon)) return "headphones"
            if (/speaker|audio/.test(icon)) return "speaker"
            if (/mouse/.test(icon)) return "mouse"
            if (/keyboard/.test(icon)) return "keyboard"
            if (/phone/.test(icon)) return "phone"
            if (/computer|laptop/.test(icon)) return "laptop"
            if (/gaming|joystick/.test(icon)) return "gamepad"
            return "bluetooth"
        }

        PixelBox {
            anchors.fill: parent
            step: 2
            fill: row.dev.connected ? Theme.alpha(Theme.hue("mem"), 0.16) : "transparent"
            stroke: row.dev.connected ? Theme.hue("mem") : Theme.alpha(Theme.dim, 0.18)
        }
        Row {
            x: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10
            Icon { name: row.glyph(row.dev.icon || ""); size: 18; color: row.dev.connected ? Theme.hue("mem") : Theme.dim; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1
                Label { width: 240; text: row.dev.name || row.dev.address; font.bold: row.dev.connected }
                Label {
                    text: row.busy ? (row.dev.pairing ? "pairing…" : "working…")
                        : row.dev.connected ? "connected" : row.dev.paired ? "paired" : row.dev.address
                    color: row.busy ? Theme.accent2 : Theme.dim
                }
            }
            Row {
                visible: row.dev.batteryAvailable
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                Meter { value: row.dev.battery; ramp: "mem"; segments: 8; segW: 4; segH: 8; anchors.verticalCenter: parent.verticalCenter }
                Label { text: Math.round(row.dev.battery * 100) + "%"; color: Theme.dim }
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Chip {
                text: row.dev.connected ? "disconnect" : row.dev.paired ? "connect" : row.dev.pairing ? "cancel" : "pair"
                on: !row.dev.connected && row.dev.paired
                onClicked: {
                    var d = row.dev
                    if (d.connected) d.disconnect()
                    else if (d.paired) d.connect()
                    else if (d.pairing) d.cancelPair()
                    else { d.trusted = true; d.pair() }
                }
            }
            RoundButton {
                visible: row.dev.paired
                implicitWidth: 24; implicitHeight: 24; iconSize: 12
                icon: "trash"
                hue: Theme.ramp("temp", 1)
                onClicked: row.dev.forget()
            }
        }
    }
}
