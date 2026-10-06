import Quickshell
import QtQuick
import QtQuick.Effects
import "../singletons"

PanelWindow {
    anchors { top: true; right: true }
    exclusiveZone: 0
    margins { top: 6; right: 0 }
    implicitWidth: 380
    implicitHeight: 400
    color: "transparent"

    visible: Notifs.popups.count > 0 || linger.running
    mask: Region { item: list }

    Timer {
        id: linger
        interval: 1070
    }

    Connections {
        target: Notifs.popups
        function onCountChanged() {
            if (Notifs.popups.count === 0) linger.restart()
        }
    }

    ListView {
        id: list
        width: parent.width
        height: contentHeight
        interactive: false
        spacing: 6
        model: Notifs.popups



        remove: Transition {
            SequentialAnimation {
                NumberAnimation { property: "flowIn"; to: 0; duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
                NumberAnimation { property: "colH"; to: 0; duration: 160; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
                NumberAnimation { property: "appFade"; to: 0; duration: 140; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
                NumberAnimation { property: "pillW"; to: 0; duration: 240; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
                NumberAnimation { property: "iconSharp"; to: 0; duration: 140; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
                NumberAnimation { property: "iconFade"; to: 0; duration: 140; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
            }
        }

        displaced: Transition {
            NumberAnimation { property: "y"; duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
        }

        delegate: Item {
            id: toast

            required property int nid
            required property string summary
            required property string appName
            required property bool critical

            property real iconFade: 0
            property real iconSharp: 0
            property real pillW: 0
            property real appFade: 0
            property real colH: 0
            property real flowIn: 0

            Component.onCompleted: entryAnim.start()

            SequentialAnimation {
                id: entryAnim
                NumberAnimation { target: toast; property: "iconFade"; to: 1; duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
                NumberAnimation { target: toast; property: "iconSharp"; to: 1; duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
                NumberAnimation { target: toast; property: "pillW"; to: 1; duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
                NumberAnimation { target: toast; property: "appFade"; to: 1; duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
                NumberAnimation { target: toast; property: "colH"; to: 1; duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
                NumberAnimation { target: toast; property: "flowIn"; to: 1; duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
            }

            width: list.width
            height: 26

            SequentialAnimation {
                running: !toast.critical
                paused: hover.hovered
                PauseAnimation { duration: Notifs.popupTimeout }
                ScriptAction { script: Notifs.hidePopup(toast.nid) }
            }

            HoverHandler { id: hover }
            TapHandler { onTapped: Notifs.dismiss(toast.nid) }

            Rectangle {
                anchors.right: diamond.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: (content.width + 31) * toast.pillW
                height: 20
                radius: 10
                color: toast.critical ? Theme.criticalDark : Theme.night
                opacity: 0.55
            }

            Row {
                id: content
                anchors.right: diamond.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: toast.appName.toUpperCase()
                    color: toast.critical ? Theme.text : Theme.mist
                    opacity: toast.appFade
                    font.family: Theme.titleFont
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: 16

                    Rectangle {
                        anchors.top: parent.top
                        width: 2
                        height: 16 * toast.colH
                        radius: 1
                        color: toast.critical ? Theme.crimson : Theme.soulflame
                    }
                }

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(senderText.implicitWidth, 200)
                    height: senderText.implicitHeight

                    Item {
                        y: -8
                        width: parent.width
                        height: parent.height + 16
                        clip: true

                        Text {
                            id: senderText
                            y: 8
                            x: -width * (1 - toast.flowIn)
                            width: Math.min(implicitWidth, 200)
                            text: toast.summary
                            elide: Text.ElideRight
                            color: Theme.text
                            font.family: Theme.accentFont
                            font.pixelSize: 14
                            font.capitalization: Font.AllLowercase
                        }
                    }
                }
            }

            Image {
                id: diamond
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                z: 2
                source: toast.critical ? "../assets/diamond_crimson.svg"
                                       : "../assets/diamond_steel.svg"
                sourceSize: Qt.size(44, 44)
                opacity: toast.iconFade

                layer.enabled: toast.iconSharp < 1
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 1 - toast.iconSharp
                    blurMax: 24
                }
            }
        }
    }
}
