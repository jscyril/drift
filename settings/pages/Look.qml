import QtQuick
import "../../services"
import "../../components"

Column {
    id: pg
    spacing: 18
    readonly property var o: Config.opts

    // live palette: what matugen pulled out of the wallpaper right now
    Section {
        title: "palette"
        badge: o.colorMode === "wallpaper" ? "from wallpaper" : "custom"
        Row {
            spacing: 6
            Repeater {
                model: [
                    { n: "accent", c: Theme.accent }, { n: "accent2", c: Theme.accent2 }, { n: "accent3", c: Theme.accent3 },
                    { n: "fg", c: Theme.fg }, { n: "dim", c: Theme.dim }, { n: "raised", c: Theme.raised },
                    { n: "bg", c: Theme.bg }, { n: "surface", c: Theme.surface }
                ]
                Column {
                    required property var modelData
                    spacing: 4
                    PixelBox { width: 64; height: 40; step: 3; fill: modelData.c; stroke: Theme.alpha(Theme.fg, 0.25) }
                    Label { text: modelData.n; color: Theme.dim }
                    Label { text: String(modelData.c).slice(1, 7); color: Theme.alpha(Theme.dim, 0.6); font.pixelSize: 8 }
                }
            }
        }
        Item { width: 1; height: 4 }
        Repeater {
            model: ["cpu", "mem", "temp", "gpu", "down", "time", "gh"]
            Row {
                required property string modelData
                spacing: 10
                Label { width: 48; text: modelData; color: Theme.hue(modelData) }
                Meter { value: 1; ramp: modelData; segments: 60; segW: 6; segH: 8; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }

    Section {
        title: "colors"
        Setting {
            title: "colors from"
            hint: "wallpaper, or your own accent"
            Segmented {
                options: [{ label: "wallpaper", value: "wallpaper" }, { label: "custom", value: "custom" }]
                value: pg.o.colorMode
                onPicked: v => pg.o.colorMode = v
            }
        }
        Setting {
            visible: pg.o.colorMode === "custom"
            title: "accent"
            below: true
            Flow {
                width: parent.width
                spacing: 6
                Repeater {
                    model: ["#7ab8ff", "#3ddc84", "#ffb547", "#ff4f6d", "#b56bff", "#ff6bd6", "#45e0ff", "#ffe066", "#c6e84a", "#a0a0a0"]
                    Item {
                        required property string modelData
                        readonly property bool sel: pg.o.customAccent === modelData
                        width: 28; height: 28
                        PixelBox { anchors.fill: parent; step: 2; fill: modelData; stroke: parent.sel ? Theme.fg : modelData }
                        Label { anchors.centerIn: parent; visible: parent.sel; text: "x"; color: "#000"; font.bold: true }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pg.o.customAccent = modelData }
                    }
                }
                Field {
                    width: 110
                    text: pg.o.customAccent
                    placeholder: "#hex"
                    onCommitted: t => { if (/^#[0-9a-fA-F]{6}$/.test(t.trim())) pg.o.customAccent = t.trim() }
                }
            }
        }
        Setting {
            title: "palette style"
            hint: "how hard matugen pushes the color"
            below: true
            Flow {
                width: parent.width
                spacing: 6
                Repeater {
                    model: [
                        { label: "vibrant", value: "scheme-vibrant" }, { label: "tonal", value: "scheme-tonal-spot" },
                        { label: "expressive", value: "scheme-expressive" }, { label: "fruit salad", value: "scheme-fruit-salad" },
                        { label: "rainbow", value: "scheme-rainbow" }, { label: "content", value: "scheme-content" },
                        { label: "fidelity", value: "scheme-fidelity" }, { label: "neutral", value: "scheme-neutral" },
                        { label: "mono", value: "scheme-monochrome" }
                    ]
                    Chip {
                        required property var modelData
                        text: modelData.label
                        on: pg.o.scheme === modelData.value
                        onClicked: pg.o.scheme = modelData.value
                    }
                }
            }
        }
        Setting {
            title: "meter colors"
            hint: "neon gradients, or tones from the palette"
            Segmented {
                options: [{ label: "neon", value: "neon" }, { label: "palette", value: "wallpaper" }]
                value: pg.o.meterColors
                onPicked: v => pg.o.meterColors = v
            }
        }
    }

    Section {
        title: "surface"
        hue: Theme.accent2
        Setting {
            title: "bar opacity"
            below: true
            MiniSlider {
                width: parent.width
                from: 0.4; to: 1; step: 0.02
                value: pg.o.barOpacity
                format: v => Math.round(v * 100) + "%"
                onMoved: v => pg.o.barOpacity = v
            }
        }
        Toggle { key: "scanlines"; title: "crt fx"; hint: "scanlines and a passing beam" }
    }

    Section {
        title: "motion"
        hue: Theme.accent3
        Setting {
            title: "animation speed"
            hint: "1.0 is the default; higher is snappier"
            below: true
            MiniSlider {
                width: parent.width
                from: 0.5; to: 2; step: 0.1
                value: pg.o.animSpeed
                ramp: "time"
                format: v => v.toFixed(1) + "x"
                onMoved: v => pg.o.animSpeed = v
            }
        }
    }
}
