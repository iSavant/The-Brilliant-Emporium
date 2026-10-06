pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/wallthumbs"

    property string current: ""
    property var files: []

    signal changeRequested(string path)

    function set(path) {
        if (path && path !== current) changeRequested(path)
    }

    function commit(path) {
        current = path
        store.setText(path)
    }

    function thumb(path) {
        return "file://" + thumbDir + "/" + path.split("/").pop() + ".jpg"
    }

    function rescan() {
        scan.running = true
    }

    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/quickshell-wallpaper"
        blockLoading: true
        onLoaded: root.current = text().trim()
    }

    Process {
        id: scan
        command: ["sh", "-c",
            "mkdir -p \"$2\"; find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort | "
            + "while read -r f; do t=\"$2/$(basename \"$f\").jpg\"; "
            + "[ -f \"$t\" ] || magick \"$f\" -thumbnail 1024x640^ -gravity center -extent 1024x640 -quality 85 \"$t\"; "
            + "echo \"$f\"; done",
            "sh", root.dir, root.thumbDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = this.text.split("\n").filter(s => s !== "")
                if (JSON.stringify(list) !== JSON.stringify(root.files)) root.files = list
            }
        }
    }
}
