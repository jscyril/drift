import QtQuick
import "../../services"
import "../../components"

Column {
    id: pg
    spacing: 18
    readonly property var o: Config.opts

    Section {
        title: "github"
        badge: GitHub.ready ? GitHub.totalYear + " this year" : ""
        hue: Theme.hue("gh")
        Setting {
            title: "user"
            hint: "public profile, no token needed"
            Field { text: pg.o.githubUser; placeholder: "username"; onCommitted: t => pg.o.githubUser = t.trim() }
        }
        Heatmap { visible: GitHub.ready; weeks: Math.min(53, Math.floor(parent.width / 12)); cell: 10; gap: 2 }
    }

    Section {
        title: "screen time"
        badge: Theme.duration(ScreenTime.todayTotal) + " today"
        hue: Theme.hue("time")
        Setting {
            title: "idle after"
            hint: "counting pauses when you've been away this long"
            below: true
            MiniSlider {
                width: parent.width
                from: 1; to: 15; step: 1
                value: pg.o.idleMinutes
                ramp: "time"
                format: v => Math.round(v) + "min"
                onMoved: v => pg.o.idleMinutes = Math.round(v)
            }
        }
        Label {
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.dim
            text: "stored in " + ScreenTime.path + " (90 days). older history was imported from noctalia."
        }
    }
}
