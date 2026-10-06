import Quickshell
import QtQuick
import "../singletons"

Item {
    id: root

    property int sel: 0
    property int modeSel: 0
    property bool armed: false

    readonly property var modes: ["OFF", "DO NOT DISTURB", "GAMEMODE"]

    Component.onCompleted: modeSel = Notifs.dnd ? 1 : 0

    ScriptModel {
        id: items
        values: [...Notifs.history.values].reverse()
        onValuesChanged: if (root.sel >= values.length) root.sel = Math.max(0, values.length - 1)
    }

    function applyMode(i) {
        if (i === 2) {
            modeSel = 2
            if (!armed) {
                armed = true
                disarm.restart()
                return
            }
            armed = false
            Quickshell.execDetached(["hyprctl", "eval", "require(\"modules.gamemode\").toggle()"])
            return
        }
        armed = false
        modeSel = i
        Notifs.dnd = i === 1
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: {
            root.armed = false
            root.modeSel = Notifs.dnd ? 1 : 0
        }
    }

    function handleKey(e) {
        const k = e.key
        if (k === Qt.Key_H || k === Qt.Key_Left) {
            applyMode(Math.max(0, modeSel - 1))
        } else if (k === Qt.Key_L || k === Qt.Key_Right) {
            applyMode(Math.min(2, modeSel + 1))
        } else if (k === Qt.Key_J || k === Qt.Key_Down) {
            sel = Math.min(items.values.length - 1, sel + 1)
            list.positionViewAtIndex(sel, ListView.Contain)
        } else if (k === Qt.Key_K || k === Qt.Key_Up) {
            sel = Math.max(0, sel - 1)
            list.positionViewAtIndex(sel, ListView.Contain)
        } else if (k === Qt.Key_Return || k === Qt.Key_Enter) {
            if (armed) applyMode(2)
            else items.values[sel]?.dismiss()
        } else if (k === Qt.Key_Delete) {
            if (e.modifiers & Qt.ShiftModifier) Notifs.clearAll()
            else items.values[sel]?.dismiss()
        } else return
        e.accepted = true
    }

    Column {
        anchors.fill: parent
        spacing: 18

        Text {
            text: "Prince of Nothing"
            color: Theme.rose
            font.family: Theme.titleFont
            font.pixelSize: 22
            font.bold: true
            font.letterSpacing: 4
        }

        Row {
            spacing: 28

            Repeater {
                model: root.modes

                Item {
                    id: seg
                    required property string modelData
                    required property int index
                    readonly property bool on: index === root.modeSel

                    width: label.implicitWidth
                    height: label.implicitHeight + 8

                    Text {
                        id: label
                        text: seg.modelData
                        color: seg.on ? (seg.index === 2 && root.armed ? Theme.rose : Theme.text) : Theme.mist
                        font.family: Theme.titleFont
                        font.pixelSize: 11
                        font.letterSpacing: 2
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    Rectangle {
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                        width: seg.on ? parent.width : 0
                        height: 1
                        color: seg.index === 2 && root.armed ? Theme.rose : Theme.soulflame
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyMode(seg.index)
                    }
                }
            }
        }

        Text {
            visible: root.armed
            text: "again, and the world fades"
            color: Theme.mist
            font.family: Theme.accentFont
            font.pixelSize: 14
            font.capitalization: Font.AllLowercase
        }

        Text {
            text: items.values.length + (items.values.length === 1 ? " WHISPER" : " WHISPERS")
            color: Theme.mist
            font.family: Theme.titleFont
            font.pixelSize: 10
            font.letterSpacing: 2
        }

        ListView {
            id: list
            width: parent.width
            height: parent.height - y
            clip: true
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            model: items

            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool current: index === root.sel

                width: list.width
                height: col.implicitHeight + 16

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Theme.ember
                    opacity: row.current ? 0.3 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                Rectangle {
                    x: 0
                    y: 8
                    width: 2
                    height: row.current ? parent.height - 16 : 0
                    color: Theme.soulflame
                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
                }

                Column {
                    id: col
                    x: 16
                    y: 8
                    width: parent.width - 32
                    spacing: 2

                    Text {
                        text: (row.modelData.appName || "unknown").toUpperCase()
                        color: Theme.mist
                        font.family: Theme.titleFont
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                    Text {
                        width: parent.width
                        text: row.modelData.summary
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: Theme.text
                        font.family: Theme.accentFont
                        font.pixelSize: 15
                        font.capitalization: Font.AllLowercase
                    }
                    Text {
                        visible: text !== ""
                        width: parent.width
                        text: row.modelData.body
                        textFormat: Text.PlainText
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        color: Theme.mist
                        font.family: Theme.bodyFont
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.sel = row.index
                    onClicked: row.modelData.dismiss()
                }
            }

            Text {
                anchors.centerIn: parent
                visible: items.values.length === 0
                text: "silence."
                color: Theme.mist
                font.family: Theme.accentFont
                font.pixelSize: 16
            }
        }
    }
}
