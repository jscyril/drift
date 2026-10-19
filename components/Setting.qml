import QtQuick
import "../services"

// Settings row: title + hint on the left, control on the right
// (or underneath with `below: true`).
Item {
    id: row
    property string title
    property string hint
    property bool below: false
    default property alias control: slot.data

    width: parent ? parent.width : 300
    implicitHeight: below ? text.height + 8 + slot.childrenRect.height + 4 : Math.max(32, text.height + 8)

    Column {
        id: text
        width: row.below ? row.width : row.width - slot.childrenRect.width - 16
        y: row.below ? 0 : (row.implicitHeight - height) / 2
        spacing: 3
        Label { width: parent.width; text: "> " + row.title; font.bold: true }
        Label {
            width: parent.width
            visible: row.hint !== ""
            text: "  " + row.hint
            color: Theme.alpha(Theme.dim, 0.8)
            wrapMode: Text.Wrap
        }
    }

    Item {
        id: slot
        x: row.below ? 0 : row.width - childrenRect.width
        y: row.below ? text.height + 8 : (row.implicitHeight - childrenRect.height) / 2
        width: row.below ? row.width : childrenRect.width
        height: childrenRect.height
    }
}
