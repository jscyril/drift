import QtQuick
import Quickshell.Services.UPower
import "../../services"
import "../../components"

Column {
    id: pg
    spacing: 18
    // the physical battery has health/energy; the display device is the aggregate
    readonly property var bat: UPower.devices.values.find(d => d.isLaptopBattery) || null

    Section {
        visible: System.hasBattery
        title: "battery"
        badge: System.charging ? "charging" : UPower.onBattery ? "on battery" : "plugged in"
        hue: Theme.hue("temp")
        Row {
            spacing: 20
            Label { text: System.batteryPct + "%"; font.pixelSize: Theme.fsBig * 2; color: Theme.ramp("mem", System.batteryPct / 100) }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Meter { value: System.batteryPct / 100; ramp: "mem"; segments: 40; segW: 8; segH: 14 }
                Label {
                    color: Theme.dim
                    text: {
                        var b = System.battery
                        if (!b) return ""
                        if (System.charging && b.timeToFull > 0) return Theme.duration(b.timeToFull) + " until full"
                        if (!System.charging && b.timeToEmpty > 0) return Theme.duration(b.timeToEmpty) + " left"
                        return ""
                    }
                }
            }
        }
        Row {
            visible: !!pg.bat
            spacing: 30
            topPadding: 4
            Repeater {
                model: pg.bat ? [
                    ["draw", Math.abs(pg.bat.changeRate).toFixed(1) + " W"],
                    ["energy", pg.bat.energy.toFixed(1) + " / " + pg.bat.energyCapacity.toFixed(1) + " Wh"],
                    ["health", pg.bat.healthSupported ? Math.round(pg.bat.healthPercentage) + "%" : "-"]
                ] : []
                Column {
                    required property var modelData
                    Label { text: modelData[0]; color: Theme.dim }
                    Label { text: modelData[1]; font.bold: true }
                }
            }
        }
    }

    Section {
        title: "power profile"
        hue: Theme.hue("cpu")
        Row {
            width: parent.width
            spacing: 8
            Repeater {
                model: [
                    { p: PowerProfile.PowerSaver, label: "saver", icon: "leaf", ramp: "mem", hint: "quiet & long battery" },
                    { p: PowerProfile.Balanced, label: "balanced", icon: "balance", ramp: "down", hint: "the default" },
                    { p: PowerProfile.Performance, label: "performance", icon: "rocket", ramp: "temp", hint: "fans on, go fast" }
                ].filter(e => e.p !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)
                Tile {
                    required property var modelData
                    width: 200
                    on: PowerProfiles.profile === modelData.p
                    icon: modelData.icon
                    title: modelData.label
                    subtitle: modelData.hint
                    hue: Theme.hue(modelData.ramp)
                    onClicked: PowerProfiles.profile = modelData.p
                }
            }
        }
    }

    Section {
        title: "power saver"
        badge: System.lowPower ? "active" : "off"
        hue: Theme.hue("mem")
        Setting {
            title: "drift power saver"
            hint: "slower stat polling, no idle animations; auto = whenever you're on battery"
            Segmented {
                options: [{ label: "auto", value: "auto" }, { label: "on", value: "on" }, { label: "off", value: "off" }]
                value: Config.opts.powerSaver
                onPicked: v => Config.opts.powerSaver = v
            }
        }
    }

    Section {
        title: "idle"
        hue: Theme.accent2
        Setting {
            title: "caffeine"
            hint: "keep the screen awake"
            Switch { checked: System.caffeine; onToggled: v => System.caffeine = v }
        }
    }

    Section {
        title: "session"
        badge: "click twice to confirm"
        hue: Theme.ramp("temp", 1)
        Row {
            spacing: 14
            Repeater {
                model: [
                    { icon: "lock", label: "lock", cmd: System.lockCmd },
                    { icon: "monitor", label: "screen off", cmd: "sleep 0.6; niri msg action power-off-monitors" },
                    { icon: "sleep", label: "sleep", cmd: "systemctl suspend" },
                    { icon: "account", label: "log out", cmd: "niri msg action quit --skip-confirmation" },
                    { icon: "restart", label: "reboot", cmd: "systemctl reboot" },
                    { icon: "power", label: "power off", cmd: "systemctl poweroff" }
                ]
                Column {
                    required property var modelData
                    spacing: 4
                    ConfirmButton { implicitWidth: 44; implicitHeight: 44; iconSize: 20; icon: modelData.icon; command: modelData.cmd }
                    Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: Theme.dim }
                }
            }
        }
    }
}
