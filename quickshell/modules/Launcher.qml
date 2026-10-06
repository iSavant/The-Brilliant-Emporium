import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import Quickshell.Hyprland
import "../singletons"

Scope {
    id: scope

    function toggle() {
        loader.active = true
        loader.item.toggle()
    }

    GlobalShortcut {
        name: "launcher"
        onPressed: scope.toggle()
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { scope.toggle() }
    }

    LazyLoader {
        id: loader
        loading: true

PanelWindow {
    id: root

    readonly property int panelW: 760
    readonly property int panelH: 520
    readonly property int lineOver: 40
    readonly property real glass: 0.4

    property bool shown: false
    property string cat: "all"
    property int focusIdx: 0
    property point lastMouse: Qt.point(-1, -1)
    property string armed: ""
    property bool codexOn: false
    property var codex: ({})
    property var binds: []
    readonly property string query: searchInput.text.toLowerCase().trim()

    onQueryChanged: { focusIdx = 0; armed = "" }
    onCatChanged: { focusIdx = 0; armed = "" }
    onFocusIdxChanged: armed = ""

    property real lineFade: 0
    property real lineSharp: 0
    property real openH: 0

    anchors { top: true; bottom: true; left: true; right: true }
    color: Qt.rgba(0, 0, 0, 0.1)
    visible: shown

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    function toggle() {
        if (shown && !closeAnim.running) closeLauncher()
        else openLauncher()
    }

    function openLauncher() {
        closeAnim.stop()
        searchInput.text = ""
        cat = "all"
        focusIdx = 0
        armed = ""
        codexOn = false
        lastMouse = Qt.point(-1, -1)
        list.positionViewAtBeginning()
        shown = true
        bindsProc.running = true
        openAnim.start()
        focusKick.restart()
    }

    function closeLauncher() {
        if (!shown || closeAnim.running) return
        openAnim.stop()
        closeAnim.start()
    }

    function arm(key) {
        armed = key
        disarm.restart()
    }

    function launch(item) {
        if (!item) return
        if (item.kind === "app") {
            item.entry.execute()
            closeLauncher()
        } else if (item.kind === "rite") {
            if (item.confirm && armed !== "rite:" + item.name) { arm("rite:" + item.name); return }
            if (item.fn === "dnd") Notifs.dnd = !Notifs.dnd
            else Quickshell.execDetached(item.cmd)
            closeLauncher()
        }
    }

    function uninstall(item) {
        if (!item || item.kind !== "app") return
        const key = "cast:" + item.entry.id
        if (armed !== key) { arm(key); return }
        closeLauncher()
        Quickshell.execDetached(["kitty", "--title", "cast out", "sh", "-c", root.castScript, "sh", item.entry.id])
    }

    function toggleCodex() {
        const item = results.values[focusIdx]
        if (codexOn) { codexOn = false; return }
        if (!item || item.kind !== "app") return
        codex = {}
        codexOn = true
        infoProc.command = ["sh", "-c", root.infoScript, "sh", item.entry.id]
        infoProc.running = true
    }

    function hoverSelect(area, idx) {
        const p = area.mapToItem(null, area.mouseX, area.mouseY)
        if (lastMouse.x < 0) { lastMouse = p; return }
        if (p.x === lastMouse.x && p.y === lastMouse.y) return
        lastMouse = p
        focusIdx = idx
    }

    readonly property string findDesktop: "f=$(find /usr/share/applications \"$HOME/.local/share/applications\" /var/lib/flatpak/exports/share/applications \"$HOME/.local/share/flatpak/exports/share/applications\" -name \"$1.desktop\" 2>/dev/null | head -n1); "

    readonly property string castScript: findDesktop
        + "case \"$f\" in "
        + "*flatpak*) flatpak uninstall \"$1\" ;; "
        + "/usr/*) pkg=$(pacman -Qqo \"$f\") && sudo pacman -Rns \"$pkg\" ;; "
        + "\"\") echo \"no trace of $1 was found\" ;; "
        + "*) rm -i \"$f\" ;; "
        + "esac; printf '\\npress enter to close'; read -r _"

    readonly property string infoScript: findDesktop
        + "case \"$f\" in "
        + "/usr/*) echo 'Source : pacman'; LC_ALL=C pacman -Qi $(pacman -Qqo \"$f\") ;; "
        + "*flatpak*) echo 'Source : flatpak' ;; "
        + "\"\") echo 'Source : unknown' ;; "
        + "*) echo 'Source : local' ;; "
        + "esac"

    Timer {
        id: focusKick
        interval: 30
        onTriggered: searchInput.forceActiveFocus()
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = ""
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.shown
    }

    Process {
        id: bindsProc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const mods = [[64, "SUPER"], [4, "CTRL"], [8, "ALT"], [1, "SHIFT"]]
                try {
                    root.binds = JSON.parse(this.text)
                        .filter(b => b.key && !b.key.startsWith("mouse"))
                        .map(b => {
                            const keys = mods.filter(m => b.modmask & m[0]).map(m => m[1])
                                .concat([b.key.toUpperCase()]).join(" + ")
                            const name = b.description || (b.dispatcher + (b.arg ? " " + b.arg : ""))
                            return { kind: "bind", cat: "binds", name: name, keys: keys,
                                     hay: (name + " " + keys + " " + (b.arg || "")).toLowerCase() }
                        })
                } catch (e) {
                    root.binds = []
                }
            }
        }
    }

    Process {
        id: infoProc
        stdout: StdioCollector {
            onStreamFinished: {
                const o = {}
                for (const line of this.text.split("\n")) {
                    const i = line.indexOf(":")
                    if (i > 0) o[line.slice(0, i).trim()] = line.slice(i + 1).trim()
                }
                root.codex = o
            }
        }
    }

    function catOf(e) {
        const c = e.categories.join(" ")
        if (/Development|IDE|TextEditor|Debugger/.test(c)) return "dev"
        if (/WebBrowser|Email|Chat|Network|FileTransfer/.test(c)) return "net"
        if (/Audio|Video|Player|Music/.test(c)) return "media"
        if (/Office|Spreadsheet|WordProcessor|Presentation/.test(c)) return "office"
        if (/Graphics|Photography/.test(c)) return "graphics"
        if (/Game|Emulator/.test(c)) return "games"
        if (/System|Utility|Monitor|Settings/.test(c)) return "sys"
        return "other"
    }

    readonly property var apps: Array.from(DesktopEntries.applications.values)
        .filter(e => !e.noDisplay)
        .map(e => ({
            kind: "app",
            entry: e,
            name: e.name,
            cat: root.catOf(e),
            hay: [e.name, e.genericName, e.comment, e.keywords.join(" ")].join(" ").toLowerCase()
        }))
        .sort((a, b) => a.name.localeCompare(b.name))

    readonly property var rites: [
        { name: "Suspend",        rune: "ᛁ", cmd: ["systemctl", "suspend"] },
        { name: "Log out",        rune: "ᚱ", cmd: ["loginctl", "terminate-user", Quickshell.env("USER")], confirm: true },
        { name: "Reboot",         rune: "ᛃ", cmd: ["systemctl", "reboot"], confirm: true },
        { name: "Shut down",      rune: "ᚺ", cmd: ["systemctl", "poweroff"], confirm: true },
        { name: "Gamemode",       rune: "ᛜ", cmd: ["hyprctl", "eval", "require(\"modules.gamemode\").toggle()"], confirm: true },
        { name: "Do not disturb", rune: "ᛚ", fn: "dnd" },
        { name: "Control centre", rune: "ᛟ", cmd: ["qs", "ipc", "call", "control", "toggle"] },
        { name: "Clipboard",      rune: "ᛗ", cmd: ["qs", "ipc", "call", "clipboard", "toggle"] },
        { name: "Power menu",     rune: "ᚦ", cmd: ["qs", "ipc", "call", "power", "toggle"] }
    ].map(r => Object.assign({ kind: "rite", cat: "rites", hay: (r.name + " rite").toLowerCase() }, r))

    readonly property var everything: apps.concat(rites, binds)

    readonly property var catOrder: ["all", "dev", "sys", "net", "media", "office", "graphics", "games", "other", "rites", "binds"]
    readonly property var catLabels: ({
        all: "ALL", dev: "DEVELOP", sys: "SYSTEM", net: "NETWORK", media: "MEDIA",
        office: "OFFICE", graphics: "GRAPHICS", games: "GAMES", other: "OTHER",
        rites: "RITES", binds: "BINDS"
    })

    readonly property var catCounts: {
        const n = { all: apps.length + rites.length }
        for (const a of everything)
            n[a.cat] = (n[a.cat] ?? 0) + 1
        return n
    }

    readonly property var catKeys: catOrder.filter(k => (catCounts[k] ?? 0) > 0)

    ScriptModel {
        id: results
        values: root.everything.filter(a =>
            (root.cat === "all" ? (a.kind !== "bind" || root.query !== "") : a.cat === root.cat)
            && (root.query === "" || a.hay.includes(root.query)))
    }

    function move(d) {
        const n = results.values.length
        if (n === 0) return
        focusIdx = Math.max(0, Math.min(n - 1, focusIdx + d))
        list.positionViewAtIndex(focusIdx, ListView.Contain)
        if (codexOn) { codexOn = false; toggleCodex() }
    }

    function cycleCat(d) {
        const i = catKeys.indexOf(cat)
        cat = catKeys[(i + d + catKeys.length) % catKeys.length]
        codexOn = false
    }

    SequentialAnimation {
        id: openAnim
        NumberAnimation { target: root; property: "lineFade"; to: 1; duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
        NumberAnimation { target: root; property: "lineSharp"; to: 1; duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
        NumberAnimation { target: root; property: "openH"; to: 1; duration: 320; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
    }

    SequentialAnimation {
        id: closeAnim
        NumberAnimation { target: root; property: "openH"; to: 0; duration: 260; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
        NumberAnimation { target: root; property: "lineSharp"; to: 0; duration: 160; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
        NumberAnimation { target: root; property: "lineFade"; to: 0; duration: 160; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve }
        ScriptAction { script: root.shown = false }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeLauncher()
    }

    Item {
        id: frame
        anchors.centerIn: parent
        width: root.panelW
        height: root.panelH * root.openH
        clip: true

        Item {
            id: panel
            anchors.centerIn: parent
            width: root.panelW
            height: root.panelH

            MouseArea {
                anchors.fill: parent
                onClicked: searchInput.forceActiveFocus()
            }

            Rectangle {
                anchors.fill: parent
                radius: 10
                color: Theme.night
                opacity: 0.42
            }

            Item {
                id: header
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 56

                Row {
                    anchors { left: parent.left; leftMargin: 24; verticalCenter: parent.verticalCenter }
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "THE SPELL"
                        color: Theme.text
                        font.family: Theme.titleFont
                        font.pixelSize: 14
                        font.letterSpacing: 3
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2; height: 16
                        color: Theme.soulflame; opacity: 0.6
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "what shall awaken?"
                        color: Theme.mist
                        font.family: Theme.accentFont
                        font.pixelSize: 15
                    }
                }

                Row {
                    anchors { right: parent.right; rightMargin: 24; verticalCenter: parent.verticalCenter }
                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: String(results.values.length).padStart(2, "0") + " / " + root.everything.length
                        color: Theme.mist
                        font.family: Theme.titleFont
                        font.pixelSize: 11
                        font.letterSpacing: 1
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2; height: 16
                        color: Theme.soulflame; opacity: 0.6
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatTime(clock.date, "h:mm")
                        color: Theme.soulflame
                        font.family: Theme.accentFont
                        font.pixelSize: 16
                        font.bold: true
                    }
                }
            }

            Item {
                id: search
                anchors {
                    top: header.bottom
                    left: parent.left; right: parent.right
                    leftMargin: 20; rightMargin: 20
                }
                height: 44

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: Theme.abyss
                    opacity: 0.5
                }

                Text {
                    id: searchIcon
                    anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                    text: ">"
                    color: Theme.soulflame
                    font.family: Theme.bodyFont
                    font.pixelSize: 18
                }

                TextInput {
                    id: searchInput
                    anchors {
                        left: searchIcon.right; leftMargin: 8
                        right: parent.right; rightMargin: 16
                        verticalCenter: parent.verticalCenter
                    }
                    clip: true
                    color: Theme.text
                    selectionColor: Theme.ember
                    font.family: Theme.accentFont
                    font.pixelSize: 18

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier
                        const shift = event.modifiers & Qt.ShiftModifier
                        if (event.key === Qt.Key_Escape) {
                            if (root.codexOn) root.codexOn = false
                            else root.closeLauncher()
                        }
                        else if (event.key === Qt.Key_Up) root.move(-1)
                        else if (event.key === Qt.Key_Down) root.move(1)
                        else if (event.key === Qt.Key_Tab) root.cycleCat(1)
                        else if (event.key === Qt.Key_Backtab) root.cycleCat(-1)
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) root.launch(results.values[root.focusIdx])
                        else if (event.key === Qt.Key_I && ctrl) root.toggleCodex()
                        else if (event.key === Qt.Key_Delete && shift) root.uninstall(results.values[root.focusIdx])
                        else return
                        event.accepted = true
                    }

                    Text {
                        visible: searchInput.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "whisper a true name…"
                        color: Theme.mist
                        font: searchInput.font
                    }
                }
            }

            Item {
                id: body
                anchors {
                    top: search.bottom; topMargin: 12
                    bottom: footer.top
                    left: parent.left; right: parent.right
                    leftMargin: 20; rightMargin: 20
                }

                Column {
                    id: sidebar
                    width: 140
                    spacing: 2

                    Repeater {
                        model: root.catKeys

                        Item {
                            id: catItem
                            required property string modelData
                            readonly property bool active: root.cat === modelData

                            width: sidebar.width
                            height: 28

                            Rectangle {
                                x: 0; y: 6
                                width: 2
                                height: catItem.active ? 16 : 0
                                color: Theme.soulflame
                                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
                            }

                            Text {
                                x: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: root.catLabels[catItem.modelData]
                                color: catItem.active ? Theme.text : Theme.mist
                                font.family: Theme.titleFont
                                font.pixelSize: 10
                                font.letterSpacing: 2
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            Text {
                                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                                text: String(root.catCounts[catItem.modelData]).padStart(2, "0")
                                color: Theme.mist
                                opacity: 0.6
                                font.family: Theme.titleFont
                                font.pixelSize: 9
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.cat = catItem.modelData
                                    root.codexOn = false
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }
                    }
                }

                ListView {
                    id: list
                    visible: !root.codexOn
                    anchors {
                        left: sidebar.right; leftMargin: 12
                        right: parent.right
                        top: parent.top; bottom: parent.bottom
                    }
                    clip: true
                    spacing: 2
                    reuseItems: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: results

                    delegate: Item {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool current: index === root.focusIdx
                        readonly property string kind: modelData.kind
                        readonly property bool isArmed: root.armed !== "" && current
                            && (root.armed === "cast:" + (modelData.entry?.id ?? "") || root.armed === "rite:" + modelData.name)

                        width: list.width
                        height: 40

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: row.isArmed ? Theme.criticalDark : Theme.ember
                            opacity: row.isArmed ? 0.6 : row.current ? 0.35 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        Rectangle {
                            x: 0; y: 10
                            width: 2
                            height: row.current ? 20 : 0
                            color: row.isArmed ? Theme.crimson : Theme.soulflame
                            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
                        }

                        Image {
                            id: appIcon
                            x: row.current ? 18 : 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 24; height: 24
                            source: row.kind === "app" ? Quickshell.iconPath(row.modelData.entry.icon, true) : ""
                            sourceSize: Qt.size(48, 48)
                            visible: row.kind === "app" && source != ""
                            opacity: row.current ? 1 : 0.55
                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
                            Behavior on opacity { NumberAnimation { duration: 160 } }
                        }

                        Text {
                            visible: !appIcon.visible
                            x: row.current ? 22 : 16
                            width: 18
                            horizontalAlignment: Text.AlignHCenter
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.kind === "rite" ? row.modelData.rune : row.kind === "bind" ? "ᚲ" : "◆"
                            color: row.current ? Theme.soulflame : Theme.steel
                            font.family: row.kind === "app" ? Theme.bodyFont : Theme.runeFont
                            font.pixelSize: row.kind === "app" ? 12 : 16
                            Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
                        }

                        Column {
                            anchors {
                                left: parent.left; leftMargin: 54
                                right: tag.left; rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: 1

                            Text {
                                width: parent.width
                                text: row.modelData.name
                                elide: Text.ElideRight
                                color: Theme.text
                                opacity: row.current ? 1 : 0.75
                                font.family: Theme.accentFont
                                font.pixelSize: 16
                                font.capitalization: Font.AllLowercase
                            }

                            Text {
                                visible: row.kind === "bind"
                                text: row.modelData.keys ?? ""
                                color: Theme.mist
                                font.family: Theme.titleFont
                                font.pixelSize: 9
                                font.letterSpacing: 2
                            }
                        }

                        Text {
                            id: tag
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            text: row.isArmed ? (row.kind === "app" ? "again, to cast it out" : "again")
                                : row.kind === "bind" ? row.modelData.key
                                : root.catLabels[row.modelData.cat]
                            color: row.isArmed ? Theme.crimson : Theme.mist
                            opacity: row.isArmed ? 1 : 0.7
                            font.family: row.isArmed ? Theme.accentFont : Theme.titleFont
                            font.pixelSize: row.isArmed ? 14 : 9
                            font.letterSpacing: row.isArmed ? 0 : 2
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.hoverSelect(rowMouse, row.index)
                            onPositionChanged: root.hoverSelect(rowMouse, row.index)
                            onClicked: root.launch(row.modelData)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: results.values.length === 0
                        text: "nothing answers."
                        color: Theme.mist
                        font.family: Theme.accentFont
                        font.pixelSize: 16
                    }
                }

                Flickable {
                    id: codexView
                    visible: root.codexOn
                    anchors {
                        left: sidebar.right; leftMargin: 24
                        right: parent.right; rightMargin: 12
                        top: parent.top; bottom: parent.bottom
                    }
                    clip: true
                    contentHeight: codexCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    readonly property var e: results.values[root.focusIdx]?.entry ?? null

                    Column {
                        id: codexCol
                        width: parent.width
                        spacing: 10

                        Row {
                            spacing: 14
                            Image {
                                width: 40; height: 40
                                source: codexView.e ? Quickshell.iconPath(codexView.e.icon, true) : ""
                                sourceSize: Qt.size(80, 80)
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    text: codexView.e?.name ?? ""
                                    color: Theme.text
                                    font.family: Theme.titleFont
                                    font.pixelSize: 18
                                    font.letterSpacing: 1
                                }
                                Text {
                                    visible: text !== ""
                                    text: codexView.e?.genericName ?? ""
                                    color: Theme.mist
                                    font.family: Theme.accentFont
                                    font.pixelSize: 15
                                    font.capitalization: Font.AllLowercase
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: codexView.e?.comment ?? ""
                            wrapMode: Text.Wrap
                            color: Theme.text
                            font.family: Theme.bodyFont
                            font.pixelSize: 12
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: root.codex["Description"] ?? ""
                            wrapMode: Text.Wrap
                            color: Theme.mist
                            font.family: Theme.bodyFont
                            font.pixelSize: 12
                        }

                        Item { width: 1; height: 6 }

                        Repeater {
                            model: [
                                ["ROLE", (codexView.e?.categories ?? []).filter(c => !/^X-/.test(c)).join(" · ")],
                                ["SUMMONED BY", codexView.e?.execString ?? ""],
                                ["SOURCE", root.codex["Source"] ?? "…"],
                                ["VERSION", root.codex["Version"] ?? ""],
                                ["WEIGHT", root.codex["Installed Size"] ?? ""],
                                ["BOUND SINCE", root.codex["Install Date"] ?? ""],
                                ["ORIGIN", root.codex["URL"] ?? ""]
                            ]

                            Row {
                                required property var modelData
                                visible: modelData[1] !== ""
                                spacing: 14

                                Text {
                                    width: 110
                                    text: parent.modelData[0]
                                    color: Theme.mist
                                    font.family: Theme.titleFont
                                    font.pixelSize: 9
                                    font.letterSpacing: 2
                                }
                                Text {
                                    width: codexCol.width - 124
                                    text: parent.modelData[1]
                                    wrapMode: Text.WrapAnywhere
                                    color: Theme.text
                                    font.family: Theme.bodyFont
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
            }

            Text {
                id: footer
                anchors {
                    bottom: parent.bottom; bottomMargin: 12
                    horizontalCenter: parent.horizontalCenter
                }
                text: root.codexOn ? "^I · CLOSE CODEX    ↑↓ · NEXT    ESC · CLOSE"
                    : "↑↓ SELECT    ⇥ ASPECT    ⏎ AWAKEN    ^I CODEX    ⇧DEL CAST OUT    ESC SEVER"
                color: Theme.mist
                opacity: 0.6
                font.family: Theme.titleFont
                font.pixelSize: 9
                font.letterSpacing: 2
            }
        }
    }

    Item {
        id: lines
        x: (root.width - width) / 2
        y: frame.y - 12
        width: root.panelW + root.lineOver * 2
        height: frame.height + 24
        opacity: root.lineFade

        layer.enabled: root.lineSharp < 1
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1 - root.lineSharp
            blurMax: 24
        }

        Repeater {
            model: 2

            Rectangle {
                required property int index
                width: lines.width
                height: 1
                y: index === 0 ? 12 : lines.height - 13
                color: Theme.soulflame
                opacity: 0.8
            }
        }
    }
}
}
}
