pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property color night:        "#060708"
    readonly property color abyss:        "#101316"
    readonly property color shade:        "#1B2124"
    readonly property color steel:        "#343B40"
    readonly property color slate:        "#464D52"
    readonly property color ember:        "#66676B"
    readonly property color mist:         "#8E8A8C"
    readonly property color soulflame:    "#BAB7B6"
    readonly property color text:         "#D8D1D3"
    readonly property color weave:        "#312E35"
    readonly property color dusk:         "#443B44"
    readonly property color rose:         "#8A616D"
    readonly property color criticalDark: "#5D2027"
    readonly property color critical:     "#8F1E25"
    readonly property color crimson:      "#CC1E2B"

    readonly property string iconFont:   "Symbols Nerd Font"
    readonly property string titleFont:  "Cinzel Decorative"
    readonly property string accentFont: "Highcrest - Personal use"
    readonly property string bodyFont:   "Roboto Mono"
    readonly property string runeFont: "Noto Sans Runic"

    readonly property var curve: [0.4, 0, 0.2, 1, 1, 1]
}
