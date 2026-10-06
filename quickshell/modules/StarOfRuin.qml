import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import QtQuick
import "../singletons"

Item {
    id: root

    property int tab: 0
    property int wsel: 0
    property int bsel: 0
    property bool wifiOn: false
    property var networks: []
    property var saved: []
    property string prompt: ""
    property string pw: ""
    property string error: ""
    property string busy: ""

    readonly property var tabs: ["WI-FI", "BLUETOOTH"]
    readonly property bool captureEsc: prompt !== ""
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: (adapter?.devices?.values ?? []).slice().sort((a, b) =>
        (b.connected - a.connected) || (b.paired - a.paired) || (a.name || "").localeCompare(b.name || ""))

    Component.onCompleted: refresh()
    Component.onDestruction: if (adapter?.discovering) adapter.discovering = false

    function splitT(line) {
        const out = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            const c = line[i]
            if (c === "\\" && i + 1 < line.length) { cur += line[++i]; continue }
            if (c === ":") { out.push(cur); cur = ""; continue }
            cur += c
        }
        out.push(cur)
        return out
    }

    function refresh() {
        radioProc.running = true
        savedProc.running = true
        scanProc.running = true
    }

    function run(cmd) {
        actProc.command = cmd
        actProc.running = true
    }

    function activateNet(n) {
        if (!n) return
        if (n.active) {
            busy = n.ssid
            run(["nmcli", "connection", "down", "id", n.ssid])
        } else if (!n.secure || saved.includes(n.ssid)) {
            busy = n.ssid
            run(["nmcli", "dev", "wifi", "connect", n.ssid])
        } else {
            prompt = n.ssid
            pw = ""
            error = ""
        }
    }

    function submitPw() {
        if (pw === "") return
        busy = prompt
        pwProc.command = ["nmcli", "--ask", "dev", "wifi", "connect", prompt]
        pwProc.running = true
    }

    function activateDev(d) {
        if (!d) return
        if (d.connected) d.disconnect()
        else if (d.paired) d.connect()
        else {
            d.trusted = true
            d.pair()
        }
    }

    function handleKey(e) {
        const k = e.key
        if (prompt !== "") {
            if (k === Qt.Key_Escape) { prompt = ""; pw = ""; error = "" }
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) submitPw()
            else if (k === Qt.Key_Backspace) pw = pw.slice(0, -1)
            else if (e.text && e.text.length === 1 && e.text >= " ") pw += e.text
            else return
            e.accepted = true
            return
        }
        if (k === Qt.Key_Tab || k === Qt.Key_Backtab) tab = 1 - tab
        else if (tab === 0) {
            if (k === Qt.Key_J || k === Qt.Key_Down) wsel = Math.min(networks.length - 1, wsel + 1)
            else if (k === Qt.Key_K || k === Qt.Key_Up) wsel = Math.max(0, wsel - 1)
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) activateNet(networks[wsel])
            else if (k === Qt.Key_T) run(["nmcli", "radio", "wifi", wifiOn ? "off" : "on"])
            else if (k === Qt.Key_R) scanProc.running = true
            else return
        } else {
            if (k === Qt.Key_J || k === Qt.Key_Down) bsel = Math.min(devices.length - 1, bsel + 1)
            else if (k === Qt.Key_K || k === Qt.Key_Up) bsel = Math.max(0, bsel - 1)
            else if (k === Qt.Key_Return || k === Qt.Key_Enter) activateDev(devices[bsel])
            else if (k === Qt.Key_T && adapter) adapter.enabled = !adapter.enabled
            else if (k === Qt.Key_S && adapter) adapter.discovering = !adapter.discovering
            else if (k === Qt.Key_X) devices[bsel]?.forget()
            else return
        }
        e.accepted = true
    }

    Timer {
        interval: 8000
        repeat: true
        running: root.tab === 0 && root.wifiOn
        onTriggered: scanProc.running = true
    }

    Process {
        id: radioProc
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.wifiOn = this.text.trim() === "enabled"
        }
    }

    Process {
        id: savedProc
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: root.saved = this.text.split("\n").filter(s => s !== "")
        }
    }

    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                const best = {}
                for (const line of this.text.split("\n")) {
                    if (!line) continue
                    const f = root.splitT(line)
                    const ssid = f[3]
                    if (!ssid) continue
                    const n = { ssid: ssid, active: f[0] === "*", signal: +f[1], secure: f[2] !== "" && f[2] !== "--" }
                    const old = best[ssid]
                    if (!old || n.active || (!old.active && n.signal > old.signal)) best[ssid] = n
                }
                root.networks = Object.values(best).sort((a, b) => (b.active - a.active) || (b.signal - a.signal))
                if (root.wsel >= root.networks.length) root.wsel = Math.max(0, root.networks.length - 1)
            }
        }
    }

    Process {
        id: actProc
        onExited: (exitCode, exitStatus) => {
            root.busy = ""
            root.refresh()
        }
    }

    Process {
        id: pwProc
        stdinEnabled: true
        onStarted: {
            write(root.pw + "\n")
            root.pw = ""
        }
        onExited: (exitCode, exitStatus) => {
            root.busy = ""
            if (exitCode !== 0) root.error = "the word was wrong"
            else { root.prompt = ""; root.error = "" }
            root.refresh()
        }
    }

    Column {
        anchors.fill: parent
        spacing: 16

        Text {
            text: "Star of Ruin"
            color: Theme.rose
            font.family: Theme.titleFont
            font.pixelSize: 22
            font.bold: true
            font.letterSpacing: 4
        }

        Row {
            spacing: 28

            Repeater {
                model: root.tabs

                Item {
                    id: tabItem
                    required property string modelData
                    required property int index
                    readonly property bool on: index === root.tab

                    width: tabLabel.implicitWidth
                    height: tabLabel.implicitHeight + 8

                    Text {
                        id: tabLabel
                        text: tabItem.modelData
                        color: tabItem.on ? Theme.text : Theme.mist
                        font.family: Theme.titleFont
                        font.pixelSize: 11
                        font.letterSpacing: 2
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }

                    Rectangle {
                        anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
                        width: tabItem.on ? parent.width : 0
                        height: 1
                        color: Theme.soulflame
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tab = tabItem.index
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: parent.height - y

            Column {
                visible: root.tab === 0
                anchors.fill: parent
                anchors.bottomMargin: 24
                spacing: 10

                Text {
                    text: "WI-FI · " + (root.wifiOn ? "AWAKE" : "ASLEEP")
                    color: root.wifiOn ? Theme.text : Theme.mist
                    font.family: Theme.titleFont
                    font.pixelSize: 10
                    font.letterSpacing: 2
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.run(["nmcli", "radio", "wifi", root.wifiOn ? "off" : "on"])
                    }
                }

                ListView {
                    id: wlist
                    width: parent.width
                    height: parent.height - y - (root.prompt !== "" ? 90 : 0)
                    clip: true
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.networks
                    currentIndex: root.wsel
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Item {
                        id: net
                        required property var modelData
                        required property int index
                        readonly property bool on: index === root.wsel

                        width: wlist.width
                        height: 34

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: Theme.ember
                            opacity: net.on ? 0.3 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        Rectangle {
                            y: 8
                            width: 2
                            height: net.on ? 18 : 0
                            color: Theme.soulflame
                            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
                        }

                        Text {
                            x: 16
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 170
                            elide: Text.ElideRight
                            text: net.modelData.ssid
                            color: net.modelData.active ? Theme.text : Theme.mist
                            font.family: Theme.accentFont
                            font.pixelSize: 15
                            font.capitalization: Font.AllLowercase
                        }

                        Row {
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            spacing: 12

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: text !== ""
                                text: root.busy === net.modelData.ssid ? "BINDING…" : net.modelData.active ? "BOUND" : ""
                                color: Theme.soulflame
                                font.family: Theme.titleFont
                                font.pixelSize: 9
                                font.letterSpacing: 2
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: net.modelData.secure ? "ᛉ" : " "
                                color: Theme.mist
                                font.family: Theme.runeFont
                                font.pixelSize: 13
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Repeater {
                                    model: [1, 30, 55, 80]

                                    Rectangle {
                                        required property int modelData
                                        required property int index
                                        anchors.bottom: parent.bottom
                                        width: 3
                                        height: 4 + index * 3
                                        color: net.modelData.signal >= modelData ? Theme.soulflame : Theme.steel
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.wsel = net.index
                            onClicked: root.activateNet(net.modelData)
                        }
                    }
                }

                Column {
                    visible: root.prompt !== ""
                    width: parent.width
                    spacing: 6

                    Text {
                        text: "speak the word for " + root.prompt
                        color: Theme.mist
                        font.family: Theme.accentFont
                        font.pixelSize: 15
                        font.capitalization: Font.AllLowercase
                    }
                    Text {
                        text: root.pw.length ? "•".repeat(root.pw.length) : "…"
                        color: Theme.text
                        font.family: Theme.bodyFont
                        font.pixelSize: 16
                        font.letterSpacing: 2
                    }
                    Text {
                        visible: root.error !== ""
                        text: root.error
                        color: Theme.mist
                        font.family: Theme.accentFont
                        font.pixelSize: 14
                    }
                }
            }

            Column {
                visible: root.tab === 1
                anchors.fill: parent
                anchors.bottomMargin: 24
                spacing: 10

                Row {
                    spacing: 24

                    Text {
                        text: "BLUETOOTH · " + (root.adapter?.enabled ? "AWAKE" : "ASLEEP")
                        color: root.adapter?.enabled ? Theme.text : Theme.mist
                        font.family: Theme.titleFont
                        font.pixelSize: 10
                        font.letterSpacing: 2
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
                        }
                    }

                    Text {
                        visible: root.adapter?.enabled ?? false
                        text: root.adapter?.discovering ? "SEEKING…" : "SEEK"
                        color: root.adapter?.discovering ? Theme.soulflame : Theme.mist
                        font.family: Theme.titleFont
                        font.pixelSize: 10
                        font.letterSpacing: 2
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.adapter.discovering = !root.adapter.discovering
                        }
                    }
                }

                ListView {
                    id: blist
                    width: parent.width
                    height: parent.height - y
                    clip: true
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.devices
                    currentIndex: root.bsel
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: Item {
                        id: dev
                        required property var modelData
                        required property int index
                        readonly property bool on: index === root.bsel

                        width: blist.width
                        height: 34

                        Connections {
                            target: dev.modelData
                            function onPairedChanged() {
                                if (dev.modelData.paired && !dev.modelData.connected) dev.modelData.connect()
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: Theme.ember
                            opacity: dev.on ? 0.3 : 0
                            Behavior on opacity { NumberAnimation { duration: 120 } }
                        }

                        Rectangle {
                            y: 8
                            width: 2
                            height: dev.on ? 18 : 0
                            color: Theme.soulflame
                            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curve } }
                        }

                        Text {
                            x: 16
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 170
                            elide: Text.ElideRight
                            text: dev.modelData.name || dev.modelData.deviceName || dev.modelData.address
                            color: dev.modelData.connected ? Theme.text : Theme.mist
                            font.family: Theme.accentFont
                            font.pixelSize: 15
                            font.capitalization: Font.AllLowercase
                        }

                        Row {
                            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                            spacing: 12

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: dev.modelData.batteryAvailable
                                text: Math.round(dev.modelData.battery * 100) + "%"
                                color: Theme.mist
                                font.family: Theme.bodyFont
                                font.pixelSize: 11
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: dev.modelData.pairing ? "BINDING…"
                                    : dev.modelData.connected ? "BOUND"
                                    : dev.modelData.paired ? "KNOWN" : "NEW"
                                color: dev.modelData.connected || dev.modelData.pairing ? Theme.soulflame : Theme.mist
                                font.family: Theme.titleFont
                                font.pixelSize: 9
                                font.letterSpacing: 2
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.bsel = dev.index
                            onClicked: root.activateDev(dev.modelData)
                        }
                    }
                }
            }

            Text {
                anchors.bottom: parent.bottom
                text: root.prompt !== "" ? "⏎ SPEAK    ESC · SILENCE"
                    : root.tab === 0 ? "⇥ ASPECT    J K · SEEK    ⏎ BIND    T · WAKE/SLEEP    R · RESCAN"
                    : "⇥ ASPECT    J K · SEEK    ⏎ BIND    T · WAKE/SLEEP    S · SEEK DEVICES    X · FORGET"
                color: Theme.mist
                opacity: 0.6
                font.family: Theme.titleFont
                font.pixelSize: 9
                font.letterSpacing: 2
            }
        }
    }
}
