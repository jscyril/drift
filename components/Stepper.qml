import QtQuick
import "../services"

Row {
    id: st
    property int value: 0
    property int from: 0
    property int to: 10
    signal moved(int value)
    spacing: 4

    RoundButton { implicitWidth: 24; implicitHeight: 24; icon: "left"; enabled: st.value > st.from; onClicked: st.moved(st.value - 1) }
    Item {
        width: 28; height: 24
        Digit {
            anchors.centerIn: parent
            value: st.value % 10
            pixelSize: Theme.fsBig
            color: Theme.accent
        }
    }
    RoundButton { implicitWidth: 24; implicitHeight: 24; icon: "right"; enabled: st.value < st.to; onClicked: st.moved(st.value + 1) }
}
