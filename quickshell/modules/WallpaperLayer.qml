import Quickshell
import Quickshell.Wayland
import QtQuick
import "../singletons"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win
        required property var modelData
        screen: modelData

        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: Theme.night

        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell-wallpaper"

        property string shownPath: Wallpaper.current
        property string nextPath: ""
        property real progress: 0

        Connections {
            target: Wallpaper
            function onChangeRequested(path) {
                if (anim.running) anim.complete()
                win.nextPath = path
                nextImg.source = "file://" + path
            }
        }

        Image {
            id: curImg
            anchors.fill: parent
            source: win.shownPath ? "file://" + win.shownPath : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(width, height)
            asynchronous: true
        }

        Image {
            id: nextImg
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(width, height)
            asynchronous: true
            onStatusChanged: if (status === Image.Ready && win.nextPath !== "") anim.restart()
        }

        ShaderEffectSource {
            id: oldSrc
            sourceItem: curImg
            hideSource: fx.visible
        }

        ShaderEffectSource {
            id: newSrc
            sourceItem: nextImg
            hideSource: true
        }

        Row {
            id: atlasRow
            Repeater {
                model: 24
                Text {
                    required property int index
                    width: 32
                    height: 32
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: String.fromCodePoint(0x16A0 + index * 3)
                    color: "white"
                    font.family: Theme.runeFont
                    font.pixelSize: 24
                }
            }
        }

        ShaderEffectSource {
            id: atlasSrc
            sourceItem: atlasRow
            hideSource: true
        }

        ShaderEffect {
            id: fx
            anchors.fill: parent
            visible: anim.running

            property var oldTex: oldSrc
            property var newTex: newSrc
            property var atlas: atlasSrc
            property real progress: win.progress
            property real time: win.progress * 30
            property point res: Qt.point(width, height)
            property real cell: 22
            property real runes: 24

            fragmentShader: Qt.resolvedUrl("wallpaper/ink.frag.qsb")
        }

        SequentialAnimation {
            id: anim
            NumberAnimation { target: win; property: "progress"; from: 0; to: 1; duration: 2400 }
            ScriptAction {
                script: {
                    win.shownPath = win.nextPath
                    Wallpaper.commit(win.nextPath)
                    win.progress = 0
                }
            }
        }

        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 200
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(Theme.night.r, Theme.night.g, Theme.night.b, 0.3) }
                GradientStop { position: 0.1; color: Qt.rgba(Theme.night.r, Theme.night.g, Theme.night.b, 0.27) }
                GradientStop { position: 0.2; color: Qt.rgba(Theme.night.r, Theme.night.g, Theme.night.b, 0.24) }
                GradientStop { position: 0.3; color: Qt.rgba(Theme.night.r, Theme.night.g, Theme.night.b, 0.21) }
                GradientStop { position: 0.4; color: Qt.rgba(Theme.night.r, Theme.night.g, Theme.night.b, 0.16) }
                GradientStop { position: 0.5; color: Qt.rgba(Theme.night.r, Theme.night.g, Theme.night.b, 0.11) }
                GradientStop { position: 0.6; color: Qt.rgba(Theme.night.r, Theme.night.g, Theme.night.b, 0.07) }
                GradientStop { position: 0.7; color: Qt.rgba(Theme.night.r, Theme.night.g, Theme.night.b, 0.04) }
                GradientStop { position: 0.8; color: Qt.rgba(Theme.night.r, Theme.night.g, Theme.night.b, 0.02) }
                GradientStop { position: 0.9; color: Qt.rgba(Theme.night.r, Theme.night.g, Theme.night.b, 0.01) }
                GradientStop { position: 1.0; color: Qt.rgba(Theme.night.r, Theme.night.g, Theme.night.b, 0) }
            }
        }
    }
}
