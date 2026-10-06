import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import "../singletons"

Item {
    id: root

    property int tab: 0
    property int band: 0
    readonly property var tabs: ["OUTPUT", "VOLUME", "MICROPHONE", "EQUALISER"]

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    function setVol(n, v) {
        if (n?.audio) n.audio.volume = Math.max(0, Math.min(1, v))
    }

    function isKey(e, ...keys) {
        return keys.includes(e.key)
    }

    function handleKey(e) {
        if (isKey(e, Qt.Key_Tab)) tab = (tab + 1) % 4
        else if (isKey(e, Qt.Key_Backtab)) tab = (tab + 3) % 4
        else if (tab === 0) {
            if (isKey(e, Qt.Key_J, Qt.Key_Down)) outList.sel = Math.min(sinks.length - 1, outList.sel + 1)
            else if (isKey(e, Qt.Key_K, Qt.Key_Up)) outList.sel = Math.max(0, outList.sel - 1)
            else if (isKey(e, Qt.Key_Return, Qt.Key_Enter)) Pipewire.preferredDefaultAudioSink = sinks[outList.sel]
            else return
        } else if (tab === 1) {
            if (isKey(e, Qt.Key_H, Qt.Key_Left)) setVol(sink, (sink?.audio?.volume ?? 0) - 0.05)
            else if (isKey(e, Qt.Key_L, Qt.Key_Right)) setVol(sink, (sink?.audio?.volume ?? 0) + 0.05)
            else if (isKey(e, Qt.Key_M) && sink?.audio) sink.audio.muted = !sink.audio.muted
            else return
        } else if (tab === 2) {
            if (isKey(e, Qt.Key_J, Qt.Key_Down)) micList.sel = Math.min(sources.length - 1, micList.sel + 1)
            else if (isKey(e, Qt.Key_K, Qt.Key_Up)) micList.sel = Math.max(0, micList.sel - 1)
            else if (isKey(e, Qt.Key_Return, Qt.Key_Enter)) Pipewire.preferredDefaultAudioSource = sources[micList.sel]
            else if (isKey(e, Qt.Key_H, Qt.Key_Left)) setVol(source, (source?.audio?.volume ?? 0) - 0.05)
            else if (isKey(e, Qt.Key_L, Qt.Key_Right)) setVol(source, (source?.audio?.volume ?? 0) + 0.05)
            else if (isKey(e, Qt.Key_M) && source?.audio) source.audio.muted = !source.audio.muted
            else return
        } else {
            if (isKey(e, Qt.Key_H, Qt.Key_Left)) band = Math.max(0, band - 1)
            else if (isKey(e, Qt.Key_L, Qt.Key_Right)) band = Math.min(9, band + 1)
            else if (isKey(e, Qt.Key_K, Qt.Key_Up)) Eq.setGain(band, Eq.gains[band] + 1)
            else if (isKey(e, Qt.Key_J, Qt.Key_Down)) Eq.setGain(band, Eq.gains[band] - 1)
            else if (isKey(e, Qt.Key_P)) {
                const i = Eq.presetNames.indexOf(Eq.preset)
                Eq.applyPreset(Eq.presetNames[(i + 1) % Eq.presetNames.length])
            }
            else if (isKey(e, Qt.Key_0)) Eq.applyPreset("Flat")
            else return
        }
        e.accepted = true
    }

    Column {
        anchors.fill: parent
        spacing: 16

        Text {
            text: "Lost from Light"
            color: Theme.rose
            font.family: Theme.titleFont
            font.pixelSize: 22
            font.bold: true
            font.letterSpacing: 4
        }

        Row {
            spacing: 28

            Repeater {
                model: root.tabs

                Item {
                    id: tabItem
                    required property string modelData
                    required property int index
                    readonly property bool on: index === root.tab

                    width: tabLabel.implicitWidth
                    height: tabLabel.implicitHeight + 8

                    Text {
                        id: tabLabel
                        text: tabItem.modelData
                        color: tabItem.on ? Theme.text : Theme.mist
                        font.family: Theme.titleFont
                        font.pixelSize: 11
                        font.letterSpacing: 2
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    Rectangle {
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                        width: tabItem.on ? parent.width : 0
                        height: 1
                        color: Theme.soulflame
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tab = tabItem.index
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height - y

            DeviceList {
                id: outList
                visible: root.tab === 0
                anchors.fill: parent
                anchors.bottomMargin: 24
                model: root.sinks
                current: root.sink
                onPicked: node => Pipewire.preferredDefaultAudioSink = node
            }

            Column {
                visible: root.tab === 1
                width: parent.width
                y: 16
                spacing: 14

                Text {
                    text: root.sink?.audio?.muted ? "silenced" : Math.round((root.sink?.audio?.volume ?? 0) * 100) + "%"
                    color: Theme.text
                    font.family: Theme.titleFont
                    font.pixelSize: 44
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.sink ? (root.sink.description || root.sink.name) : "no voice"
                    color: Theme.mist
                    font.family: Theme.accentFont
                    font.pixelSize: 15
                    font.capitalization: Font.AllLowercase
                }
                RuneSlider {
                    width: parent.width
                    value: root.sink?.audio?.volume ?? 0
                    onMoved: v => root.setVol(root.sink, v)
                }
            }

            Column {
                visible: root.tab === 2
                anchors.fill: parent
                spacing: 14

                DeviceList {
                    id: micList
                    width: parent.width
                    height: Math.min(contentHeight, 200)
                    model: root.sources
                    current: root.source
                    onPicked: node => Pipewire.preferredDefaultAudioSource = node
                }
                Text {
                    text: root.source?.audio?.muted ? "silenced" : Math.round((root.source?.audio?.volume ?? 0) * 100) + "%"
                    color: Theme.text
                    font.family: Theme.titleFont
                    font.pixelSize: 28
                }
                RuneSlider {
                    width: parent.width
                    value: root.source?.audio?.volume ?? 0
                    onMoved: v => root.setVol(root.source, v)
                }
            }

            Column {
                visible: root.tab === 3
                width: parent.width
                spacing: 18

                Row {
                    spacing: 24

                    Repeater {
                        model: Eq.presetNames

                        Text {
                            required property string modelData
                            text: modelData.toUpperCase()
                            color: Eq.preset === modelData ? Theme.text : Theme.mist
                            font.family: Theme.titleFont
                            font.pixelSize: 10
                            font.letterSpacing: 2

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Eq.applyPreset(parent.modelData)
                            }
                        }
                    }
                }

                Row {
                    spacing: 10
                    opacity: Eq.available ? 1 : 0.3

                    Repeater {
                        model: Eq.labels

                        Item {
                            id: bandItem
                            required property string modelData
                            required property int index
                            readonly property real g: Eq.gains[index]
                            readonly property bool on: index === root.band

                            width: 48
                            height: 250

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: (bandItem.g > 0 ? "+" : "") + bandItem.g
                                color: bandItem.on ? Theme.text : Theme.mist
                                font.family: Theme.bodyFont
                                font.pixelSize: 11
                            }

                            Item {
                                y: 22
                                width: parent.width
                                height: 200

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 2
                                    height: parent.height
                                    color: Theme.steel
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: parent.height / 2
                                    width: 10
                                    height: 1
                                    color: Theme.ember
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: bandItem.on ? 4 : 2
                                    height: Math.abs(bandItem.g) / 12 * parent.height / 2
                                    y: bandItem.g >= 0 ? parent.height / 2 - height : parent.height / 2
                                    color: bandItem.on ? Theme.soulflame : Theme.mist
                                    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: m => {
                                        root.band = bandItem.index
                                        Eq.setGain(bandItem.index, (0.5 - m.y / height) * 24)
                                    }
                                    onPositionChanged: m => {
                                        if (pressed) Eq.setGain(bandItem.index, (0.5 - m.y / height) * 24)
                                    }
                                }
                            }

                            Text {
                                y: 230
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: bandItem.modelData
                                color: bandItem.on ? Theme.text : Theme.mist
                                font.family: Theme.titleFont
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                Text {
                    visible: !Eq.available
                    text: "the equaliser sleeps"
                    color: Theme.mist
                    font.family: Theme.accentFont
                    font.pixelSize: 15
                }
            }

            Text {
                anchors.bottom: parent.bottom
                text: root.tab === 0 ? "⇥ ASPECT    J K · SEEK    ⏎ BIND"
                    : root.tab === 1 ? "⇥ ASPECT    H L · ADJUST    M · SILENCE"
                    : root.tab === 2 ? "⇥ ASPECT    J K · SEEK    ⏎ BIND    H L · ADJUST    M · SILENCE"
                    : "⇥ ASPECT    H L · BAND    J K · GAIN    P · PRESET    0 · FLAT"
                color: Theme.mist
                opacity: 0.6
                font.family: Theme.titleFont
                font.pixelSize: 9
                font.letterSpacing: 2
            }
        }
    }
}
