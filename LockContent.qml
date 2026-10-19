import QtQuick
import Quickshell
import "services"
import "components"

// What the lock screen shows. `lock` is the Lock scope (password, status,
// submit()); split out so it can be previewed in a normal window.
Item {
    id: lc
    required property var lock

    // the wallpaper, crushed to 160x90 and scaled up: instant pixel art
    Image {
        anchors.fill: parent
        source: Theme.wallpaper ? "file://" + Theme.wallpaper : ""
        sourceSize: Qt.size(160, 90)
        fillMode: Image.PreserveAspectCrop
        smooth: false
    }
    Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.surface, 0.62) }
    Canvas {
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.fillStyle = "rgba(0,0,0,0.16)"
            for (var y = 0; y < height; y += 3) ctx.fillRect(0, y, width, 1)
        }
    }

    // hidden input that owns the keyboard
    TextInput {
        id: input
        focus: true
        opacity: 0
        echoMode: TextInput.Password
        Component.onCompleted: forceActiveFocus()
        onTextEdited: { lc.lock.password = text; if (lc.lock.status === "wrong") lc.lock.status = "" }
        onAccepted: lc.lock.submit()
        Keys.onEscapePressed: { lc.lock.password = ""; text = "" }
        Connections {
            target: lc.lock
            function onPasswordChanged() { if (lc.lock.password === "") input.text = "" }
        }
    }
    MouseArea { anchors.fill: parent; onClicked: input.forceActiveFocus() }

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        spacing: 18

        Clock { anchors.horizontalCenter: parent.horizontalCenter; pixelSize: 110 }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(new Date(), "dddd · dd MMMM").toLowerCase()
            font.pixelSize: Theme.fsBig
            color: Theme.accent2
        }
        Item { width: 1; height: 30 }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "> " + Quickshell.env("USER")
            color: Theme.dim
        }

        // password box: one block per typed character
        Item {
            id: pwBox
            anchors.horizontalCenter: parent.horizontalCenter
            width: 360; height: 46
            readonly property color hue: lc.lock.status === "wrong" ? Theme.ramp("temp", 1) : lc.lock.status === "checking" ? Theme.accent2 : Theme.accent

            PixelBox {
                anchors.fill: parent
                step: 3
                fill: Theme.alpha(Theme.bg, 0.92)
                stroke: pwBox.hue
                title: lc.lock.status === "wrong" ? "wrong password" : lc.lock.status === "checking" ? "checking" : "password"
                titleColor: pwBox.hue
            }
            Row {
                anchors.centerIn: parent
                spacing: 4
                Repeater {
                    model: Math.min(lc.lock.password.length, 28)
                    Rectangle {
                        required property int index
                        width: 8; height: 8
                        color: Theme.ramp("gh", 0.4 + 0.6 * index / 28)
                    }
                }
                // block cursor
                Rectangle {
                    width: 8; height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: pwBox.hue
                    visible: lc.lock.status !== "checking"
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: lc.lock.locked
                        PropertyAction { value: 1 }
                        PauseAnimation { duration: 530 }
                        PropertyAction { value: 0 }
                        PauseAnimation { duration: 530 }
                    }
                }
            }
            // shake on failure
            SequentialAnimation {
                id: shake
                PropertyAction { target: pwBox; property: "anchors.horizontalCenterOffset"; value: -10 }
                PauseAnimation { duration: 50 }
                PropertyAction { target: pwBox; property: "anchors.horizontalCenterOffset"; value: 10 }
                PauseAnimation { duration: 50 }
                PropertyAction { target: pwBox; property: "anchors.horizontalCenterOffset"; value: -6 }
                PauseAnimation { duration: 50 }
                PropertyAction { target: pwBox; property: "anchors.horizontalCenterOffset"; value: 0 }
            }
            Connections { target: lc.lock; function onFailed() { shake.restart() } }
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: lc.lock.fails > 0 ? lc.lock.fails + " failed " + (lc.lock.fails === 1 ? "try" : "tries") + " · type and press enter" : "type and press enter"
            color: Theme.alpha(Theme.dim, 0.8)
        }
    }

    // bottom strip: battery, media
    Row {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.margins: 28
        spacing: 18
        Row {
            visible: System.hasBattery
            spacing: 8
            BatteryPill { anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
            visible: !!System.player && System.player.trackTitle !== ""
            spacing: 8
            Icon { name: "music"; size: 14; color: Theme.hue("time"); anchors.verticalCenter: parent.verticalCenter }
            Label { text: System.player ? System.player.trackTitle : ""; color: Theme.dim; width: Math.min(implicitWidth, 400) }
        }
    }
    Label {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 28
        text: "drift://locked"
        color: Theme.alpha(Theme.dim, 0.6)
    }
}
