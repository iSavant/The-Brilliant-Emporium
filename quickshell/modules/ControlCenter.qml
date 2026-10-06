import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
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
        name: "control"
        onPressed: scope.toggle()
    }

    IpcHandler {
        target: "control"
        function toggle(): void { scope.toggle() }
    }

    LazyLoader {
        id: loader
        loading: true

PanelWindow {
    id: root

    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property int hReach: 250
    readonly property int vReach: 150
    readonly property int panelW: 300
    readonly property int panelH: 130
    readonly property int detailW: 640
    readonly property int detailH: 560
    readonly property int hubR: 62
    readonly property int ringN: 18
    readonly property real glass: 0.45

    property bool shown: false
    property string sel: ""
    property string opened: ""
    property var detail: null
    property real hubFade: 0
    property real hubSharp: 0
    property real sweep: 0
    property real decipher: 0
    property real focusT: 0
    property int tick: 0

    readonly property bool flickering: (decipher > 0 && decipher < 1) || (focusT > 0 && focusT < 1)

    readonly property var files: ({
        top: "StarOfRuin.qml",
        right: "PrinceOfNothing.qml",
        bottom: "LostFromLight.qml",
        left: "Nightingale.qml"
    })

    readonly property var slots: [
        { key: "top",    dx: 0,  dy: -1, title: "Star of Ruin" },
        { key: "right",  dx: 1,  dy: 0,  title: "Prince of Nothing" },
        { key: "bottom", dx: 0,  dy: 1,  title: "Lost from Light" },
        { key: "left",   dx: -1, dy: 0,  title: "Nightingale" }
    ]

    anchors { top: true; bottom: true; left: true; right: true }
    color: Qt.rgba(0, 0, 0, 0.1)
    visible: shown

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-control"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    function toggle() {
        if (shown && !closeAnim.running) closeCenter()
        else openCenter()
    }

    function openCenter() {
        closeAnim.stop()
        sel = ""
        opened = ""
        focusT = 0
        shown = true
        openAnim.start()
        focusKick.restart()
    }

    function closeCenter() {
        if (!shown || closeAnim.running) return
        openAnim.stop()
        focusIn.stop()
        focusOut.stop()
        closeAnim.start()
    }

    function openPanel(k) {
        if (opened !== "" || openAnim.running) return
        sel = k
        opened = k
        focusOut.stop()
        focusIn.start()
    }

    function back() {
        if (opened === "") { closeCenter(); return }
        focusIn.stop()
        focusOut.start()
    }

    function dirFor(key) {
        if (key === Qt.Key_Up || key === Qt.Key_K || key === Qt.Key_W) return "top"
        if (key === Qt.Key_Down || key === Qt.Key_J || key === Qt.Key_S) return "bottom"
        if (key === Qt.Key_Left || key === Qt.Key_H || key === Qt.Key_A) return "left"
        if (key === Qt.Key_Right || key === Qt.Key_L || key === Qt.Key_D) return "right"
        return ""
    }

    Timer {
        id: focusKick
        interval: 30
        onTriggered: keys.forceActiveFocus()
    }

    Timer {
        interval: 60
        repeat: true
        running: root.shown && root.flickering
        onTriggered: root.tick++
    }

    SequentialAnimation {
        id: openAnim
        NumberAnimation { target: root; property: "hubFade"; to: 1; duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
        NumberAnimation { target: root; property: "hubSharp"; to: 1; duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
        NumberAnimation { target: root; property: "sweep"; to: 1.05; duration: 1400 }
        NumberAnimation { target: root; property: "decipher"; to: 1; duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: root; property: "focusT"; to: 0; duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
        NumberAnimation { target: root; property: "decipher"; to: 0; duration: 380; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
        NumberAnimation { target: root; property: "sweep"; to: 0; duration: 900 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "hubSharp"; to: 0; duration: 140; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
            NumberAnimation { target: root; property: "hubFade"; to: 0; duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
        }
        ScriptAction { script: { root.shown = false; root.opened = ""; root.sel = "" } }
    }

    SequentialAnimation {
        id: focusIn
        NumberAnimation { target: root; property: "focusT"; to: 1; duration: 420; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
    }

    SequentialAnimation {
        id: focusOut
        NumberAnimation { target: root; property: "focusT"; to: 0; duration: 360; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
        ScriptAction { script: root.opened = "" }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.night
        opacity: 0.35 * root.hubFade
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.back()
    }

    Item {
        id: keys
        Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape && !(root.detail && root.detail.captureEsc)) {
                root.back()
                event.accepted = true
                return
            }
            if (root.opened !== "") {
                if (root.detail && root.detail.handleKey) root.detail.handleKey(event)
                return
            }
            const d = root.dirFor(event.key)
            if (d !== "") {
                if (root.sel === d) root.openPanel(d)
                else root.sel = d
                event.accepted = true
            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && root.sel !== "") {
                root.openPanel(root.sel)
                event.accepted = true
            }
        }
    }

    Item {
        id: sigil
        x: root.cx - width / 2
        y: root.cy - height / 2
        z: 2
        width: root.hubR * 2
        height: root.hubR * 2
        opacity: root.hubFade * (1 - root.focusT)

        layer.enabled: root.hubSharp < 1
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1 - root.hubSharp
            blurMax: 32
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: Qt.rgba(Theme.night.r, Theme.night.g, Theme.night.b, 0.8)
            border.width: 1
            border.color: Theme.soulflame
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 34
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Theme.steel
        }

        Repeater {
            model: root.ringN

            Text {
                required property int index
                readonly property real a: index / root.ringN * 2 * Math.PI - Math.PI / 2

                visible: index < Math.round(Math.min(1, root.sweep) * root.ringN)
                x: sigil.width / 2 + (root.hubR - 9) * Math.cos(a) - width / 2
                y: sigil.height / 2 + (root.hubR - 9) * Math.sin(a) - height / 2
                rotation: a * 180 / Math.PI + 90
                text: String.fromCodePoint(0x16A0 + index * 4)
                color: Theme.mist
                font.family: Theme.runeFont
                font.pixelSize: 11
            }
        }

        Text {
            anchors.centerIn: parent
            text: "ᛟ"
            color: Theme.soulflame
            font.family: Theme.runeFont
            font.pixelSize: 34
        }
    }

    Repeater {
        model: root.slots

        Item {
            id: card
            required property var modelData
            required property int index
            readonly property real raw: Math.max(0, Math.min(1, (root.sweep - index * 0.25) / 0.3))
            readonly property real emerge: raw * raw * (3 - 2 * raw)

            readonly property string key: modelData.key
            readonly property bool isSel: root.sel === key
            readonly property real t: root.opened === key ? root.focusT : 0
            readonly property real gone: root.opened !== "" && root.opened !== key ? root.focusT : 0
            readonly property real dec: Math.max(0, Math.min(1, root.decipher * 1.3 - index * 0.1)) * (1 - gone)
            readonly property real hx: root.cx + modelData.dx * root.hReach * card.emerge - root.panelW / 2
            readonly property real hy: root.cy + modelData.dy * root.vReach * card.emerge - root.panelH / 2

            x: hx + (root.cx - root.detailW / 2 - hx) * t + (root.cx - root.panelW / 2 - hx) * gone * 0.7
            y: hy + (root.cy - root.detailH / 2 - hy) * t + (root.cy - root.panelH / 2 - hy) * gone * 0.7
            width: root.panelW + (root.detailW - root.panelW) * t
            height: root.panelH + (root.detailH - root.panelH) * t
            z: t > 0 ? 3 : 1
            opacity: Math.min(1, card.emerge * 2) * (1 - gone)
            scale: (0.4 + 0.6 * card.emerge) * (1 - 0.5 * gone)
            visible: opacity > 0

            layer.enabled: gone > 0 && gone < 1
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: card.gone
                blurMax: 40
            }

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: Theme.night
                opacity: 0.24
            }

            Rectangle {
                visible: card.t === 0
                width: card.modelData.dx !== 0 ? 2 : root.panelW * (card.isSel ? 0.4 : 0)
                height: card.modelData.dy !== 0 ? 2 : root.panelH * (card.isSel ? 0.5 : 0)
                x: card.modelData.dx < 0 ? parent.width - 2 : card.modelData.dx > 0 ? 0 : (parent.width - width) / 2
                y: card.modelData.dy < 0 ? parent.height - 2 : card.modelData.dy > 0 ? 0 : (parent.height - height) / 2
                color: Theme.rose
                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: root.opened === ""
                onEntered: if (root.opened === "") root.sel = card.key
                onClicked: if (root.opened === "") root.openPanel(card.key)
            }

            Column {
                x: 22
                y: 18
                spacing: 4
                opacity: Math.max(0, 1 - card.t * 2)

                RuneText {
                    plain: card.modelData.title
                    progress: card.dec * 3
                    tick: root.tick
                    runeColor: Theme.ember
                    color: card.isSel ? Theme.rose : Theme.ember
                    font.family: Theme.titleFont
                    font.pixelSize: 15
                    font.bold: true
                    font.letterSpacing: 3
                }

                Item { width: 1; height: 12 }

                RuneText {
                    width: root.panelW - 44
                    elide: Text.ElideRight
                    plain: card.key === "top" ? (SysInfo.networkConnected ? "wi-fi · linked" : "wi-fi · severed")
                        : card.key === "bottom" ? "volume · " + (Pipewire.defaultAudioSink?.audio?.muted ? "silenced"
                            : Math.round((Pipewire.defaultAudioSink?.audio?.volume ?? 0) * 100) + "%")
                        : card.key === "left" ? (SysInfo.player ? SysInfo.player.trackTitle : "silence")
                        : SysInfo.notifications + " unread"
                    progress: card.dec * 3 - 1
                    tick: root.tick
                    runeColor: Theme.ember
                    color: Theme.text
                    font.family: Theme.bodyFont
                    font.pixelSize: 12
                }

                RuneText {
                    width: root.panelW - 44
                    elide: Text.ElideRight
                    plain: card.key === "top" ? "bluetooth · " + (Bluetooth.defaultAdapter?.enabled ? "awake" : "asleep")
                        : card.key === "bottom" ? "microphone · " + (Pipewire.defaultAudioSource?.audio?.muted ? "silenced" : "open")
                        : card.key === "left" ? (SysInfo.player ? SysInfo.player.trackArtist : "")
                        : (Notifs.dnd ? "do not disturb · on" : "do not disturb · off")
                    progress: card.dec * 3 - 2
                    tick: root.tick
                    runeColor: Theme.ember
                    color: Theme.mist
                    font.family: Theme.bodyFont
                    font.pixelSize: 12
                }
            }

            Loader {
                anchors.fill: parent
                anchors.margins: 24
                active: root.opened === card.key
                opacity: Math.max(0, card.t * 2 - 1)
                source: root.files[card.key]
                onItemChanged: if (item) root.detail = item
            }
        }
    }
}
}
}
