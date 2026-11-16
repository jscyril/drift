import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"
import "../../components"

Column {
    id: pg
    spacing: 18
    readonly property var o: Config.opts
    property bool swaync: false

    // another daemon holding the notification bus means drift never sees anything
    Process {
        running: true
        command: ["pgrep", "-x", "swaync"]
        onExited: code => pg.swaync = code === 0
    }

    Section {
        visible: pg.swaync
        title: "heads up"
        hue: Theme.ramp("temp", 1)
        Label {
            width: parent.width
            wrapMode: Text.Wrap
            text: "swaync is running and owns notifications, so drift's popups and history stay empty. stop it and drift takes over on its own."
        }
        Chip {
            text: "stop swaync"
            icon: "close"
            danger: true
            onClicked: { Quickshell.execDetached(["sh", "-c", "systemctl --user stop swaync 2>/dev/null; pkill -x swaync"]); pg.swaync = false }
        }
    }

    Section {
        title: "popups"
        hue: Theme.hue("up")
        Toggle { key: "notifPopups"; title: "notification popups"; hint: "new notifications drop out of the bar" }
        Setting {
            visible: pg.o.notifPopups
            title: "popup time"
            below: true
            MiniSlider {
                width: parent.width
                from: 2; to: 15; step: 1
                value: pg.o.popupSeconds
                ramp: "temp"
                format: v => Math.round(v) + "s"
                onMoved: v => pg.o.popupSeconds = Math.round(v)
            }
        }
        Setting {
            title: "do not disturb"
            hint: "keep history, skip popups"
            Switch { checked: System.dnd; onToggled: v => System.dnd = v }
        }
        Toggle { key: "dndSchedule"; title: "quiet hours"; hint: "do not disturb by the clock; the notification center also has 30m / 1h / 2h" }
        Setting {
            visible: pg.o.dndSchedule
            title: "from / until"
            hint: "24-hour HH:MM; may run past midnight"
            Row {
                spacing: 6
                Field { width: 70; text: pg.o.dndFrom; placeholder: "22:00"; onCommitted: t => { if (NightLight.mins(t.trim()) >= 0) pg.o.dndFrom = t.trim() } }
                Field { width: 70; text: pg.o.dndTo; placeholder: "08:00"; onCommitted: t => { if (NightLight.mins(t.trim()) >= 0) pg.o.dndTo = t.trim() } }
            }
        }
        Setting {
            title: "test"
            Chip { text: "send one"; icon: "bell-ring"; onClicked: Quickshell.execDetached(["notify-send", "-a", "drift", "hello from drift", "this is what a notification looks like"]) }
        }
    }

    Section {
        title: "history"
        badge: System.notifications.length + " kept"
        hue: Theme.accent2
        Repeater {
            model: System.notifications.slice(0, 8)
            NotifItem { required property var modelData; width: parent.width; notif: modelData; onActivated: System.invoke(modelData) }
        }
        Label { visible: System.notifications.length === 0; text: "nothing here"; color: Theme.dim }
        Chip { visible: System.notifications.length > 0; text: "clear all"; icon: "sweep"; onClicked: System.clearNotifications() }
    }
}
