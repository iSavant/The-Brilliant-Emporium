import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Effects
import "../singletons"

Scope {
    id: scope

    function toggle() {
        loader.active = true
        loader.item.toggle()
    }

    GlobalShortcut {
        name: "wallpaper"
        onPressed: scope.toggle()
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { scope.toggle() }
    }

    LazyLoader {
        id: loader

        PanelWindow {
            id: root

            readonly property int perScreen: 5
            readonly property int tileH: 600
            readonly property int gap: 200

            property bool shown: false
            property bool moved: false
            property real fade: 0

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            visible: shown

            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "quickshell-wallpaper-picker"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.exclusionMode: ExclusionMode.Ignore

            function toggle() {
                if (shown && !closeAnim.running) closePicker()
                else openPicker()
            }

            function place() {
                if (Wallpaper.files.length === 0) return
                const i = Math.max(0, Wallpaper.files.indexOf(Wallpaper.current))
                strip.currentIndex = i
                strip.positionViewAtIndex(i, PathView.Center)
            }

            function openPicker() {
                closeAnim.stop()
                moved = false
                shown = true
                Wallpaper.rescan()
                Qt.callLater(place)
                openAnim.start()
                focusKick.restart()
                reveal(true)
            }

            function closePicker() {
                if (!shown || closeAnim.running) return
                openAnim.stop()
                closeAnim.start()
                reveal(false)
            }

            function reveal(on) {
                Quickshell.execDetached(["hyprctl", "eval", "require(\"modules.look\").reveal(" + on + ")"])
            }

            function apply() {
                const f = Wallpaper.files[strip.currentIndex]
                if (f) Wallpaper.set(f)
                closePicker()
            }

            function step(d) {
                moved = true
                if (d > 0) strip.incrementCurrentIndex()
                else strip.decrementCurrentIndex()
            }

            Connections {
                target: Wallpaper
                function onFilesChanged() {
                    if (root.shown && !root.moved) Qt.callLater(root.place)
                }
            }

            Timer {
                id: focusKick
                interval: 30
                onTriggered: strip.forceActiveFocus()
            }

            SequentialAnimation {
                id: openAnim
                NumberAnimation { target: root; property: "fade"; to: 1; duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
            }

            SequentialAnimation {
                id: closeAnim
                NumberAnimation { target: root; property: "fade"; to: 0; duration: 240; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
                ScriptAction { script: root.shown = false }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.closePicker()
            }

            PathView {
                id: strip

                readonly property real tileW: width / root.perScreen
                readonly property int slots: Math.min(Wallpaper.files.length, root.perScreen + 2)

                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: root.tileH + 60
                model: Wallpaper.files
                opacity: root.fade
                pathItemCount: slots
                preferredHighlightBegin: 0.5
                preferredHighlightEnd: 0.5
                highlightRangeMode: PathView.StrictlyEnforceRange
                snapMode: PathView.SnapOneItem
                highlightMoveDuration: 420

                path: Path {
                    startX: strip.width / 2 - strip.tileW * strip.slots / 2
                    startY: strip.height / 2
                    PathLine {
                        x: strip.width / 2 + strip.tileW * strip.slots / 2
                        y: strip.height / 2
                    }
                }

                onMovementStarted: root.moved = true

                Keys.onPressed: event => {
                    const k = event.key
                    if (k === Qt.Key_Escape) root.closePicker()
                    else if (k === Qt.Key_Left || k === Qt.Key_H) root.step(-1)
                    else if (k === Qt.Key_Right || k === Qt.Key_L) root.step(1)
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.apply()
                    else return
                    event.accepted = true
                }

                delegate: Item {
                    id: cell
                    required property string modelData
                    required property int index
                    readonly property bool sel: PathView.isCurrentItem
                    readonly property bool isCurrent: modelData === Wallpaper.current

                    readonly property real centreX: x + width / 2
                    readonly property real dist: Math.min(1, Math.abs(centreX - strip.width / 2) / (strip.width / 2))
                    readonly property real near: 1 - dist * dist * (3 - 2 * dist)
                    readonly property real s: 0.3 + 0.55 * near
                    readonly property real pull: 80 * dist * dist * dist * dist * (centreX < strip.width / 2 ? 1 : -1)

                    width: strip.tileW
                    height: strip.height

                    Item {
                        id: card
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: cell.pull
                        width: (strip.tileW - root.gap) * cell.s
                        height: root.tileH * cell.s
                        opacity: 0.35 + 0.65 * cell.near

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: "black"
                            shadowOpacity: 0.6
                            shadowBlur: 0.6
                            shadowHorizontalOffset: 6
                            shadowVerticalOffset: 8
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: Theme.shade
                        }

                        Image {
                            anchors.fill: parent
                            source: Wallpaper.thumb(cell.modelData)
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(1024, 640)
                            asynchronous: true
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.width: cell.sel ? 2 : 1
                            border.color: cell.sel ? Theme.soulflame : Theme.steel
                            Behavior on border.color { ColorAnimation { duration: 240 } }
                        }

                        Text {
                            visible: Wallpaper.isLive(cell.modelData)
                            anchors { left: parent.left; bottom: parent.bottom; margins: 8 }
                            text: "LIVE"
                            color: Theme.soulflame
                            font.family: Theme.titleFont
                            font.pixelSize: 9
                            font.letterSpacing: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.moved = true
                                if (cell.sel) root.apply()
                                else strip.currentIndex = cell.index
                            }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: card.horizontalCenter
                        anchors.top: card.bottom
                        anchors.topMargin: 10
                        visible: cell.isCurrent
                        width: 32
                        height: 2
                        color: Theme.soulflame
                    }
                }
            }

            Text {
                anchors { bottom: parent.bottom; bottomMargin: 40; horizontalCenter: parent.horizontalCenter }
                opacity: 0.6 * root.fade
                text: "H L · SEEK    ⏎ · DREAM IT    ESC · WAKE"
                color: Theme.mist
                font.family: Theme.titleFont
                font.pixelSize: 9
                font.letterSpacing: 2
            }
        }
    }
}
