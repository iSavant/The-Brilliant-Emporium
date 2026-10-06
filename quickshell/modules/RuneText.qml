import QtQuick
import "../singletons"

Text {
    id: rt

    property string plain: ""
    property real progress: 1
    property color runeColor: Theme.ember
    property int tick: 0

    readonly property var map: ({
        a: "ᚨ", b: "ᛒ", c: "ᚲ", d: "ᛞ", e: "ᛖ", f: "ᚠ", g: "ᚷ", h: "ᚺ", i: "ᛁ",
        j: "ᛃ", k: "ᚲ", l: "ᛚ", m: "ᛗ", n: "ᚾ", o: "ᛟ", p: "ᛈ", q: "ᚲ", r: "ᚱ",
        s: "ᛊ", t: "ᛏ", u: "ᚢ", v: "ᚹ", w: "ᚹ", x: "ᛉ", y: "ᛃ", z: "ᛉ",
        "0": "ᛜ", "1": "ᚦ", "2": "ᚻ", "3": "ᛇ", "4": "ᛄ",
        "5": "ᛣ", "6": "ᛤ", "7": "ᛥ", "8": "ᛦ", "9": "ᛧ"
    })

    function esc(s) {
        return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    }

    textFormat: Text.StyledText
    text: {
        const p = Math.max(0, Math.min(1, progress))
        const n = Math.round(plain.length * p)
        let tail = ""
        for (let i = n; i < plain.length; i++) {
            const ch = plain[i]
            const r = map[ch.toLowerCase()]
            if (!r) { tail += ch; continue }
            const flick = p > 0 && p < 1 && i < n + 3
            tail += flick ? String.fromCodePoint(0x16A0 + (tick * 7 + i * 13) % 75) : r
        }
        const head = esc(plain.slice(0, n))
        return tail === "" ? head
            : head + "<font face=\"" + Theme.runeFont + "\" color=\"" + runeColor + "\">" + esc(tail) + "</font>"
    }
}
