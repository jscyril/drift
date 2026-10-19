import QtQuick
import "../services"

// A box with staircase pixel corners and an optional btop-style title set
// into the top border: ──┤ title ├──. Built from 1px rects, no overlaps,
// so translucent fills stay even.
Item {
    id: box
    property color fill: Theme.alpha(Theme.bg, 0.92)
    property color stroke: Theme.alpha(Theme.accent, 0.55)
    property int step: 2                     // corner stair size in px
    property string title: ""
    property color titleColor: Theme.accent
    property string badge: ""                // small right-side label in the border

    readonly property int s: step

    // ── fill ──
    Repeater {
        model: box.s
        Rectangle {
            required property int index
            x: box.s - index; y: index
            width: box.width - 2 * (box.s - index); height: 1
            color: box.fill
        }
    }
    Rectangle { x: 0; y: box.s; width: box.width; height: Math.max(0, box.height - 2 * box.s); color: box.fill }
    Repeater {
        model: box.s
        Rectangle {
            required property int index
            x: box.s - index; y: box.height - 1 - index
            width: box.width - 2 * (box.s - index); height: 1
            color: box.fill
        }
    }

    // ── stroke ──
    // top edge, broken around the title
    Rectangle {
        x: box.s; y: 0; height: 1
        width: box.title === "" ? box.width - 2 * box.s : titleRow.x - 3 - box.s
        color: box.stroke
    }
    Rectangle {
        visible: box.title !== "" || box.badge !== ""
        readonly property real from: box.title === "" ? box.s : titleRow.x + titleRow.width + 3
        readonly property real to: box.badge === "" ? box.width - box.s : badgeRow.x - 3
        x: from; y: 0; height: 1
        width: Math.max(0, to - from)
        color: box.stroke
    }
    Rectangle {
        visible: box.badge !== ""
        x: badgeRow.x + badgeRow.width + 3; y: 0; height: 1
        width: Math.max(0, box.width - box.s - x)
        color: box.stroke
    }
    Rectangle { x: box.s; y: box.height - 1; width: box.width - 2 * box.s; height: 1; color: box.stroke }
    Rectangle { x: 0; y: box.s; width: 1; height: box.height - 2 * box.s; color: box.stroke }
    Rectangle { x: box.width - 1; y: box.s; width: 1; height: box.height - 2 * box.s; color: box.stroke }
    Repeater {
        model: Math.max(0, box.s - 1)
        Item {
            required property int index
            readonly property int i: index + 1
            readonly property int inset: box.s - i
            Rectangle { x: parent.inset; y: parent.i; width: 1; height: 1; color: box.stroke }
            Rectangle { x: box.width - 1 - parent.inset; y: parent.i; width: 1; height: 1; color: box.stroke }
            Rectangle { x: parent.inset; y: box.height - 1 - parent.i; width: 1; height: 1; color: box.stroke }
            Rectangle { x: box.width - 1 - parent.inset; y: box.height - 1 - parent.i; width: 1; height: 1; color: box.stroke }
        }
    }

    // ── title & badge ──
    Row {
        id: titleRow
        visible: box.title !== ""
        x: 12
        y: -Math.round(height / 2)
        spacing: 4
        Rectangle { width: 1; height: 7; color: box.stroke; anchors.verticalCenter: parent.verticalCenter }
        Label { text: box.title; color: box.titleColor; font.bold: true }
        Rectangle { width: 1; height: 7; color: box.stroke; anchors.verticalCenter: parent.verticalCenter }
    }
    Row {
        id: badgeRow
        visible: box.badge !== ""
        x: box.width - width - 12
        y: -Math.round(height / 2)
        spacing: 4
        Rectangle { width: 1; height: 7; color: box.stroke; anchors.verticalCenter: parent.verticalCenter }
        Label { text: box.badge; color: Theme.dim }
        Rectangle { width: 1; height: 7; color: box.stroke; anchors.verticalCenter: parent.verticalCenter }
    }
}
