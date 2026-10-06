import Quickshell
import QtQuick
import "modules"
import "singletons"

ShellRoot {
    Bar {}
    Launcher {}
    Notifications {}
    Clipboard {}
    PowerMenu {}
    ControlCenter {}
        Component.onCompleted: Eq.restore()
    WallpaperLayer {}
    WallpaperPicker {}
}
