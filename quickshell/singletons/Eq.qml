pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var labels: ["31", "62", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    readonly property var presetNames: ["Flat", "Bass", "Vocal", "Treble"]
    readonly property var presets: ({
        Flat:   [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        Bass:   [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
        Vocal:  [-2, -1, 0, 2, 4, 4, 3, 1, 0, -1],
        Treble: [0, 0, 0, 0, 0, 1, 2, 4, 5, 6]
    })

    property var gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property string preset: "Flat"

    readonly property var node: Pipewire.nodes.values.find(n => n.name === "effect_input.shadow_eq") ?? null
    readonly property bool available: node !== null

    onNodeChanged: push()

    function restore() {
        push()
    }

    function setGain(i, g) {
        const next = gains.slice()
        next[i] = Math.max(-12, Math.min(12, Math.round(g)))
        gains = next
        preset = ""
        if (!pushTimer.running) pushTimer.start()
        saveTimer.restart()
    }

    function applyPreset(name) {
        gains = presets[name].slice()
        preset = name
        push()
        saveTimer.restart()
    }

    function push() {
        if (!node) return
        const params = gains.map((g, i) => "\"eq" + (i + 1) + ":Gain\" " + g.toFixed(1)).join(" ")
        Quickshell.execDetached(["pw-cli", "set-param", String(node.id), "Props", "{ params = [ " + params + " ] }"])
    }

    Timer {
        id: pushTimer
        interval: 40
        onTriggered: root.push()
    }

    Timer {
        id: saveTimer
        interval: 500
        onTriggered: store.setText(JSON.stringify({ gains: root.gains, preset: root.preset }))
    }

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/quickshell-eq.json"
        blockLoading: true
        onLoaded: {
            try {
                const o = JSON.parse(text())
                if (Array.isArray(o.gains) && o.gains.length === 10) root.gains = o.gains
                root.preset = o.preset ?? ""
            } catch (e) {}
        }
    }
}
