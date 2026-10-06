pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    property bool dnd: false

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice()) n.dismiss()
    }

    readonly property int popupTimeout: 5000
    readonly property int count: server.trackedNotifications.values.length
    readonly property var history: server.trackedNotifications

    property ListModel popups: ListModel {}
    property var live: ({})

    function indexOf(nid) {
        for (let i = 0; i < popups.count; i++)
            if (popups.get(i).nid === nid) return i
        return -1
    }

    function hidePopup(nid) {
        const i = indexOf(nid)
        if (i >= 0) popups.remove(i)
    }

    function dismiss(nid) {
        const n = live[nid]
        if (n) n.dismiss()
        else hidePopup(nid)
    }

    NotificationServer {
        id: server

        keepOnReload: true
        bodySupported: true
        actionsSupported: false
        imageSupported: false
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true
            const nid = n.id
            root.live[nid] = n

            n.closed.connect(() => {
                root.hidePopup(nid)
                delete root.live[nid]
            })

            if (root.dnd && n.urgency !== NotificationUrgency.Critical) return
            root.popups.insert(0, {
                nid: nid,
                summary: n.summary ?? "",
                appName: n.appName ?? "",
                critical: n.urgency === NotificationUrgency.Critical
            })
        }
    }
}
