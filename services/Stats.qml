pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// System telemetry sampled every 1.5s (5s in power saver) from /proc and /sys.
// GPU is the integrated AMD one: polling nvidia-smi would keep the dGPU awake.
Singleton {
    id: stats

    readonly property int historyLen: 60

    property real cpu: 0                 // 0..1
    property var cores: []               // per-core 0..1
    property var cpuHistory: []
    property real memUsed: 0             // bytes
    property real memTotal: 1
    property real swapUsed: 0
    property real swapTotal: 0
    property var memHistory: []
    property real tempC: 0
    property var tempHistory: []
    property real gpu: 0                 // 0..1
    property var gpuHistory: []
    property real rxRate: 0              // bytes/s
    property real txRate: 0
    property var rxHistory: []
    property var txHistory: []
    property real netPeak: 1             // auto-scale for net graphs
    property string load: ""
    property real uptime: 0
    property var disks: []               // [{ mount, used, free, size }]; free = what you can write (df avail)
    property var procs: []               // [{ pid, name, cpu, mem }]
    property bool wantProcs: false       // set while the system card is open

    readonly property real mem: memTotal > 0 ? memUsed / memTotal : 0

    property var _prevCpu: []            // [[idle, total] per line]
    property real _prevRx: -1
    property real _prevTx: -1
    property real _prevT: 0

    function _push(arr, v) {
        var a = arr.slice(arr.length >= historyLen ? 1 : 0)
        a.push(v)
        return a
    }

    // read straight from /proc and /sys: no process per sample
    FileView { id: fStat; path: "/proc/stat"; blockLoading: true; printErrors: false }
    FileView { id: fMem; path: "/proc/meminfo"; blockLoading: true; printErrors: false }
    FileView { id: fNet; path: "/proc/net/dev"; blockLoading: true; printErrors: false }
    FileView { id: fLoad; path: "/proc/loadavg"; blockLoading: true; printErrors: false }
    FileView { id: fUp; path: "/proc/uptime"; blockLoading: true; printErrors: false }
    FileView { id: fTemp; path: stats.tempPath; blockLoading: true; printErrors: false }
    FileView { id: fGpu; path: stats.gpuPath; blockLoading: true; printErrors: false }
    property string tempPath: ""
    property string gpuPath: ""

    // sensor paths move between boots; find them once
    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do [ \"$(cat $h/name)\" = k10temp ] && echo $h/temp1_input && break; done; echo; ls /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var l = this.text.split("\n")
                stats.tempPath = l[0] || ""
                stats.gpuPath = l[2] || ""
            }
        }
    }

    function sample() {
        var read = f => { if (f.path === "") return ""; f.reload(); return f.text() }
        _parse(read(fStat) + "\n@MEM\n" + read(fMem) + "\n@NET\n" + read(fNet) + "\n@TEMP\n" + read(fTemp)
            + "\n@GPU\n" + read(fGpu) + "\n@LOAD\n" + read(fLoad) + "\n@UP\n" + read(fUp))
    }

    function _parse(text) {
        var sec = { STAT: [] }, cur = "STAT"
        text.split("\n").forEach(function(l) {
            if (l.charAt(0) === "@") { cur = l.slice(1); sec[cur] = [] }
            else if (l !== "") sec[cur].push(l)
        })

        // cpu
        var cpuLines = sec.STAT.filter(l => l.startsWith("cpu"))
        var usage = [], prev = []
        cpuLines.forEach(function(l, i) {
            var f = l.trim().split(/\s+/).slice(1).map(Number)
            var idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0)
            prev.push([idle, total])
            var p = stats._prevCpu[i]
            usage.push(p && total > p[1] ? 1 - (idle - p[0]) / (total - p[1]) : 0)
        })
        _prevCpu = prev
        cpu = usage[0] || 0
        cores = usage.slice(1)
        cpuHistory = _push(cpuHistory, cpu)

        // memory
        var mi = {}
        ;(sec.MEM || []).forEach(function(l) {
            var m = l.match(/^(\w+):\s+(\d+)/)
            if (m) mi[m[1]] = Number(m[2]) * 1024
        })
        memTotal = mi.MemTotal || 1
        memUsed = memTotal - (mi.MemAvailable || 0)
        swapTotal = mi.SwapTotal || 0
        swapUsed = swapTotal - (mi.SwapFree || 0)
        memHistory = _push(memHistory, mem)

        // network (all non-loopback interfaces)
        var rx = 0, tx = 0
        ;(sec.NET || []).slice(2).forEach(function(l) {
            var parts = l.trim().split(/[:\s]+/)
            if (parts[0] === "lo") return
            rx += Number(parts[1]); tx += Number(parts[9])
        })
        var now = Date.now() / 1000
        if (_prevRx >= 0 && now > _prevT) {
            rxRate = Math.max(0, (rx - _prevRx) / (now - _prevT))
            txRate = Math.max(0, (tx - _prevTx) / (now - _prevT))
        }
        _prevRx = rx; _prevTx = tx; _prevT = now
        rxHistory = _push(rxHistory, rxRate)
        txHistory = _push(txHistory, txRate)
        netPeak = Math.max(64 * 1024, ...rxHistory, ...txHistory)

        tempC = Number((sec.TEMP || [])[0] || 0) / 1000
        tempHistory = _push(tempHistory, Math.min(1, tempC / 100))
        gpu = Number((sec.GPU || [])[0] || 0) / 100
        gpuHistory = _push(gpuHistory, gpu)
        load = ((sec.LOAD || [])[0] || "").split(" ").slice(0, 3).join(" ")
        uptime = Number(((sec.UP || [])[0] || "0").split(" ")[0])
    }

    Timer {
        interval: System.lowPower ? 5000 : 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: stats.sample()
    }

    // disks: slow-changing
    Process {
        id: diskProc
        command: ["sh", "-c", "df -B1 --output=target,used,avail,size -x tmpfs -x devtmpfs -x efivarfs -x overlay | tail -n +2"]
        stdout: StdioCollector {
            onStreamFinished: {
                stats.disks = this.text.trim().split("\n").map(function(l) {
                    var f = l.trim().split(/\s+/)
                    return { mount: f[0], used: Number(f[1]), free: Number(f[2]), size: Number(f[3]) }
                }).filter(d => d.size > 1e9 && !d.mount.startsWith("/boot"))
            }
        }
    }
    Timer { interval: 60000; running: true; repeat: true; triggeredOnStart: true; onTriggered: diskProc.running = true }

    // top processes: only while someone is looking
    Process {
        id: procProc
        command: ["sh", "-c", "ps -eo pid,pcpu,pmem,comm --sort=-pcpu --no-headers | head -n 8"]
        stdout: StdioCollector {
            onStreamFinished: {
                stats.procs = this.text.trim().split("\n").filter(l => l !== "").map(function(l) {
                    var f = l.trim().split(/\s+/)
                    return { pid: Number(f[0]), cpu: Number(f[1]), mem: Number(f[2]), name: f.slice(3).join(" ") }
                })
            }
        }
    }
    Timer { interval: 2000; running: stats.wantProcs; repeat: true; triggeredOnStart: true; onTriggered: procProc.running = true }

    function kill(pid) { Quickshell.execDetached(["kill", String(pid)]) }
}
