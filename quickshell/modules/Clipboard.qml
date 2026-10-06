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
        name: "clipboard"
        onPressed: scope.toggle()
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { scope.toggle() }
    }

    LazyLoader {
        id: loader

PanelWindow {
    id: root

    readonly property int panelW: 440
    readonly property int maxShown: 12
    readonly property int textMax: 320
    readonly property real glass: 0.4
    readonly property string previewFont: Theme.titleFont

    property bool shown: false
    property bool open: false
    property bool revealed: false
    property bool loaded: false
    property var entries: []
    property int sel: 0
    property int tick: 0
    property bool wipeArmed: false
    readonly property string query: search.text.toLowerCase()
        readonly property string thumbDir: Quickshell.cachePath("clip")

    property real barW: 0
    property real openH: 0

    readonly property var filtered: entries
        .filter(e => query === "" || e.hay.includes(query))
        .slice(0, maxShown)

    readonly property real targetH: 12 + (filtered.length > 0 ? filtered.length * 32 - 6 : 26) + 44
    property real panelH: targetH
    Behavior on panelH {
        NumberAnimation { duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
    }

    readonly property var glyphs: Array.from({ length: 75 },
        (_, i) => String.fromCodePoint(0x16A0 + i))

    onQueryChanged: sel = 0

    anchors { top: true; left: true }
    margins { top: 6; left: 0 }
    exclusiveZone: 0
    implicitWidth: panelW
    implicitHeight: 560
    color: "transparent"
    visible: shown

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-clipboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    mask: Region { item: frame }

    function toggle() {
        if (shown && open) closeClip()
        else openClip()
    }


    function openClip() {
        if (open) return
        closeAnim.stop()
        search.text = ""
        sel = 0
        wipeArmed = false
        loaded = false
        shown = true
        open = true
        listProc.running = true
        openAnim.start()
        focusKick.restart()
    }

    function closeClip() {
        if (!open) return
        openAnim.stop()
        ripple.duration = results.values.length * 25 + 480
        open = false
        wipeArmed = false
        closeAnim.start()
    }

    function copy(e) {
        if (!e) return
        Quickshell.execDetached(["sh", "-c", "echo " + e.id + " | cliphist decode | wl-copy"])
        closeClip()
    }

    function remove(e) {
        if (!e) return
        Quickshell.execDetached(["sh", "-c", "echo " + e.id + " | cliphist delete"])
        entries = entries.filter(x => x !== e)
    }

    function wipe() {
        if (!wipeArmed) {
            wipeArmed = true
            disarm.restart()
            return
        }
        wipeArmed = false
        Quickshell.execDetached(["cliphist", "wipe"])
        entries = []
    }

    SequentialAnimation {
        id: openAnim
        NumberAnimation {
            target: root; property: "barW"; to: 1
            duration: 260
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
        }
        NumberAnimation {
            target: root; property: "openH"; to: 1
            duration: 320
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
        }
        ScriptAction { script: root.revealed = true }
    }

    SequentialAnimation {
        id: closeAnim
        PauseAnimation { id: ripple; duration: 480 }
        NumberAnimation {
            target: root; property: "openH"; to: 0
            duration: 260
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
        }
        NumberAnimation {
            target: root; property: "barW"; to: 0
            duration: 220
            easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
        }
        ScriptAction { script: { root.shown = false; root.revealed = false } }
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = this.text.split("\n")
                    .filter(l => l.length > 0)
                    .slice(0, 100)
                    .map(l => {
                        const tab = l.indexOf("\t")
                        const body = l.slice(tab + 1)
                        const img = body.match(/^\[\[ binary data .* (\w+) (\d+x\d+) \]\]$/)
                        return {
                            id: l.slice(0, tab),
                            text: img ? "IMAGE  " + img[2] : body,
                            image: !!img,
                            hay: body.toLowerCase()
                        }
                    })
                root.loaded = true
            }
        }
    }

    ScriptModel {
        id: results
        values: root.open && root.revealed ? root.filtered : []

        onValuesChanged: {
            flicker.restart()
            if (root.sel >= values.length)
                root.sel = Math.max(0, values.length - 1)
        }
    }

    Timer {
        id: focusKick
        interval: 30
        onTriggered: search.forceActiveFocus()
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.wipeArmed = false
    }

    Timer {
        id: flicker
        interval: 1000
    }

    Timer {
        interval: 60
        repeat: true
        running: flicker.running
        onTriggered: root.tick++
    }

    TextInput {
        id: search
        opacity: 0
        width: 1
        height: 1

        Keys.onEscapePressed: root.closeClip()
        Keys.onUpPressed: root.sel = Math.max(0, root.sel - 1)
        Keys.onDownPressed: root.sel = Math.min(results.values.length - 1, root.sel + 1)
        Keys.onReturnPressed: root.copy(results.values[root.sel])
        Keys.onEnterPressed: root.copy(results.values[root.sel])
        Keys.onDeletePressed: event => {
            if (event.modifiers & Qt.ShiftModifier) root.wipe()
            else root.remove(results.values[root.sel])
        }
    }

    Item {
        id: frame
        width: root.panelW
        height: root.panelH * root.openH
        clip: true

        Rectangle {
            width: root.panelW
            height: root.panelH
            topRightRadius: 10
            bottomRightRadius: 10
            color: Theme.night
            opacity: 0
        }

        ListView {
            id: list
            x: 10
            y: 12
            width: root.panelW - 20
            height: root.panelH - 56
            interactive: false
            spacing: 6
            model: results

            remove: Transition {
                SequentialAnimation {
                    PauseAnimation { duration: ViewTransition.index * 25 }
                    NumberAnimation {
                        properties: "textSharp,textFade,pillIn"; to: 0
                        duration: 140
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
                    }
                    NumberAnimation {
                        property: "pillW"; to: 0
                        duration: 180
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
                    }
                    NumberAnimation {
                        properties: "runeSharp,runeFade"; to: 0
                        duration: 140
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
                    }
                }
            }

            displaced: Transition {
                NumberAnimation {
                    property: "y"
                    duration: 220
                    easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
                }
            }

            delegate: Item {
                id: clip
                required property var modelData
                required property int index
                readonly property bool current: index === root.sel

                property real runeFade: 0
                property real runeSharp: 0
                property real pillW: 0
                property real pillIn: 0
                property real textFade: 0
                property real textSharp: 0

                readonly property int glyph: Number(modelData.id) % root.glyphs.length
                readonly property int seed: Math.floor(Math.random() * 1000)

                width: list.width
                height: 26

                SequentialAnimation {
                    id: entryAnim
                    PauseAnimation { duration: Math.max(0, clip.index) * 40 }
                    NumberAnimation {
                        target: clip; property: "runeFade"; to: 1
                        duration: 180
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
                    }
                    NumberAnimation {
                        target: clip; property: "runeSharp"; to: 1
                        duration: 220
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
                    }
                    NumberAnimation {
                        target: clip; property: "pillW"; to: 1
                        duration: 280
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
                    }
                    NumberAnimation {
                        target: clip; properties: "textFade,pillIn"; to: 1
                        duration: 160
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
                    }
                    NumberAnimation {
                        target: clip; property: "textSharp"; to: 1
                        duration: 200
                        easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve
                    }
                }

                Component.onCompleted: entryAnim.start()
                ListView.onRemove: entryAnim.stop()

                Item {
                    id: body

                    readonly property real runeMid: rune.width / 2
                    readonly property real pillFullW: (rune.width - runeMid) + 8 + content.implicitWidth + 14

                    width: runeMid + pillFullW
                    height: parent.height

                    HoverHandler {
                        onHoveredChanged: if (hovered) root.sel = clip.index
                    }
                    TapHandler {
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.copy(clip.modelData)
                    }
                    TapHandler {
                        acceptedButtons: Qt.RightButton
                        onTapped: root.remove(clip.modelData)
                    }

                    Rectangle {
                        x: body.runeMid
                        width: body.pillFullW * clip.pillW
                        height: parent.height
                        topRightRadius: height / 2
                        bottomRightRadius: height / 2
                        color: clip.current ? Theme.ember : "black"
                        opacity: (clip.current ? 0.55 : 0.3) * (0.4 + 0.6 * clip.pillIn)
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Row {
                        id: content
                        x: rune.width + 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        opacity: clip.textFade
                        layer.enabled: clip.textSharp < 1
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur: 1 - clip.textSharp
                            blurMax: 24
                        }

                        Image {
                            id: thumb
                            property bool tried: false

                            visible: clip.modelData.image && status === Image.Ready
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32
                            height: 18
                            fillMode: Image.PreserveAspectCrop
                            sourceSize: Qt.size(64, 36)
                            asynchronous: true
                            source: clip.modelData.image ? "file://" + root.thumbDir + "/" + clip.modelData.id : ""

                            onStatusChanged: {
                                if (status === Image.Error && !tried) {
                                    tried = true
                                    decode.running = true
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, root.textMax)
                            text: clip.modelData.text
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            color: clip.current ? Theme.text : Theme.mist
                            font.family: root.previewFont
                            font.pixelSize: 12
                            font.letterSpacing: 1
                        }
                    }

                    Process {
                        id: decode
                        command: ["sh", "-c", "mkdir -p '" + root.thumbDir + "' && echo " + clip.modelData.id
                            + " | cliphist decode > '" + root.thumbDir + "/" + clip.modelData.id + "'"]
                        onExited: (exitCode, exitStatus) => {
                            thumb.source = ""
                            thumb.source = "file://" + root.thumbDir + "/" + clip.modelData.id
                        }
                    }

                    Text {
                        id: rune
                        width: 26
                        height: 26
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter

                        text: clip.runeSharp >= 1
                            ? root.glyphs[clip.glyph]
                            : root.glyphs[(root.tick * 7 + clip.seed) % root.glyphs.length]

                        color: clip.current ? Theme.soulflame : Theme.steel
                        font.family: "Noto Sans Runic"
                        font.pixelSize: 18

                        opacity: clip.runeFade
                        layer.enabled: clip.runeSharp < 1
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur: 1 - clip.runeSharp
                            blurMax: 24
                        }
                    }
                }
            }
        }

        Row {
            x: 44
            y: list.y + Math.max(list.contentHeight, 0) + 12
            spacing: 8

            Text {
                visible: search.text !== "" || root.wipeArmed || (root.loaded && root.filtered.length === 0)
                text: root.wipeArmed ? "again, to forget all"
                    : search.text !== "" ? "seek"
                    : "the void remembers nothing"
                color: root.wipeArmed ? Theme.rose : Theme.mist
                font.family: Theme.accentFont
                font.pixelSize: 15
            }

            Text {
                visible: search.text !== "" && !root.wipeArmed
                anchors.verticalCenter: parent.verticalCenter
                text: search.text.toUpperCase()
                color: Theme.text
                font.family: Theme.titleFont
                font.pixelSize: 12
                font.letterSpacing: 1
            }
        }
    }

    Repeater {
        model: 2

        Rectangle {
            required property int index
            width: root.panelW * root.barW
            height: 1
            y: index === 0 ? 0 : frame.height - 1
            color: Theme.soulflame
        }
    }
}
}
}
