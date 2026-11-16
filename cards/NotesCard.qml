import QtQuick
import Quickshell
import "../services"
import "../components"

// Scratchpad: type anywhere in the box, it saves as you go.
Column {
    id: card
    width: 400
    spacing: 10

    Item {
        width: card.width
        height: head.height
        Row {
            id: head
            spacing: 14
            Label { text: Notes.lines; font.pixelSize: Theme.fsBig * 2; color: Theme.accent2 }
            Label { anchors.verticalCenter: parent.verticalCenter; text: Notes.lines === 1 ? "line" : "lines"; color: Theme.dim }
        }
        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            RoundButton { icon: "clipboard"; onClicked: Quickshell.execDetached(["wl-copy", Notes.text]) }
            RoundButton { icon: "trash"; onClicked: { Notes.save(""); area.text = "" } }
        }
    }

    Item {
        width: card.width
        height: 220
        PixelBox {
            anchors.fill: parent
            step: 1
            fill: Theme.alpha(Theme.fg, 0.04)
            stroke: area.activeFocus ? Theme.accent2 : Theme.alpha(Theme.dim, 0.4)
        }
        Flickable {
            id: flick
            anchors.fill: parent
            anchors.margins: 8
            contentHeight: area.height
            clip: true
            TextEdit {
                id: area
                width: flick.width
                height: Math.max(implicitHeight, flick.height)
                text: Notes.text
                color: Theme.fg
                selectionColor: Theme.accent2
                selectedTextColor: Theme.surface
                font.family: Theme.font
                font.pixelSize: Theme.fs
                wrapMode: TextEdit.Wrap
                renderType: Text.NativeRendering
                Component.onCompleted: forceActiveFocus()
                onTextChanged: if (text !== Notes.text) Notes.save(text)
                onCursorRectangleChanged: {
                    if (cursorRectangle.y < flick.contentY) flick.contentY = cursorRectangle.y
                    else if (cursorRectangle.y + cursorRectangle.height > flick.contentY + flick.height) flick.contentY = cursorRectangle.y + cursorRectangle.height - flick.height
                }
            }
        }
        Label {
            visible: area.text === ""
            x: 8; y: 8
            text: "jot something down…"
            color: Theme.dim
        }
    }
}
