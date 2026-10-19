pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Live niri state from `niri msg -j event-stream`.
Singleton {
    id: niri

    property var workspaces: []          // raw niri workspace objects
    property var windows: ({})           // window id -> raw niri window
    property var focusedWindowId: null

    readonly property var focusedWindow: focusedWindowId !== null ? (windows[focusedWindowId] || null) : null
    readonly property string focusedOutput: {
        var w = workspaces.find(w => w.is_focused)
        return w ? w.output : ""
    }

    function workspacesOn(output) {
        return workspaces.filter(w => w.output === output).sort((a, b) => a.idx - b.idx)
    }

    // windows of a workspace, left to right in niri's scrolling layout
    function windowsIn(wsId) {
        var out = []
        for (var k in windows) if (windows[k].workspace_id === wsId) out.push(windows[k])
        var col = w => (w.layout && w.layout.pos_in_scrolling_layout) ? w.layout.pos_in_scrolling_layout[0] : 999
        return out.sort((a, b) => col(a) - col(b))
    }

    // Same monitor: plain focus-workspace (no pointer warp). Other monitor:
    // focus that workspace by id over the IPC socket rather than focus-monitor,
    // which re-centers the pointer.
    function focusWorkspace(output, idx) {
        if (output === focusedOutput) {
            Quickshell.execDetached(["niri", "msg", "action", "focus-workspace", String(idx)])
            return
        }
        var ws = workspaces.find(w => w.output === output && w.idx === idx)
        if (ws) {
            var req = JSON.stringify({ Action: { FocusWorkspace: { reference: { Id: ws.id } } } })
            Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | socat - "$NIRI_SOCKET" >/dev/null', "sh", req])
        } else {
            Quickshell.execDetached(["sh", "-c", 'niri msg action focus-monitor "$1" && niri msg action focus-workspace "$2"',
                                     "sh", output, String(idx)])
        }
    }

    function focusWindow(id) {
        Quickshell.execDetached(["niri", "msg", "action", "focus-window", "--id", String(id)])
    }

    function _handle(ev) {
        if (ev.WorkspacesChanged) {
            workspaces = ev.WorkspacesChanged.workspaces
        } else if (ev.WorkspaceActivated) {
            var a = ev.WorkspaceActivated
            var target = workspaces.find(w => w.id === a.id)
            if (!target) return
            workspaces = workspaces.map(function(w) {
                var c = Object.assign({}, w)
                if (w.output === target.output) c.is_active = (w.id === a.id)
                if (a.focused) c.is_focused = (w.id === a.id)
                return c
            })
        } else if (ev.WorkspaceActiveWindowChanged) {
            var e = ev.WorkspaceActiveWindowChanged
            workspaces = workspaces.map(w => w.id === e.workspace_id
                ? Object.assign({}, w, { active_window_id: e.active_window_id }) : w)
        } else if (ev.WindowsChanged) {
            var m = {}
            ev.WindowsChanged.windows.forEach(function(w) {
                m[w.id] = w
                if (w.is_focused) focusedWindowId = w.id
            })
            windows = m
        } else if (ev.WindowOpenedOrChanged) {
            var win = ev.WindowOpenedOrChanged.window
            var m2 = Object.assign({}, windows)
            m2[win.id] = win
            windows = m2
            if (win.is_focused) focusedWindowId = win.id
        } else if (ev.WindowLayoutsChanged) {
            var m3 = Object.assign({}, windows)
            ev.WindowLayoutsChanged.changes.forEach(function(ch) {
                if (m3[ch[0]]) m3[ch[0]] = Object.assign({}, m3[ch[0]], { layout: ch[1] })
            })
            windows = m3
        } else if (ev.WindowClosed) {
            var m4 = Object.assign({}, windows)
            delete m4[ev.WindowClosed.id]
            windows = m4
            if (focusedWindowId === ev.WindowClosed.id) focusedWindowId = null
        } else if (ev.WindowFocusChanged) {
            focusedWindowId = ev.WindowFocusChanged.id
        }
    }

    Process {
        id: stream
        command: ["niri", "msg", "-j", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try { niri._handle(JSON.parse(data)) } catch (e) {}
            }
        }
        onExited: restart.start()   // niri restarted or IPC hiccup
    }

    Timer {
        id: restart
        interval: 2000
        onTriggered: stream.running = true
    }
}
