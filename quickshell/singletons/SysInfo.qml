pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Bluetooth
import Quickshell.Networking
import QtQuick

Singleton {
    id: root

    readonly property var focusedToplevel: {
        const active = Hyprland.activeToplevel
        const ws = Hyprland.focusedWorkspace
        if (!active || !ws) return null
        return active.workspace?.id === ws.id ? active : null
    }

    FileView {
        id: hostFile
        path: "/etc/hostname"
        blockLoading: true
    }
    readonly property string host: hostFile.text().trim()
    readonly property string user: Quickshell.env("USER")

    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? null
    readonly property string media: !player ? ""
        : player.trackArtist ? player.trackArtist + " — " + player.trackTitle
        : player.trackTitle

    readonly property bool bluetoothConnected: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property bool networkConnected: Networking.devices.values.some(d => d.connected)
    readonly property int notifications: Notifs.count

    property string memory: "--"

    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text()
            const total = parseInt(t.match(/MemTotal:\s+(\d+)/)[1])
            const avail = parseInt(t.match(/MemAvailable:\s+(\d+)/)[1])
            root.memory = Math.floor((total - avail) / total * 100) + "%"
        }
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: meminfo.reload()
    }
}
