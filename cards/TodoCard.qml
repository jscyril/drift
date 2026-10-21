import QtQuick
import "../services"
import "../components"
import "../services/dates.js" as Dates

// To-do list. Type + Enter to add ("pay rent @fri" sets a due date), click a task
// to tick it, hover for the date and delete buttons.
Column {
    id: card
    width: 400
    spacing: 12

    property int editing: -1          // index (in Todo.items) whose date editor is open
    readonly property var now: new Date(Todo.today + "T12:00:00")

    Item {
        width: card.width
        height: head.height
        Row {
            id: head
            spacing: 14
            Label { text: Todo.pending; font.pixelSize: Theme.fsBig * 2; color: Theme.accent3 }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Label { text: Todo.pending === 1 ? "thing to do" : "things to do" }
                Label {
                    text: Todo.overdue > 0 ? Todo.overdue + " overdue" : (Todo.items.length - Todo.pending) + " done"
                    color: Todo.overdue > 0 ? Theme.ramp("temp", 1) : Theme.dim
                }
            }
        }
        Segmented {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            options: [{ label: "my order", value: "order" }, { label: "date", value: "date" }]
            value: Config.opts.todoSort
            onPicked: v => Config.opts.todoSort = v
        }
    }

    Column {
        width: card.width
        spacing: 4
        Field {
            id: input
            width: card.width
            placeholder: "add a task · @tmr, @fri 5pm, @25oct sets a due date"
            onAccepted: t => { Todo.add(t); input.clear() }
            Component.onCompleted: { grab(); Todo.sync() }
        }
        Label {
            readonly property var p: Dates.parse(input.textValue, card.now)
            visible: p.due !== ""
            x: 8
            text: p.due ? "due " + Dates.label(p.due, card.now) + " · " + Qt.formatDate(new Date(p.due + "T12:00:00"), "ddd d MMM").toLowerCase()
                          + (p.time ? " · " + Dates.fmtTime(p.time, Config.opts.clock24h) : "") : ""
            color: Theme.accent3
        }
    }

    Column {
        width: card.width
        spacing: 2
        Repeater {
            model: Todo.view(Config.opts.todoSort)
            Column {
                id: row
                required property var modelData
                readonly property var t: modelData.t
                readonly property int idx: modelData.i
                readonly property int days: t.due ? Dates.daysUntil(t.due, card.now) : 99
                readonly property string time: { Todo.meta; return Todo.timeOf(t) }
                readonly property bool late: { Todo.nowHM; Todo.meta; return Todo.late(t) }
                readonly property bool hovered: main.containsMouse || dateBtn.containsMouse || delBtn.containsMouse
                width: card.width

                MouseArea {
                    id: main
                    width: card.width
                    height: Math.max(22, words.height + 6)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Todo.toggle(row.idx)
                    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.accent3, row.hovered ? 0.08 : 0) }
                    Icon {
                        x: 4
                        y: 3
                        name: row.t.done ? "checkbox-marked" : "checkbox-blank"
                        size: 15
                        color: row.t.done ? Theme.accent3 : Theme.dim
                    }
                    Column {
                        id: words
                        x: 26
                        y: 3
                        width: parent.width - x - right.width - 10
                        Label {
                            width: parent.width
                            text: row.t.text
                            wrapMode: Text.Wrap
                            elide: Text.ElideNone
                            color: row.t.done ? Theme.dim : Theme.fg
                            font.strikeout: row.t.done
                        }
                        Label {
                            visible: !!row.t.notes
                            width: parent.width
                            text: row.t.notes || ""
                            color: Theme.dim
                            maximumLineCount: 1
                        }
                    }
                    Row {
                        id: right
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        y: 3
                        spacing: 6
                        Label {
                            visible: !!row.t.due
                            anchors.verticalCenter: parent.verticalCenter
                            text: !row.t.due ? "" : row.t.done ? Dates.plain(row.t.due, card.now) : Dates.whenLabel(row.t.due, row.time, card.now, Config.opts.clock24h)
                            color: row.t.done ? Theme.dim
                                 : row.late ? Theme.ramp("temp", 1)
                                 : row.days === 0 ? Theme.accent2
                                 : row.days === 1 ? Theme.accent3 : Theme.dim
                        }
                        MouseArea {
                            id: dateBtn
                            visible: row.hovered || card.editing === row.idx
                            width: 18; height: 16
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.editing = card.editing === row.idx ? -1 : row.idx
                            Icon { anchors.centerIn: parent; name: "calendar"; size: 13; color: parent.containsMouse || card.editing === row.idx ? Theme.accent3 : Theme.dim }
                        }
                        MouseArea {
                            id: delBtn
                            visible: row.hovered
                            width: 18; height: 16
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { card.editing = -1; Todo.remove(row.idx) }
                            Icon { anchors.centerIn: parent; name: "trash"; size: 13; color: parent.containsMouse ? Theme.ramp("temp", 1) : Theme.dim }
                        }
                    }
                }

                // date editor: quick picks, or type anything @ understands
                Row {
                    visible: card.editing === row.idx
                    x: 26
                    spacing: 6
                    topPadding: 4; bottomPadding: 6
                    Repeater {
                        model: [{ l: "today", w: "today" }, { l: "tomorrow", w: "tmr" }, { l: "+1 week", w: "1w" }]
                        Chip {
                            required property var modelData
                            text: modelData.l
                            onClicked: { Todo.setDue(row.idx, Dates.dueFrom(modelData.w, new Date())); card.editing = -1 }
                        }
                    }
                    Chip {
                        visible: !!row.t.due
                        text: "no date"
                        onClicked: { Todo.setDue(row.idx, ""); card.editing = -1 }
                    }
                    Field {
                        width: 110
                        placeholder: "fri 5pm, 9am"
                        // a date alone keeps the time; with a time, sets both
                        onAccepted: t => {
                            var w = Dates.when(t, new Date())
                            if (w) { Todo.setDue(row.idx, w.due, w.time || undefined); card.editing = -1 }
                        }
                    }
                }
            }
        }
        Label { visible: Todo.items.length === 0; text: "nothing yet"; color: Theme.dim; x: 4 }
    }

    Row {
        spacing: 8
        Chip {
            visible: !Todo.google && Todo.items.length > Todo.pending
            text: "clear done"
            icon: "sweep"
            onClicked: { card.editing = -1; Todo.clearDone() }
        }
        Chip {
            visible: Todo.google && Todo.needsSignIn
            on: true
            text: "sign in to google"
            icon: "account"
            onClicked: Todo.signIn()
        }
        Label {
            visible: Todo.google
            width: Math.min(implicitWidth, card.width - 170)
            anchors.verticalCenter: parent.verticalCenter
            text: Todo.syncing ? "syncing…" : Todo.syncError !== "" ? Todo.syncError : "google tasks"
            color: Todo.syncError !== "" && !Todo.syncing ? Theme.ramp("temp", 1) : Theme.dim
        }
    }
}
