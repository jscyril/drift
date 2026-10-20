import Quickshell
import Quickshell.Io
import QtQuick
import "services"
import "settings"

ShellRoot {
    id: root
    // singletons start on first use; the wallpaper rotation must run from launch
    readonly property var wallpapers: Wallpapers
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    // settings window: only exists while open
    LazyLoader {
        id: settings
        SettingsWindow {
            visible: true
            onVisibleChanged: if (!visible) settings.active = false
        }
    }
    // session menu (Win+Z)
    LazyLoader {
        id: session
        SessionMenu { onClose: session.active = false }
    }

    // clipboard history (Mod+Shift+V) and capture menu (Print)
    LazyLoader { id: clipLoader; ClipboardMenu { onClose: clipLoader.active = false } }
    LazyLoader { id: capLoader; CaptureMenu { onClose: capLoader.active = false } }

    // lock screen: always present so locking is instant
    Lock { id: lockScreen }

    // volume / mic / brightness pop-up
    property string osdKind: "volume"
    LazyLoader { id: osdLoader; Osd { kind: root.osdKind } }
    Timer { id: osdHide; interval: 1400; onTriggered: osdLoader.active = false }
    function osd(kind) { osdKind = kind; osdLoader.active = true; osdHide.restart() }

    Connections {
        target: System
        function onLockRequested() { lockScreen.lock() }
        function onOpenSettings(page) {
            settings.active = true
            if (page !== "") settings.item.page = page
        }
    }

    // usually reached through the `drift` command (bin/drift), e.g. `drift lock`
    IpcHandler {
        target: "drift"
        function toggle(card: string): void {
            if (card === "settings") System.openSettings("")
            else System.requestCard(card)
        }
        function settings(page: string): void { System.openSettings(page) }
        function session(): void { session.active = !session.active }
        function clipboard(): void { clipLoader.active = !clipLoader.active }
        function capture(): void { capLoader.active = !capLoader.active }
        function lock(): void { lockScreen.lock() }
        function updatesRefresh(): void { Updates.refresh() }

        // media keys: change the value, then show the pop-up
        function volumeUp(): void { System.setVolume(System.volume + 0.05); root.osd("volume") }
        function volumeDown(): void { System.setVolume(System.volume - 0.05); root.osd("volume") }
        function volumeMute(): void { System.toggleMute(); root.osd("volume") }
        function micMute(): void { System.toggleMicMute(); root.osd("mic") }
        function brightnessUp(): void { System.setBrightness(System.brightness + 0.05); root.osd("brightness") }
        function brightnessDown(): void { System.setBrightness(System.brightness - 0.05); root.osd("brightness") }
    }
}
