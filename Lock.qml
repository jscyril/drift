import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import "services"

// drift lock screen (ext-session-lock). The compositor keeps the session
// locked even if drift dies; there is deliberately no way to unlock except PAM.
Scope {
    id: root
    property bool locked: false
    property string password: ""
    property string status: ""          // "", "checking", "wrong"
    property int fails: 0
    signal failed()

    function lock() { if (!locked) { password = ""; status = ""; locked = true } }
    function submit() {
        if (pam.active || password === "") return
        status = "checking"
        pam.start()
    }

    PamContext {
        id: pam
        config: "swaylock"
        onPamMessage: if (responseRequired) respond(root.password)
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.locked = false
                root.fails = 0
                root.status = ""
            } else {
                root.fails++
                root.status = "wrong"
                root.failed()
            }
            root.password = ""
        }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            color: Theme.surface
            LockContent { anchors.fill: parent; lock: root }
        }
    }
}
