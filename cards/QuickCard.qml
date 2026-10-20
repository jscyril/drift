import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import "../services"
import "../components"

ColumnLayout {
    id: card
    signal close()
    signal openCard(string name)
    // right-click on any control: jump to its page in the settings app
    function settings(page) { card.close(); System.openSettings(page) }
    width: 400
    spacing: 12

    Component.onCompleted: System.refreshBrightness()

    // header: battery readout + session buttons
    RowLayout {
        Layout.fillWidth: true
        spacing: 4
        Column {
            Layout.fillWidth: true
            spacing: 2
            Label {
                text: System.hasBattery ? System.batteryPct + "%" : Qt.formatDate(new Date(), "dddd").toLowerCase()
                font.pixelSize: Theme.fsBig
                color: Theme.ramp("cpu", System.hasBattery ? (100 - System.batteryPct) / 100 * 0.9 : 0)
            }
            Label {
                text: (System.hasBattery ? System.batteryPowerText + (System.batterySecsLeft > 0 ? " · " + Theme.duration(System.batterySecsLeft) + (UPower.onBattery ? " left" : " to full") : "") + " · " : "") + "up " + Theme.duration(Stats.uptime)
                color: Theme.dim
            }
        }
        RoundButton { icon: "cog"; onClicked: card.openCard("settings"); onRightClicked: card.settings("look") }
        RoundButton { icon: "lock"; onClicked: { card.close(); System.lock() } onRightClicked: card.settings("power") }
        RoundButton { icon: "sleep"; onClicked: { card.close(); System.lock(); System.run("sleep 1; systemctl suspend") } onRightClicked: card.settings("power") }
        ConfirmButton { icon: "restart"; command: "systemctl reboot"; onRightClicked: card.settings("power") }
        ConfirmButton { icon: "power"; command: "systemctl poweroff"; onRightClicked: card.settings("power") }
    }

    Slider {
        Layout.fillWidth: true
        icon: System.volumeIcon
        ramp: "mem"
        value: System.muted ? 0 : System.volume
        onMoved: v => System.setVolume(v)
        onIconClicked: System.toggleMute()
        onRightClicked: card.settings("sound")
    }

    Slider {
        Layout.fillWidth: true
        visible: System.hasMic
        icon: System.micMuted ? "mic-off" : "mic"
        ramp: "temp"
        value: System.micMuted ? 0 : System.micVolume
        onMoved: v => System.setMicVolume(v)
        onIconClicked: System.toggleMicMute()
        onRightClicked: card.settings("sound")
    }

    Slider {
        Layout.fillWidth: true
        visible: System.hasBacklight
        icon: "brightness"
        ramp: "gpu"
        value: System.brightness
        onMoved: v => System.setBrightness(v)
        onRightClicked: card.settings("displays")
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        columnSpacing: 8
        rowSpacing: 8

        Tile {
            Layout.fillWidth: true
            on: System.wifiEnabled
            hue: Theme.hue("down")
            icon: System.netIcon
            title: "wi-fi"
            subtitle: System.wired ? "ethernet" : System.wifiSsid !== "" ? System.wifiSsid : System.wifiEnabled ? "not connected" : "off"
            onClicked: System.toggleWifi()
            onRightClicked: card.settings("network")
        }
        Tile {
            Layout.fillWidth: true
            on: System.btEnabled
            hue: Theme.accent
            icon: System.btEnabled ? (System.btConnected.length > 0 ? "bluetooth-connect" : "bluetooth") : "bluetooth-off"
            title: "bluetooth"
            subtitle: System.btConnected.length > 0 ? System.btConnected[0].name : System.btEnabled ? "on" : "off"
            onClicked: System.toggleBluetooth()
            onRightClicked: card.settings("bluetooth")
        }
        Tile {
            Layout.fillWidth: true
            on: System.dnd
            hue: Theme.accent2
            icon: System.dnd ? "bell-off" : "bell"
            title: "do not disturb"
            subtitle: System.dnd ? "silenced" : "alerts on"
            onClicked: System.dnd = !System.dnd
            onRightClicked: card.settings("notifications")
        }
        Tile {
            Layout.fillWidth: true
            on: System.caffeine
            hue: Theme.hue("gpu")
            icon: System.caffeine ? "coffee" : "coffee-outline"
            title: "caffeine"
            subtitle: System.caffeine ? "staying awake" : "off"
            onClicked: System.caffeine = !System.caffeine
            onRightClicked: card.settings("power")
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        Label {
            Layout.fillWidth: true
            text: System.notifications.length > 0 ? "> notifications [" + System.notifications.length + "]" : "> no notifications_"
            color: Theme.dim
        }
        RoundButton {
            visible: System.notifications.length > 0
            implicitWidth: 22; implicitHeight: 22; iconSize: 12
            icon: "sweep"
            onClicked: System.clearNotifications()
            onRightClicked: card.settings("notifications")
        }
    }

    Repeater {
        model: System.notifications.slice(0, 4)
        delegate: NotifItem {
            required property var modelData
            Layout.fillWidth: true
            notif: modelData
            onActivated: card.close()
        }
    }
}
