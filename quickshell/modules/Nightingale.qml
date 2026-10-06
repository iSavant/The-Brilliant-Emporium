import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects
import "../singletons"

Item {
    id: root

    property string chosen: ""
    property var lastActive: null
    readonly property string preferred: "ncspot"
    readonly property var players: Mpris.players.values
    readonly property var live: players.filter(p => p.isPlaying || (p.trackTitle || "") !== "")
    property bool summoning: false

    readonly property var player: {
        const ps = live
        const named = n => ps.find(p => (p.identity || "").toLowerCase() === n.toLowerCase())
        if (chosen !== "") { const c = named(chosen); if (c) return c }
        return named(preferred)
            ?? ps.find(p => p.isPlaying)
            ?? (lastActive ? ps.find(p => p === lastActive) : null)
            ?? ps[0]
            ?? null
    }

    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property var modelData
            target: modelData
            function onIsPlayingChanged() {
                if (modelData.isPlaying) root.lastActive = modelData
            }
        }
    }

    function fmt(s) {
        s = Math.max(0, Math.floor(s || 0))
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0")
    }

    function playPause() {
        if (!player) return
        if (player.canTogglePlaying) player.togglePlaying()
        else if (player.isPlaying) { if (player.canPause) player.pause() }
        else if (player.canPlay) player.play()
    }

    function summon() {
        console.log("summon called")
        const n = players.find(p => (p.identity || "").toLowerCase() === preferred)
        if (n) { if (n.canPlay) n.play(); return }
        if (summoning) return
        summoning = true
        summonWait.restart()
        Quickshell.execDetached(["kitty", "--class", "ncspot", "-e", "ncspot"])
    }

    function seekBy(d) {
        if (player?.canSeek) player.position = Math.max(0, Math.min(player.length, player.position + d))
    }

    function handleKey(e) {
        const k = e.key
        if (!player) {
            if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) { summon(); e.accepted = true }
            return
        }
        if (k === Qt.Key_Tab) {
            const i = live.indexOf(player)
            chosen = live[(i + 1) % live.length].identity || ""
        }
        else if (k === Qt.Key_Space || k === Qt.Key_Return || k === Qt.Key_Enter) playPause()
        else if (k === Qt.Key_L || k === Qt.Key_Right) { if (player.canGoNext) player.next() }
        else if (k === Qt.Key_H || k === Qt.Key_Left) { if (player.canGoPrevious) player.previous() }
        else if (k === Qt.Key_K || k === Qt.Key_Up) seekBy(10)
        else if (k === Qt.Key_J || k === Qt.Key_Down) seekBy(-10)
        else return
        e.accepted = true
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.player?.isPlaying ?? false
        onTriggered: root.player.positionChanged()
    }

    Timer {
        id: summonWait
        interval: 500
        repeat: true
        property int tries: 0
        onTriggered: {
            const n = root.players.find(p => (p.identity || "").toLowerCase() === root.preferred)
            if (n && n.canPlay) { n.play(); root.summoning = false; tries = 0; stop() }
            else if (++tries > 20) { root.summoning = false; tries = 0; stop() }
        }
    }

    Column {
        anchors.fill: parent
        spacing: 16

        Text {
            text: "Nightingale"
            color: Theme.rose
            font.family: Theme.titleFont
            font.pixelSize: 22
            font.bold: true
            font.letterSpacing: 4
        }

        Row {
            visible: root.live.length > 1
            spacing: 24

            Repeater {
                model: root.players

                Text {
                    required property var modelData
                    text: (modelData.identity || "player").toUpperCase()
                    color: modelData === root.player ? Theme.text : Theme.mist
                    font.family: Theme.titleFont
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.chosen = parent.modelData.identity || ""
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height - y

            Column {
                anchors.centerIn: parent
                visible: !root.player
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.summoning ? "summoning…" : "silence."
                    color: Theme.mist
                    font.family: Theme.accentFont
                    font.pixelSize: 18
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !root.summoning
                    text: "⏎ · SUMMON THE NIGHTINGALE"
                    color: Theme.mist
                    opacity: 0.6
                    font.family: Theme.titleFont
                    font.pixelSize: 9
                    font.letterSpacing: 2
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.summon()
                    }
                }
            }

            Row {
                visible: !!root.player
                width: parent.width
                spacing: 24

                Item {
                    width: 220
                    height: 220

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: Theme.shade
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: art.status !== Image.Ready
                        text: "ᛚ"
                        color: Theme.steel
                        font.family: Theme.runeFont
                        font.pixelSize: 64
                    }

                    Image {
                        id: art
                        anchors.fill: parent
                        source: root.player?.trackArtUrl ?? ""
                        sourceSize: Qt.size(440, 440)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                    }

                    MultiEffect {
                        anchors.fill: art
                        source: art
                        visible: art.status === Image.Ready
                        saturation: -1
                        brightness: -0.05
                        maskEnabled: false
                    }
                }

                Column {
                    width: parent.width - 244
                    spacing: 6

                    Text {
                        width: parent.width
                        text: root.player?.trackTitle || "untitled"
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        color: Theme.text
                        font.family: Theme.titleFont
                        font.pixelSize: 18
                        font.letterSpacing: 1
                    }
                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: root.player?.trackArtist ?? ""
                        elide: Text.ElideRight
                        color: Theme.mist
                        font.family: Theme.accentFont
                        font.pixelSize: 16
                        font.capitalization: Font.AllLowercase
                    }
                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: root.player?.trackAlbum ?? ""
                        elide: Text.ElideRight
                        color: Theme.ember
                        font.family: Theme.bodyFont
                        font.pixelSize: 11
                    }

                    Item { width: 1; height: 24 }

                    Row {
                        spacing: 36

                        Repeater {
                            model: [
                                { rune: "ᛃ", act: () => root.player?.previous(), on: () => root.player?.canGoPrevious },
                                { rune: "play", act: () => root.playPause(), on: () => root.player?.canTogglePlaying || root.player?.canPlay || root.player?.canPause },
                                { rune: "ᚱ", act: () => root.player?.next(), on: () => root.player?.canGoNext }
                            ]

                            Text {
                                required property var modelData
                                text: modelData.rune === "play" ? (root.player?.isPlaying ? "ᛁ" : "ᛊ") : modelData.rune
                                color: modelData.rune === "play" ? Theme.soulflame : Theme.text
                                opacity: modelData.on() ? 1 : 0.3
                                font.family: Theme.runeFont
                                font.pixelSize: modelData.rune === "play" ? 34 : 24
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: parent.modelData.act()
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 18 }

                    RuneSlider {
                        width: parent.width
                        value: root.player?.length > 0 ? root.player.position / root.player.length : 0
                        onMoved: v => { if (root.player?.canSeek) root.player.position = v * root.player.length }
                    }

                    Item {
                        width: parent.width
                        height: 14

                        Text {
                            text: root.fmt(root.player?.position)
                            color: Theme.mist
                            font.family: Theme.bodyFont
                            font.pixelSize: 11
                        }
                        Text {
                            anchors.right: parent.right
                            text: root.fmt(root.player?.length)
                            color: Theme.mist
                            font.family: Theme.bodyFont
                            font.pixelSize: 11
                        }
                    }
                }
            }

            Text {
                anchors.bottom: parent.bottom
                text: "␣ ⏎ · PLAY    H L · PREVIOUS / NEXT    J K · SEEK    ⇥ · NEXT SINGER"
                color: Theme.mist
                opacity: 0.6
                font.family: Theme.titleFont
                font.pixelSize: 9
                font.letterSpacing: 2
            }
        }
    }
}
