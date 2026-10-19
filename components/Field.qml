import QtQuick
import "../services"

// Pixel text field with a blinking block cursor. Commits on Enter / blur.
Item {
    id: f
    property string text
    property string placeholder
    property bool password: false
    signal committed(string text)
    readonly property string textValue: input.text   // live, before commit
    signal edited(string text)
    function grab() { input.forceActiveFocus() }

    implicitWidth: 200
    implicitHeight: 24

    PixelBox {
        anchors.fill: parent
        step: 1
        fill: Theme.alpha(Theme.fg, 0.04)
        stroke: input.activeFocus ? Theme.accent : Theme.alpha(Theme.dim, 0.4)
    }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        verticalAlignment: TextInput.AlignVCenter
        text: f.text
        color: Theme.fg
        selectionColor: Theme.accent
        selectedTextColor: Theme.surface
        font.family: Theme.font
        font.pixelSize: Theme.fs
        renderType: Text.NativeRendering
        clip: true
        cursorDelegate: Rectangle {
            width: 6
            color: Theme.accent
            visible: input.activeFocus
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: input.activeFocus
                PropertyAction { value: 1 }
                PauseAnimation { duration: 500 }
                PropertyAction { value: 0 }
                PauseAnimation { duration: 500 }
            }
        }
        echoMode: f.password ? TextInput.Password : TextInput.Normal
        passwordCharacter: "*"
        onEditingFinished: f.committed(text)
        onTextEdited: f.edited(text)

        Label {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === "" && !input.activeFocus
            text: f.placeholder
            color: Theme.alpha(Theme.dim, 0.6)
        }
    }
}
