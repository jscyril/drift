import QtQuick
import "../services"
import "../components"

// Now playing. The album art is sampled down to 40×40 and blown up without
// smoothing, so it shows as chunky pixels.
Item {
    id: card
    signal close()
    readonly property var p: System.player
    readonly property real progress: p && p.length > 0 ? Math.min(1, p.position / p.length) : 0

    implicitWidth: 440
    implicitHeight: 128

    function fmt(s) {
        s = Math.max(0, Math.floor(s || 0))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    // MPRIS doesn't push position updates; ask while playing
    Timer {
        interval: 1000
        running: card.p && card.p.isPlaying
        repeat: true
        onTriggered: card.p.positionChanged()
    }

    Item {
        id: art
        width: 128; height: 128
        Image {
            anchors.fill: parent
            anchors.margins: 3
            source: card.p ? card.p.trackArtUrl : ""
            sourceSize: Qt.size(40, 40)
            smooth: false
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        Icon {
            anchors.centerIn: parent
            visible: !card.p || card.p.trackArtUrl === ""
            name: "music"; size: 48; color: Theme.dim
        }
        PixelBox { anchors.fill: parent; fill: "transparent"; stroke: Theme.hue("time") }
    }

    Column {
        anchors.left: art.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        height: parent.height
        spacing: 4

        Label {
            width: parent.width
            text: card.p ? card.p.trackTitle : "nothing playing"
            font.pixelSize: Theme.fsBig
            color: Theme.fg
        }
        Label {
            width: parent.width
            text: card.p ? (card.p.trackArtist || card.p.identity) : ""
            color: Theme.hue("time")
        }

        Item { width: 1; height: 8 }

        Item {
            width: parent.width
            height: 12
            Meter {
                id: bar
                value: card.progress
                ramp: "time"
                segments: Math.floor(parent.width / 5)
                segW: 4; segH: 10
            }
            MouseArea {
                anchors.fill: parent
                enabled: card.p && card.p.canSeek
                cursorShape: Qt.PointingHandCursor
                onClicked: e => card.p.position = e.x / width * card.p.length
            }
        }
        Item {
            width: parent.width
            height: 12
            Label { text: card.fmt(card.p ? card.p.position : 0); color: Theme.dim }
            Label { anchors.right: parent.right; text: card.fmt(card.p ? card.p.length : 0); color: Theme.dim }
        }

        Row {
            spacing: 8
            topPadding: 4
            RoundButton { icon: "prev"; enabled: card.p && card.p.canGoPrevious; onClicked: card.p.previous() }
            RoundButton {
                icon: card.p && card.p.isPlaying ? "pause" : "play"
                filled: true
                hue: Theme.hue("time")
                implicitWidth: 40
                onClicked: card.p.togglePlaying()
            }
            RoundButton { icon: "next"; enabled: card.p && card.p.canGoNext; onClicked: card.p.next() }
            Equalizer { anchors.verticalCenter: parent.verticalCenter; playing: card.p && card.p.isPlaying }
        }
    }
}
