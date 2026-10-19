import QtQuick
import "../services"
import "../components"

// Pending updates: repo and AUR, with a one-click paru -Syu.
Column {
    id: card
    signal close()
    width: 440
    spacing: 12

    Row {
        spacing: 14
        Label { text: Updates.count; font.pixelSize: Theme.fsBig * 2; color: Theme.hue("gh") }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Label { text: Updates.count === 1 ? "update waiting" : "updates waiting" }
            Label { text: Updates.repo.length + " repo · " + Updates.aur.length + " aur"; color: Theme.dim }
        }
    }

    Repeater {
        model: [{ name: "repo", list: Updates.repo, ramp: "gh" }, { name: "aur", list: Updates.aur, ramp: "time" }].filter(g => g.list.length > 0)
        PixelBox {
            id: grp
            required property var modelData
            width: card.width
            height: lst.height + 28
            step: 2
            fill: Theme.alpha(Theme.fg, 0.025)
            stroke: Theme.alpha(Theme.hue(modelData.ramp), 0.5)
            title: modelData.name
            titleColor: Theme.hue(modelData.ramp)
            badge: modelData.list.length + ""
            Column {
                id: lst
                x: 12; y: 16
                width: parent.width - 24
                spacing: 3
                Repeater {
                    model: grp.modelData.list.slice(0, 10)
                    Row {
                        required property var modelData
                        spacing: 8
                        Label { width: 170; text: modelData.name; font.bold: true }
                        Label { width: 210; text: modelData.from + " → " + modelData.to; color: Theme.dim; elide: Text.ElideMiddle }
                    }
                }
                Label { visible: grp.modelData.list.length > 10; text: "+" + (grp.modelData.list.length - 10) + " more"; color: Theme.dim }
            }
        }
    }

    Row {
        spacing: 8
        Chip { text: "update now"; icon: "package-up"; on: true; onClicked: { card.close(); Updates.upgrade() } }
        Chip { text: Updates.checking ? "checking…" : "check again"; icon: "refresh"; onClicked: Updates.refresh() }
    }
}
