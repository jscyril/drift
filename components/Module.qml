import QtQuick
import "../services"

// Clickable bar module. On hover, pixel corner brackets snap in around it;
// while its card is open it gets a tinted backing in its own hue.
Item {
    id: mod
    property color hue: Theme.accent
    property bool active: false
    property int padding: 8
    default property alias content: inner.data
    signal clicked()
    signal rightClicked()
    readonly property bool hovered: ma.containsMouse

    implicitWidth: inner.childrenRect.width + 2 * padding
    implicitHeight: Config.opts.barHeight - 6

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(mod.hue, mod.active ? 0.18 : mod.hovered ? 0.08 : 0)
        Behavior on color { ColorAnimation { duration: Theme.dur(150) } }
    }

    // corner brackets
    Repeater {
        model: [[0, 0], [1, 0], [0, 1], [1, 1]]
        Item {
            required property var modelData
            property real off: (mod.hovered || mod.active) ? 0 : 4
            Behavior on off { NumberAnimation { duration: Theme.dur(160); easing.type: Easing.OutBack; easing.overshoot: 2 } }
            opacity: (mod.hovered || mod.active) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.dur(120) } }
            x: modelData[0] ? mod.width - 4 + off : -off
            y: modelData[1] ? mod.height - 4 + off : -off
            width: 4; height: 4
            Rectangle { x: 0; y: parent.modelData[1] ? 3 : 0; width: 4; height: 1; color: mod.hue }
            Rectangle { x: parent.modelData[0] ? 3 : 0; y: 0; width: 1; height: 4; color: mod.hue }
        }
    }

    Item {
        id: inner
        x: mod.padding
        width: childrenRect.width
        height: parent.height
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => e.button === Qt.RightButton ? mod.rightClicked() : mod.clicked()
    }
}
