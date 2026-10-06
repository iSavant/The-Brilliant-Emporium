import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../singletons"

Scope {
    id: scope

    function toggle() {
        loader.active = true
        loader.item.toggle()
    }

    GlobalShortcut {
        name: "power"
        onPressed: scope.toggle()
    }

    IpcHandler {
        target: "power"
        function toggle(): void { scope.toggle() }
    }

    LazyLoader {
        id: loader

PanelWindow {
    id: root

    readonly property int panelW: 260
    readonly property int rowH: 44
    readonly property int headerH: 64
    readonly property int panelH: headerH + actions.length * rowH + 16
    readonly property real glass: 0.1
    readonly property real barOver: 0.05
    readonly property real backdrop: 0.15

    readonly property var actions: [
        { label: "SUSPEND",  icon: String.fromCodePoint(0x16C1), confirm: false, cmd: ["systemctl", "suspend"] },
        { label: "LOGOUT",   icon: String.fromCodePoint(0x16B1), confirm: true,  cmd: ["loginctl", "terminate-user", Quickshell.env("USER")] },
        { label: "REBOOT",   icon: String.fromCodePoint(0x16C3), confirm: true,  cmd: ["systemctl", "reboot"] },
        { label: "SHUTDOWN", icon: String.fromCodePoint(0x16BA), confirm: true,  cmd: ["systemctl", "poweroff"] }
    ]

    property bool shown: false
    property int sel: 0
    property int armed: -1

    onSelChanged: armed = -1

    property real barH: 0
    property real openW: 0

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    visible: shown

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-power"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    function toggle() {
        if (shown && !closeAnim.running) closeMenu()
        else openMenu()
    }
    function openMenu() {
        closeAnim.stop()
        sel = 0
        armed = -1
        shown = true
        openAnim.start()
        focusKick.restart()
    }

    function closeMenu() {
        if (!shown || closeAnim.running) return
        openAnim.stop()
        closeAnim.start()
    }

    function move(d) {
        sel = (sel + d + actions.length) % actions.length
    }

    function activate(i) {
        const a = actions[i]
        if (a.confirm && armed !== i) {
            armed = i
            disarm.restart()
            return
        }
        closeMenu()
        Quickshell.execDetached(a.cmd)
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = -1
    }

    Timer {
        id: focusKick
        interval: 30
        onTriggered: keys.forceActiveFocus()
    }

    SequentialAnimation {
        id: openAnim
        NumberAnimation {
            target: root; property: "barH"; to: 1
            duration: 220
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
        }
        NumberAnimation {
            target: root; property: "openW"; to: 1
            duration: 320
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
        }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation {
            target: root; property: "openW"; to: 0
            duration: 260
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
        }
        NumberAnimation {
            target: root; property: "barH"; to: 0
            duration: 200
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
        }
        ScriptAction { script: root.shown = false }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.night
        opacity: root.backdrop * root.barH
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeMenu()
    }

    Item {
        id: keys
        Keys.onEscapePressed: root.closeMenu()
        Keys.onUpPressed: root.move(-1)
        Keys.onDownPressed: root.move(1)
        Keys.onReturnPressed: root.activate(root.sel)
        Keys.onEnterPressed: root.activate(root.sel)
    }

    Item {
        id: frame
        anchors {
            right: parent.right; rightMargin: -2
            verticalCenter: parent.verticalCenter
        }
        width: root.panelW * root.openW
        height: root.panelH
        clip: true

        Item {
            id: panel
            anchors.right: parent.right
            width: root.panelW
            height: root.panelH

            MouseArea { anchors.fill: parent }

            Rectangle {
                anchors.fill: parent
                color: Theme.night
                opacity: 0.1
            }

            Column {
                x: 22; y: 14
                spacing: 2

                Text {
                    text: "THE END"
                    color: Theme.text
                    font.family: Theme.titleFont
                    font.pixelSize: 14
                    font.letterSpacing: 4
                }
                Text {
                    text: "every nightmare must wake"
                    color: Theme.mist
                    font.family: Theme.accentFont
                    font.pixelSize: 14
                }
            }

            Column {
                id: rows
                y: root.headerH
                width: parent.width

                Repeater {
                    model: root.actions

                    Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool current: index === root.sel
                        readonly property bool isArmed: index === root.armed

                        width: rows.width
                        height: root.rowH

                        Rectangle {
                            anchors {
                                fill: parent
                                leftMargin: 8; rightMargin: 8
                                topMargin: 3; bottomMargin: 3
                            }

                            color: row.isArmed ? Theme.criticalDark : Theme.ember
                            opacity: row.isArmed ? 0.6 : (row.current ? 0.3 : 0)
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        Rectangle {
                            x: 8; y: 12
                            width: 2
                            height: row.current ? 20 : 0
                            color: row.isArmed ? Theme.crimson : Theme.soulflame
                            Behavior on height {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Theme.curve
                                }
                            }
                        }

                        Text {
                            x: 24
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.icon
                            color: row.isArmed ? Theme.rose
                                 : row.current ? Theme.soulflame : Theme.mist
                            font.family: Theme.iconFont
                            font.pixelSize: 16
                        }

                        Text {
                            x: 54
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.label
                            color: row.current ? Theme.text : Theme.mist
                            font.family: Theme.titleFont
                            font.pixelSize: 12
                            font.letterSpacing: 3
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            anchors {
                                right: parent.right; rightMargin: 20
                                verticalCenter: parent.verticalCenter
                            }
                            text: "again"
                            color: Theme.crimson
                            opacity: row.isArmed ? 1 : 0
                            font.family: Theme.accentFont
                            font.pixelSize: 15
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.sel = row.index
                            onClicked: {
                                root.sel = row.index
                                root.activate(row.index)
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        width: 2
        height: root.panelH * (1 + 2 * root.barOver) * root.barH
        x: frame.x - 1
        y: frame.y + (frame.height - height) / 2
        color: Theme.soulflame
        opacity: 0.8
    }
}
}
}
