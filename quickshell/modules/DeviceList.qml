import QtQuick
import "../singletons"

ListView {
    id: list

    property var current: null
    property int sel: 0
    signal picked(var node)

    clip: true
    spacing: 4
    boundsBehavior: Flickable.StopAtBounds
    onSelChanged: positionViewAtIndex(sel, ListView.Contain)

    delegate: Item {
        id: row
        required property var modelData
        required property int index
        readonly property bool on: index === list.sel
        readonly property bool bound: modelData === list.current

        width: list.width
        height: 34

        Rectangle {
            anchors.fill: parent
            radius: 6
            color: Theme.ember
            opacity: row.on ? 0.3 : 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
        }

        Rectangle {
            y: 8
            width: 2
            height: row.on ? 18 : 0
            color: Theme.soulflame
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
        }

        Text {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 110
            elide: Text.ElideRight
            text: row.modelData.description || row.modelData.nickname || row.modelData.name
            color: row.bound ? Theme.text : Theme.mist
            font.family: Theme.accentFont
            font.pixelSize: 15
            font.capitalization: Font.AllLowercase
        }

        Text {
            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
            visible: row.bound
            text: "BOUND"
            color: Theme.soulflame
            font.family: Theme.titleFont
            font.pixelSize: 9
            font.letterSpacing: 2
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: list.sel = row.index
            onClicked: list.picked(row.modelData)
        }
    }
}
