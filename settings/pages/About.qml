import QtQuick
import Quickshell
import Quickshell.Io
import "../../services"
import "../../components"

Column {
    id: pg
    spacing: 18
    property var info: ({})

    Process {
        running: true
        command: ["sh", "-c", ". /etc/os-release; echo \"os=$PRETTY_NAME\"; echo \"host=$(cat /etc/hostname)\"; echo \"kernel=$(uname -r)\";"
            + "echo \"cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//')\"; echo \"threads=$(nproc)\";"
            + "echo \"mem=$(awk '/MemTotal/{printf \"%.1f GiB\", $2/1048576}' /proc/meminfo)\";"
            + "lspci | grep -iE 'vga|3d' | sed 's/.*: //;s/^/gpu=/';"
            + "echo \"niri=$(niri --version | cut -d' ' -f2)\"; echo \"quickshell=$(qs --version | head -1 | cut -d' ' -f2)\";"
            + "echo \"pkgs=$(pacman -Qq | wc -l)\"; echo \"shell=$(basename $SHELL)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var o = { gpu: [] }
                this.text.trim().split("\n").forEach(l => {
                    var i = l.indexOf("="), k = l.slice(0, i), v = l.slice(i + 1)
                    if (k === "gpu") o.gpu.push(v.replace(/ \(rev.*\)/, "")); else o[k] = v
                })
                pg.info = o
            }
        }
    }

    // neofetch-ish: big logo + key/value list
    Section {
        title: Quickshell.env("USER") + "@" + (pg.info.host || "")
        hue: Theme.hue("mem")
        Row {
            spacing: 24
            Icon { name: "arch"; size: 120; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
            Column {
                spacing: 5
                Repeater {
                    model: [
                        ["os", pg.info.os], ["kernel", pg.info.kernel], ["wm", "niri " + (pg.info.niri || "")],
                        ["shell", "drift on quickshell " + (pg.info.quickshell || "")], ["login", pg.info.shell],
                        ["cpu", (pg.info.cpu || "") + " (" + (pg.info.threads || "") + ")"], ["memory", pg.info.mem],
                        ["packages", pg.info.pkgs], ["uptime", Theme.duration(Stats.uptime || 0)]
                    ].concat((pg.info.gpu || []).map(g => ["gpu", g]))
                    Row {
                        required property var modelData
                        required property int index
                        spacing: 8
                        Label { width: 80; text: modelData[0]; color: Theme.ramp("gh", 0.3 + 0.7 * index / 10); font.bold: true }
                        Label { width: 420; text: modelData[1] || "-" }
                    }
                }
                Row {
                    topPadding: 6
                    spacing: 0
                    Repeater {
                        model: [Theme.accent, Theme.accent2, Theme.accent3, Theme.hue("cpu"), Theme.hue("mem"), Theme.hue("temp"), Theme.hue("gpu"), Theme.hue("gh")]
                        Rectangle { required property color modelData; width: 22; height: 12; color: modelData }
                    }
                }
            }
        }
    }

    Section {
        title: "drift"
        hue: Theme.accent2
        Label {
            width: parent.width
            wrapMode: Text.Wrap
            color: Theme.dim
            text: "a pixel shell for niri. settings live in " + Config.path + " and apply instantly; edit it by hand if you like."
        }
        Row {
            spacing: 8
            Chip { text: "reload drift"; icon: "restart"; onClicked: Quickshell.reload(false) }
            Chip { text: "open config"; icon: "pencil"; onClicked: Qt.openUrlExternally("file://" + Config.path) }
            Chip { text: "reset settings"; icon: "sweep"; danger: true; onClicked: Config.reset() }
        }
    }
}
