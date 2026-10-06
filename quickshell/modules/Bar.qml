import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import "../singletons"

Scope {
    id: barRoot

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 45
            exclusiveZone: 35
            color: "transparent"

            Item {
                id: bar
                anchors.fill: parent

                // some bs on the left
                Rectangle {
                    id: leftIsland

                    anchors {
                        left: parent.left
                        leftMargin: 10
                        verticalCenter: parent.verticalCenter
                        verticalCenterOffset: - 3
                    }

                    width: leftContent.implicitWidth + 14
                    height: 26
                    radius: 13

                    color: Qt.rgba(0, 0, 0, 0.24)

                    Row {
                        id: leftContent

                        anchors {
                            left: parent.left
                            leftMargin: 12
                            verticalCenter: parent.verticalCenter
                        }

                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: Qt.formatDateTime(clock.date, "ddd dd MMM")

                            color: Theme.mist
                            font.family: Theme.titleFont
                            font.bold: true
                            font.pixelSize: 17
                            font.letterSpacing: 0.42
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter

                            text: Qt.formatTime(clock.date, "h:mm")

                            color: Theme.soulflame
                            font.family: Theme.accentFont
                            font.bold: true
                            font.pixelSize: 15
                            font.letterSpacing: 0.69
                        }

                        Item {
                            id: workspaceArea

                            width: workspaceDots.width + 7
                            height: 23

                            Row {
                                id: workspaceDots

                                anchors {
                                    left: parent.left
                                    verticalCenter: parent.verticalCenter
                                }

                                spacing: 6

                                Repeater {
                                    model: 5

                                    Item {
                                        id: dotSlot

                                        required property int index
                                        readonly property bool isCurrent:
                                            index + 1 === Hyprland.focusedWorkspace?.id

                                        width: 10
                                        height: 16

                                        Rectangle {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.top: parent.top
                                            anchors.topMargin: 1

                                            width: dotSlot.isCurrent ? 3 : 7
                                            height: dotSlot.isCurrent ? 30 : 7
                                            radius: 4
                                            color: dotSlot.isCurrent ? Theme.soulflame : Theme.weave

                                            Behavior on height {
                                                NumberAnimation {
                                                    duration: dotSlot.isCurrent ? 200 : 100
                                                    easing.type: Easing.BezierSpline
                                                    easing.bezierCurve: Theme.curve
                                                }
                                            }

                                            Behavior on width {
                                                NumberAnimation {
                                                    duration: 200
                                                    easing.type: Easing.BezierSpline
                                                    easing.bezierCurve: Theme.curve
                                                }
                                            }

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: dotSlot.isCurrent ? 200 : 100
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                id: focusedWindowLabel

                                x: Math.max(0, ((Hyprland.focusedWorkspace?.id ?? 1) * 16) - 6)
                                y: workspaceArea.height / 3

                                width: 220
                                height: 20

                                text: SysInfo.focusedToplevel?.title ?? "Dreaming"

                                color: Theme.text
                                elide: Text.ElideRight

                                font.family: Theme.accentFont
                                font.pixelSize: 15
                                font.capitalization: Font.AllLowercase

                                z: 0

                                Behavior on x {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Theme.curve
                                    }
                                }
                            }
                        }
                    }
                }

                // bs in the middle
                Rectangle {
                    id: centerIsland

                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        verticalCenter: parent.verticalCenter
                        verticalCenterOffset: - 3
                    }

                    width: hostnameText.implicitWidth + 20
                    height: 26

                    radius: 13
                    color: Qt.rgba(0, 0, 0, 0.24)

                    Text {
                        id: hostnameText

                        anchors.centerIn: parent

                        text: SysInfo.host.toUpperCase()

                        color: Theme.mist
                        font.family: Theme.titleFont
                        font.bold: true
                        font.pixelSize: 20
                        font.letterSpacing: 1.0
                    }

                    Text {
                        id: usernameText

                        x: centerIsland.width / 2 + 30
                        y: centerIsland.height / 100

                        text: SysInfo.user

                        color: Theme.soulflame
                        font.family: Theme.accentFont
                        font.pixelSize: 20

                        z: 2
                    }
                }

                // sum bs on the right
                Rectangle {
                    id: rightPill

                    anchors {
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                        verticalCenterOffset: - 3
                    }

                    width: rightContent.implicitWidth + 22
                    height: 26
                    radius: height / 2

                    color: Qt.rgba(0, 0, 0, 0.24)

                    Row {
                        id: rightContent

                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 11
                            rightMargin: 11
                        }

                        spacing: 10

                        Row {
                            id: mediaGroup

                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            visible: dripH > 0

                            property real dripH: 0
                            property real openW: 0
                            property real flowX: 1

                            readonly property int restH: 30

                            property string shownTitle: ""
                            property bool wantOpen: false

                            readonly property string incoming: SysInfo.media
                            onIncomingChanged: sync()
                            Component.onCompleted: sync()

                            function sync() {
                                if (incoming.length > 0) {
                                    shownTitle = incoming
                                    if (!wantOpen) {
                                        wantOpen = true
                                        closeAnim.stop()
                                        openAnim.start()
                                    }
                                } else if (wantOpen) {
                                    wantOpen = false
                                    openAnim.stop()
                                    closeAnim.start()
                                }
                            }

                            SequentialAnimation {
                                id: openAnim

                                NumberAnimation {
                                    target: mediaGroup; property: "dripH"
                                    to: mediaGroup.restH
                                    duration: 280
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Theme.curve
                                }

                                NumberAnimation {
                                    target: mediaGroup; property: "openW"
                                    to: 1
                                    duration: 320
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Theme.curve
                                }

                                NumberAnimation {
                                    target: mediaGroup; property: "flowX"
                                    to: 0
                                    duration: 420
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Theme.curve
                                }
                            }

                            SequentialAnimation {
                                id: closeAnim

                                NumberAnimation {
                                    target: mediaGroup; property: "flowX"
                                    to: 1
                                    duration: 260
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Theme.curve
                                }
                                NumberAnimation {
                                    target: mediaGroup; property: "openW"
                                    to: 0
                                    duration: 280
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Theme.curve
                                }
                                NumberAnimation {
                                    target: mediaGroup; property: "dripH"
                                    to: 0
                                    duration: 220
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Theme.curve
                                }
                            }

                            Item {
                                id: reveal

                                anchors.verticalCenter: parent.verticalCenter
                                width: mediaGroup.openW * content.implicitWidth
                                height: content.implicitHeight

                                Item {
                                    anchors.fill: parent
                                    anchors.topMargin: -10
                                    anchors.bottomMargin: -10
                                    clip: true

                                    Row {
                                        id: content

                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 0
                                        x: parent.width - implicitWidth + mediaGroup.flowX * implicitWidth

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 7
                                            height: 7
                                            radius: 4
                                            color: Theme.steel
                                        }

                                        Text {
                                            text: "  "
                                        }

                                        Item {
                                            id: mediaBox

                                            readonly property int maxW: 180
                                            readonly property int gap: 7
                                            readonly property real speed: 25
                                            readonly property int pad: 10
                                            readonly property bool overflowing:
                                                mediaText.implicitWidth > maxW

                                            anchors.verticalCenter: parent.verticalCenter
                                            width: Math.min(maxW, mediaText.implicitWidth)
                                            height: mediaText.implicitHeight

                                            Item {
                                                y: -mediaBox.pad
                                                width: parent.width
                                                height: parent.height + mediaBox.pad * 2
                                                clip: true

                                                Row {
                                                    id: ticker
                                                    y: mediaBox.pad
                                                    spacing: mediaBox.gap

                                                    Text {
                                                        id: mediaText
                                                        text: mediaGroup.shownTitle + " -"
                                                        color: Theme.mist
                                                        font.family: Theme.accentFont
                                                        font.pixelSize: 15
                                                        font.capitalization: Font.AllLowercase

                                                        onTextChanged: {
                                                            ticker.x = 0
                                                            if (scrollAnim.running)
                                                                scrollAnim.restart()
                                                        }
                                                    }

                                                    Text {
                                                        visible: mediaBox.overflowing
                                                        text: mediaGroup.shownTitle + " -"
                                                        color: Theme.mist
                                                        font.family: Theme.accentFont
                                                        font.pixelSize: 15
                                                        font.capitalization: Font.AllLowercase
                                                    }
                                                }
                                            }

                                            Timer {
                                                id: scrollAnim
                                                readonly property real px: 1 / Screen.devicePixelRatio
                                                interval: 1000 / (mediaBox.speed * Screen.devicePixelRatio)
                                                repeat: true
                                                running: mediaBox.overflowing && mediaGroup.flowX === 0
                                                onTriggered: {
                                                    const span = mediaText.implicitWidth + mediaBox.gap
                                                    ticker.x = ticker.x - px <= -span ? 0 : ticker.x - px
                                                }
                                                onRunningChanged: if (!running) ticker.x = 0
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: 18

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 3
                                    height: mediaGroup.dripH
                                    radius: 2
                                    color: Theme.soulflame
                                }
                            }
                        }

                        Text {
                            id: ramText
                            anchors.verticalCenter: parent.verticalCenter

                            text: "󰍛  " + SysInfo.memory
                            color: Theme.text

                            font.family: Theme.iconFont
                            font.pixelSize: 15
                        }

                        Text {
                            id: networkText
                            anchors.verticalCenter: parent.verticalCenter

                            text: "󰖩"
                            color: Theme.text

                            font.family: Theme.iconFont
                            font.pixelSize: 15

                            visible: SysInfo.networkConnected
                        }

                        Text {
                            id: bluetoothText
                            anchors.verticalCenter: parent.verticalCenter

                            text: "󰂯"
                            color: Theme.text

                            font.family: Theme.iconFont
                            font.pixelSize: 15

                            visible: SysInfo.bluetoothConnected
                        }

                        Text {
                            id: notificationText
                            anchors.verticalCenter: parent.verticalCenter

                            text: "󰂚"
                            color: Theme.text

                            font.family: Theme.iconFont
                            font.pixelSize: 15

                            visible: SysInfo.notifications > 0
                        }
                    }
                }
            }
        }
    }
}
