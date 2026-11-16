import QtQuick
import Quickshell
import Quickshell.Wayland
import "services"
import "components"

// Search box: type, pick where it goes (Tab), Enter opens it in your browser.
// google · youtube · your AI of choice (claude, chatgpt or gemini).
PanelWindow {
    id: sm
    signal close()

    screen: Quickshell.screens.find(s => s.name === Niri.focusedOutput) || Quickshell.screens[0]
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "drift-search"
    color: "transparent"

    // %s = the query, URL-encoded. gemini has no search link: the query is copied for pasting instead.
    readonly property var ais: ({
        claude: { home: "https://claude.ai/new", url: "https://claude.ai/new?q=%s" },
        chatgpt: { home: "https://chatgpt.com/", url: "https://chatgpt.com/?q=%s" },
        gemini: { home: "https://gemini.google.com/app", url: "" }
    })
    readonly property string ai: ais[Config.opts.aiProvider] ? Config.opts.aiProvider : "claude"
    readonly property var targets: [
        { key: "google", label: "google", verb: "search google for", ramp: "down", home: "https://www.google.com/", url: "https://www.google.com/search?q=%s" },
        { key: "youtube", label: "youtube", verb: "search youtube for", ramp: "temp", home: "https://www.youtube.com/", url: "https://www.youtube.com/results?search_query=%s" },
        { key: "ai", label: ai, verb: "ask " + ai, ramp: "time", home: ais[ai].home, url: ais[ai].url }
    ]
    property int sel: 0
    readonly property var cur: targets[sel]
    readonly property color hue: Theme.hue(cur.ramp)

    function link(t, q) { return q === "" || t.url === "" ? t.home : t.url.replace("%s", encodeURIComponent(q)) }
    function go() {
        var q = field.textValue.trim()
        if (q !== "" && cur.url === "") Quickshell.execDetached(["wl-copy", "--", q])
        Quickshell.execDetached(["xdg-open", link(cur, q)])
        close()
    }
    Component.onCompleted: {
        console.assert(link(targets[0], "a b&c") === "https://www.google.com/search?q=a%20b%26c")
        console.assert(link(targets[1], "") === "https://www.youtube.com/")
        console.assert(link({ home: "h", url: "" }, "x") === "h")
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.surface, 0.7)
        opacity: panel.intro
        MouseArea { anchors.fill: parent; onClicked: sm.close() }
    }

    PixelBox {
        id: panel
        property real intro: 0
        NumberAnimation on intro { to: 1; duration: Theme.dur(220); easing.type: Easing.OutCubic }
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(parent.height * 0.28 - (1 - intro) * 24)      // drops into place
        opacity: intro
        width: 640
        height: col.height + 36
        step: 4
        fill: Theme.alpha(Theme.surface, 0.98)
        stroke: sm.hue
        Behavior on stroke { ColorAnimation { duration: Theme.dur(200) } }
        title: "search"
        titleColor: sm.hue
        MouseArea { anchors.fill: parent }

        Column {
            id: col
            x: 18; y: 20
            width: parent.width - 36
            spacing: 12
            Keys.onPressed: e => {
                var n = sm.targets.length
                if (e.key === Qt.Key_Escape) sm.close()
                else if (e.key === Qt.Key_Backtab) sm.sel = (sm.sel + n - 1) % n
                else if (e.key === Qt.Key_Tab) sm.sel = (sm.sel + 1) % n
                else return
                e.accepted = true
            }

            Field {
                id: field
                width: parent.width
                implicitHeight: 32
                placeholder: "type, then enter · tab switches where it goes"
                onAccepted: sm.go()
                Component.onCompleted: grab()
            }

            Row {
                spacing: 10
                Segmented {
                    options: sm.targets.map((t, i) => ({ label: t.label, value: i }))
                    value: sm.sel
                    onPicked: v => { sm.sel = v; field.grab() }
                }
                // which AI the third slot is
                Row {
                    visible: sm.cur.key === "ai"
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    Repeater {
                        model: Object.keys(sm.ais)
                        Chip {
                            required property string modelData
                            text: modelData
                            on: sm.ai === modelData
                            onClicked: { Config.opts.aiProvider = modelData; field.grab() }
                        }
                    }
                }
            }

            Label {
                width: parent.width
                color: sm.hue
                text: {
                    var q = field.textValue.trim()
                    if (q === "") return "> open " + sm.cur.label + "_"
                    return "> " + sm.cur.verb + ": " + q + (sm.cur.url === "" ? "  (copied, paste it there)" : "") + "_"
                }
            }
        }
    }
}
