pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

// One-click battery saver: power-saver profile, brightness down to 25%,
// bluetooth off, drift's own power saver on.
// Turning it off puts back exactly what was there before.
// State lives in its own file, battery-saver.json: what was there before, or null when off.
// (Not config.json: changing several settings at once there can race its reload.)
Singleton {
    id: bs
    property var saved: null
    readonly property bool on: saved !== null
    function store(v) { saved = v; file.setText(JSON.stringify(v) + "\n") }

    function toggle() { if (on) disable(); else enable() }

    // read the live brightness first (drift's own copy can be stale),
    // then save what's there and switch everything in one go
    function enable() { if (!probe.running) probe.running = true }

    function disable() {
        var b = saved || {}
        if (b.profile !== undefined) PowerProfiles.profile = b.profile
        if (b.brightness > 0 && System.hasBacklight) System.setBrightness(b.brightness)
        if (b.bluetooth && System.adapter) System.adapter.enabled = true
        if (b.powerSaver) Config.opts.powerSaver = b.powerSaver
        store(null)
    }

    Process {
        id: probe
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                var f = this.text.split("\n")[0].split(",")      // name,class,current,percent,max
                var bright = f.length >= 5 && Number(f[4]) > 0 ? Number(f[2]) / Number(f[4]) : -1
                bs.store({
                    profile: PowerProfiles.profile,
                    brightness: bright,
                    bluetooth: System.btEnabled,
                    powerSaver: Config.opts.powerSaver
                })

                PowerProfiles.profile = PowerProfile.PowerSaver
                if (bright > 0.25) System.setBrightness(0.25)
                if (System.adapter && System.adapter.enabled) System.adapter.enabled = false
                Config.opts.powerSaver = "on"
            }
        }
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/drift/battery-saver.json"
        onLoaded: { try { bs.saved = JSON.parse(text()) } catch (e) {} }
    }
}
