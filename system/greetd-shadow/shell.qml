import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import QtQuick

ShellRoot {
    id: shell

    readonly property var sessionCmd: ["start-hyprland"]

    FloatingWindow {
        color: "#060708"
        implicitWidth: 1920
        implicitHeight: 1080

        Item {
            id: root
            anchors.fill: parent

            readonly property color night:     "#060708"
            readonly property color steel:     "#343B40"
            readonly property color slate:     "#464D52"
            readonly property color mist:      "#8E8A8C"
            readonly property color textCol:   "#D8D1D3"
            readonly property color soulflame: "#BAB7B6"
            readonly property color glow:      "#F2F0EE"
            readonly property var curve: [0.4, 0, 0.2, 1, 1, 1]

            FontLoader { id: titleF; source: "fonts/title.ttf" }
            FontLoader { id: accentF; source: "fonts/accent.ttf" }
            readonly property string titleFont: titleF.name
            readonly property string accentFont: accentF.name

            property var users: []
            property string host: ""

            FileView {
                path: "/etc/passwd"
                onLoaded: root.users = text().split("\n")
                    .map(l => l.split(":"))
                    .filter(f => f.length > 6
                        && +f[2] >= 1000 && +f[2] < 60000
                        && !/nologin|false/.test(f[6]))
                    .map(f => f[0])
            }

            FileView {
                path: "/etc/hostname"
                onLoaded: root.host = text().trim()
            }

            property int userIdx: 0
            property bool chosen: false
            property string chosenName: ""
            property bool busy: false
            property real p: 0
            property real gridIn: 0
            property real shakeX: 0
            property real runesIn: 0
            property int tick: 0
            property real unlockT: 0

            readonly property var glyphs: Array.from({ length: 75 },
                (_, i) => String.fromCodePoint(0x16A0 + i))

            Timer {
                id: burst
                interval: 700
            }

            Timer {
                interval: 60
                repeat: true
                running: (root.runesIn > 0 && root.runesIn < 1) || burst.running || exitAnim.running
                onTriggered: root.tick++
            }

            function choose() {
                const item = names.itemAt(userIdx)
                if (!item) return
                const pt = item.mapToItem(root, 0, 0)
                morph.startX = pt.x
                morph.startY = pt.y
                chosenName = item.uname
                chosen = true
                pw.text = ""
                backAnim.stop()
                chooseAnim.start()
                pw.forceActiveFocus()
            }

            function back() {
                if (busy) return
                pw.text = ""
                chosen = false
                chooseAnim.stop()
                backAnim.start()
                selector.forceActiveFocus()
            }

            function login() {
                if (busy || pw.text.length === 0) return
                if (!Greetd.available) {
                    failed()
                    return
                }
                busy = true
                Greetd.createSession(chosenName)
            }

            function failed() {
                busy = false
                pw.text = ""
                shake.restart()
            }

            Connections {
                target: Greetd

                function onAuthMessage(message, error, responseRequired, echoResponse) {
                    if (responseRequired)
                        Greetd.respond(pw.text)
                }
                function onAuthFailure(message) {
                    root.failed()
                }
                function onError(error) {
                    Greetd.cancelSession()
                    root.failed()
                }
                function onReadyToLaunch() {
                    exitAnim.start()
                }
            }

            SequentialAnimation {
                id: exitAnim
                NumberAnimation {
                    target: root; property: "unlockT"; to: 1; duration: 800
                    easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve
                }
                PauseAnimation { duration: 650 }
                NumberAnimation { target: root; property: "opacity"; to: 0; duration: 350 }
                ScriptAction { script: Greetd.launch(shell.sessionCmd) }
            }

            SequentialAnimation {
                id: chooseAnim
                NumberAnimation {
                    target: root; property: "p"; to: 1; duration: 700
                    easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: root; property: "gridIn"; to: 1; duration: 420
                        easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve
                    }
                    NumberAnimation {
                        target: root; property: "runesIn"; to: 1; duration: 900
                        easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve
                    }
                }
            }

            SequentialAnimation {
                id: backAnim
                ParallelAnimation {
                    NumberAnimation {
                        target: root; property: "gridIn"; to: 0; duration: 220
                        easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve
                    }
                    NumberAnimation {
                        target: root; property: "runesIn"; to: 0; duration: 300
                        easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve
                    }
                }
                NumberAnimation {
                    target: root; property: "p"; to: 0; duration: 600
                    easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve
                }
            }

            SequentialAnimation {
                id: shake
                NumberAnimation { target: root; property: "shakeX"; to: 10; duration: 50 }
                NumberAnimation { target: root; property: "shakeX"; to: -8; duration: 70 }
                NumberAnimation { target: root; property: "shakeX"; to: 0; duration: 90 }
            }

            Item {
                anchors.fill: parent
                visible: root.runesIn > 0

                Repeater {
                    model: 32

                    Row {
                        id: runeRow
                        required property int index

                        readonly property bool solved: pw.text.length > index || root.unlockT * grid.shownCells > index
                        property real lock: solved ? 1 : 0
                        Behavior on lock {
                            NumberAnimation {
                                duration: 600
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: root.curve
                            }
                        }

                        property real rowIn: visible ? 1 : 0
                        Behavior on rowIn { NumberAnimation { duration: 300 } }

                        visible: index < grid.shownCells
                        spacing: 10
                        x: morph.colX - 48 - width
                        y: grid.y + index * 22 + 8 - height / 2
                        opacity: root.runesIn * rowIn

                        Repeater {
                            model: 5

                            Text {
                                required property int index

                                readonly property real l: Math.max(0, Math.min(1,
                                    runeRow.lock * 1.6 - index / 5 * 0.6))

                                readonly property int seed: Math.floor(Math.random() * 1000)
                                readonly property int rest: Math.floor(Math.random() * root.glyphs.length)
                                readonly property int fin: Math.floor(Math.random() * root.glyphs.length)
                                readonly property real rot: (Math.random() - 0.5) * 90
                                readonly property real drift: (Math.random() - 0.5) * 8

                                readonly property bool shifting:
                                    (root.runesIn > 0 && root.runesIn < 1) || (l > 0 && l < 1)

                                text: l >= 1 ? root.glyphs[fin]
                                    : shifting ? root.glyphs[(root.tick * 7 + seed) % root.glyphs.length]
                                    : root.glyphs[rest]

                                width: 16
                                horizontalAlignment: Text.AlignHCenter

                                rotation: (1 - l) * rot
                                transform: Translate { y: (1 - l) * drift }

                                color: l >= 1 ? root.soulflame : root.slate
                                opacity: 0.35 + 0.65 * l

                                font.family: "Noto Sans Runic"
                                font.pixelSize: 15
                            }
                        }
                    }
                }
            }

            Text {
                text: root.host.toUpperCase()
                color: root.steel
                font.family: root.titleFont
                font.pixelSize: 64
                font.letterSpacing: 24
                rotation: -90
                x: 48 + height / 2 - width / 2
                y: root.height / 2 - height / 2
            }

            Item {
                id: selector
                focus: true
                Keys.onLeftPressed: root.userIdx = Math.max(0, root.userIdx - 1)
                Keys.onRightPressed: root.userIdx = Math.min(names.count - 1, root.userIdx + 1)
                Keys.onReturnPressed: root.choose()
                Keys.onEnterPressed: root.choose()
            }

            Row {
                anchors.centerIn: parent
                spacing: 64

                Repeater {
                    id: names
                    model: root.users

                    Item {
                        id: nameItem
                        required property string modelData
                        required property int index
                        readonly property string uname: modelData
                        readonly property bool current: index === root.userIdx

                        width: label.implicitWidth
                        height: label.implicitHeight
                        opacity: current ? (root.p > 0 ? 0 : 1) : 1 - root.p

                        Text {
                            id: label
                            text: nameItem.modelData.toUpperCase()
                            color: nameItem.current ? root.textCol : root.slate
                            font.family: root.titleFont
                            font.pixelSize: 34
                            font.letterSpacing: 8
                            Behavior on color { ColorAnimation { duration: 160 } }
                        }

                        Rectangle {
                            anchors { top: label.bottom; topMargin: 10; horizontalCenter: label.horizontalCenter }
                            width: nameItem.current ? label.width * 0.4 : 0
                            height: 1
                            color: root.soulflame
                            Behavior on width {
                                NumberAnimation {
                                    duration: 220
                                    easing.type: Easing.BezierSpline; easing.bezierCurve: root.curve
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.chosen
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.userIdx = nameItem.index
                                root.choose()
                            }
                        }
                    }
                }
            }

            Item {
                id: morph
                anchors.fill: parent
                visible: root.p > 0

                property real startX: 0
                property real startY: 0
                readonly property string upper: root.chosenName.toUpperCase()
                readonly property var letters: upper.split("")
                readonly property real letterH: 44
                readonly property real colX: root.width * 0.58
                readonly property real colY: (root.height - letters.length * letterH) / 2

                Repeater {
                    model: morph.letters

                    Text {
                        id: ch
                        required property string modelData
                        required property int index

                        readonly property real t: Math.max(0, Math.min(1,
                            root.p * 1.4 - index / Math.max(1, morph.letters.length) * 0.4))

                        TextMetrics {
                            id: prefix
                            font: ch.font
                            text: morph.upper.substring(0, ch.index)
                        }

                        text: modelData
                        color: root.textCol
                        font.family: root.titleFont
                        font.pixelSize: 34
                        font.letterSpacing: 8

                        x: (1 - t) * (morph.startX + prefix.advanceWidth) + t * (morph.colX - width / 2)
                        y: (1 - t) * morph.startY + t * (morph.colY + index * morph.letterH)
                    }
                }
            }

            Column {
                id: grid
                x: morph.colX + 56 + root.shakeX
                y: morph.colY + 40
                spacing: 6

                readonly property int shownCells: Math.max(12, pw.text.length + 1)

                Repeater {
                    model: 32

                    Rectangle {
                        required property int index
                        readonly property bool filled: index < pw.text.length || root.unlockT * grid.shownCells > index
                        readonly property real appear: Math.max(0, Math.min(1, root.gridIn * 2 - index / 12))

                        visible: index < grid.shownCells
                        width: 16
                        height: 16
                        radius: 2
                        color: filled ? root.soulflame : "transparent"
                        border.width: 1
                        border.color: filled ? root.glow : root.steel
                        opacity: appear
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }
            }

            Text {
                anchors { top: grid.bottom; topMargin: 14; left: grid.left }
                text: root.busy ? "listening…" : "[Clear Conscience]: You Cannot Lie"
                color: root.mist
                opacity: root.gridIn
                font.family: root.accentFont
                font.pixelSize: 16
            }

            TextInput {
                id: pw
                opacity: 0
                width: 1
                height: 1
                echoMode: TextInput.Password
                enabled: root.chosen && !root.busy
                Keys.onEscapePressed: root.back()
                onAccepted: root.login()
                onTextChanged: burst.restart()
            }

            Row {
                anchors { right: parent.right; bottom: parent.bottom; margins: 32 }
                spacing: 28

                Text {
                    text: "HYPRLAND"
                    color: root.mist
                    font.family: root.titleFont
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }

                Text {
                    text: "REBOOT"
                    color: root.slate
                    font.family: root.titleFont
                    font.pixelSize: 11
                    font.letterSpacing: 2
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                    }
                }

                Text {
                    text: "SHUTDOWN"
                    color: root.slate
                    font.family: root.titleFont
                    font.pixelSize: 11
                    font.letterSpacing: 2
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                    }
                }
            }

            Component.onCompleted: selector.forceActiveFocus()
        }
    }
}
