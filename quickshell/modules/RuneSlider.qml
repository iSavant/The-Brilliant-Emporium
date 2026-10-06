import QtQuick
import "../singletons"

Item {
    id: s

    property real value: 0
    signal moved(real v)

    readonly property real v: Math.max(0, Math.min(1, value))

    implicitHeight: 22

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 2
        color: Theme.steel
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width * s.v
        height: 2
        color: Theme.soulflame
        Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: parent.width * s.v - 1
        width: 2
        height: 14
        color: Theme.text
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: m => s.moved(m.x / width)
        onPositionChanged: m => { if (pressed) s.moved(m.x / width) }
    }
}
