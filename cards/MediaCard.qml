import QtQuick
import Quickshell.Services.Mpris
import "../services"
import "../components"

// Now playing. The album art is sampled down to 40×40 and blown up without
// smoothing, so it shows as chunky pixels. Pick which player to control,
// drag the bar to seek, scroll the art for volume; underneath, live audio
// levels from cava.
Column {
    id: card
    signal close()
    readonly property var p: System.player
    readonly property real progress: p && p.length > 0 ? Math.min(1, p.position / p.length) : 0
    readonly property color hue: Theme.hue("time")

    width: 446
    spacing: 12

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

    // new track: the art pops and the text slides in
    Connections {
        target: card.p
        function onTrackTitleChanged() { change.restart() }
    }
    onPChanged: change.restart()
    ParallelAnimation {
        id: change
        NumberAnimation { target: art; property: "scale"; from: 0.88; to: 1; duration: Theme.dur(320); easing.type: Easing.OutBack; easing.overshoot: 2 }
        NumberAnimation { target: info; property: "slide"; from: 14; to: 0; duration: Theme.dur(280); easing.type: Easing.OutCubic }
        NumberAnimation { target: info; property: "opacity"; from: 0; to: 1; duration: Theme.dur(280) }
    }

    // ── which player ──
    Flow {
        visible: System.players.length > 1
        width: parent.width
        spacing: 6
        Repeater {
            model: System.players
            Chip {
                required property var modelData
                text: modelData.identity.toLowerCase()
                icon: modelData.isPlaying ? "play" : "pause"
                on: modelData === card.p
                onClicked: System.pinnedPlayer = modelData
            }
        }
    }

    Item {
        width: parent.width
        height: 128

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
            PixelBox { anchors.fill: parent; fill: "transparent"; stroke: card.hue }
            // scroll for this player's volume
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                enabled: !!card.p && card.p.volumeSupported && card.p.canControl
                onWheel: w => card.p.volume = Math.max(0, Math.min(1, card.p.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05)))
            }
        }

        Column {
            id: info
            property real slide: 0
            x: art.width + 16 + slide
            width: parent.width - art.width - 16
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
                text: card.p ? [card.p.trackArtist || card.p.identity, card.p.trackAlbum].filter(t => t).join(" · ") : ""
                color: card.hue
            }

            Item { width: 1; height: 8 }

            Item {
                id: seek
                // while dragging, the bar follows the pointer and the seek happens on release
                property real drag: -1
                readonly property real shown: drag >= 0 ? drag : card.progress
                width: parent.width
                height: 12
                Meter {
                    value: seek.shown
                    ramp: "time"
                    segments: Math.floor(parent.width / 5)
                    segW: 4; segH: 10
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    enabled: card.p && card.p.canSeek && card.p.length > 0
                    cursorShape: Qt.PointingHandCursor
                    function at(x) { return Math.max(0, Math.min(1, (x - 4) / seek.width)) }
                    onPressed: e => seek.drag = at(e.x)
                    onPositionChanged: e => { if (pressed) seek.drag = at(e.x) }
                    onReleased: { card.p.position = seek.drag * card.p.length; seek.drag = -1 }
                    onCanceled: seek.drag = -1
                }
            }
            Item {
                width: parent.width
                height: 12
                Label { text: card.fmt(card.p ? seek.shown * card.p.length : 0); color: seek.drag >= 0 ? card.hue : Theme.dim }
                Label { anchors.right: parent.right; text: card.fmt(card.p ? card.p.length : 0); color: Theme.dim }
            }

            Row {
                spacing: 8
                topPadding: 4
                RoundButton {
                    visible: !!card.p && card.p.shuffleSupported
                    icon: "shuffle"
                    hue: card.hue
                    filled: visible && card.p.shuffle
                    enabled: visible && card.p.canControl
                    onClicked: card.p.shuffle = !card.p.shuffle
                }
                RoundButton { icon: "prev"; enabled: card.p && card.p.canGoPrevious; onClicked: card.p.previous() }
                RoundButton {
                    icon: card.p && card.p.isPlaying ? "pause" : "play"
                    filled: true
                    hue: card.hue
                    implicitWidth: 40
                    enabled: !!card.p
                    onClicked: card.p.togglePlaying()
                }
                RoundButton { icon: "next"; enabled: card.p && card.p.canGoNext; onClicked: card.p.next() }
                RoundButton {   // off -> whole list -> this track
                    visible: !!card.p && card.p.loopSupported
                    readonly property int state: visible ? card.p.loopState : MprisLoopState.None
                    icon: state === MprisLoopState.Track ? "repeat-once" : "repeat"
                    hue: card.hue
                    filled: state !== MprisLoopState.None
                    enabled: visible && card.p.canControl
                    onClicked: card.p.loopState = state === MprisLoopState.None ? MprisLoopState.Playlist
                        : state === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
                }
                Row {
                    visible: !!card.p && card.p.volumeSupported
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 6
                    spacing: 6
                    Icon { name: "volume-high"; size: 13; color: Theme.dim; anchors.verticalCenter: parent.verticalCenter }
                    Meter { value: card.p ? card.p.volume : 0; ramp: "mem"; segments: 10; segW: 3; segH: 8; anchors.verticalCenter: parent.verticalCenter }
                }
            }
        }
    }

    // ── visualizer: one column per frequency band, in blocks ──
    Item {
        id: vis
        readonly property int block: 5
        visible: Cava.levels.length > 0
        width: parent.width
        height: Cava.range * block
        Row {
            anchors.bottom: parent.bottom
            spacing: 2
            Repeater {
                model: Cava.bars
                Rectangle {
                    required property int index
                    anchors.bottom: parent.bottom
                    width: 12
                    height: Math.max(1, (Cava.levels[index] || 0) * vis.block)
                    color: Theme.ramp("time", index / (Cava.bars - 1))
                }
            }
        }
        // gaps that cut the columns into blocks
        Column {
            spacing: vis.block - 1
            Repeater {
                model: Cava.range
                Rectangle { width: vis.width; height: 1; color: Theme.surface }
            }
        }
    }
}
