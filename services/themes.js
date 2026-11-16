.pragma library

// Preset themes. Each is the ten chrome colors drift draws with, plus the
// sixteen terminal colors that themed apps get (AppTheme.qml).
// To add one: copy a line, change the key, name and hex values.

var keys = ["surface", "bg", "raised", "fg", "dim", "accent", "accentText", "accent2", "accent3", "outline"]

function make(key, name, chrome, ansi) {
    var t = { key: key, name: name, ansi: ansi }
    keys.forEach(function(k, i) { t[k] = chrome[i] })
    return t
}

var list = [
    //                                   surface    bg         raised     fg         dim        accent     accentText accent2    accent3    outline
    make("catppuccin", "catppuccin",    ["#11111b", "#1e1e2e", "#313244", "#cdd6f4", "#a6adc8", "#cba6f7", "#1e1e2e", "#f5c2e7", "#a6e3a1", "#45475a"],
        ["#45475a", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#f5c2e7", "#94e2d5", "#bac2de",
         "#585b70", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#f5c2e7", "#94e2d5", "#a6adc8"]),
    make("darcula", "darcula",          ["#1e1f22", "#2b2b2b", "#3c3f41", "#a9b7c6", "#808080", "#cc7832", "#1e1f22", "#9876aa", "#6a8759", "#515151"],
        ["#3c3f41", "#ff6b68", "#6a8759", "#ffc66d", "#6897bb", "#9876aa", "#299999", "#a9b7c6",
         "#606366", "#ff8785", "#a8c023", "#ffe2a8", "#7ca8c6", "#b294bb", "#4fb3b3", "#ffffff"]),
    make("dracula", "dracula",          ["#21222c", "#282a36", "#44475a", "#f8f8f2", "#9ea8c7", "#bd93f9", "#282a36", "#ff79c6", "#50fa7b", "#44475a"],
        ["#21222c", "#ff5555", "#50fa7b", "#f1fa8c", "#bd93f9", "#ff79c6", "#8be9fd", "#f8f8f2",
         "#6272a4", "#ff6e6e", "#69ff94", "#ffffa5", "#d6acff", "#ff92df", "#a4ffff", "#ffffff"]),
    make("gruvbox", "gruvbox",          ["#1d2021", "#282828", "#3c3836", "#ebdbb2", "#a89984", "#fabd2f", "#282828", "#fe8019", "#b8bb26", "#504945"],
        ["#282828", "#cc241d", "#98971a", "#d79921", "#458588", "#b16286", "#689d6a", "#a89984",
         "#928374", "#fb4934", "#b8bb26", "#fabd2f", "#83a598", "#d3869b", "#8ec07c", "#ebdbb2"]),
    make("nord", "nord",                ["#242933", "#2e3440", "#3b4252", "#eceff4", "#a3adbf", "#88c0d0", "#2e3440", "#b48ead", "#a3be8c", "#4c566a"],
        ["#3b4252", "#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead", "#88c0d0", "#e5e9f0",
         "#4c566a", "#bf616a", "#a3be8c", "#ebcb8b", "#81a1c1", "#b48ead", "#8fbcbb", "#eceff4"]),
    make("tokyonight", "tokyo night",   ["#16161e", "#1a1b26", "#292e42", "#c0caf5", "#a9b1d6", "#7aa2f7", "#16161e", "#bb9af7", "#9ece6a", "#3b4261"],
        ["#15161e", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff", "#a9b1d6",
         "#414868", "#f7768e", "#9ece6a", "#e0af68", "#7aa2f7", "#bb9af7", "#7dcfff", "#c0caf5"]),
    make("rosepine", "rosé pine",       ["#191724", "#1f1d2e", "#26233a", "#e0def4", "#908caa", "#c4a7e7", "#191724", "#ebbcba", "#9ccfd8", "#403d52"],
        ["#26233a", "#eb6f92", "#31748f", "#f6c177", "#9ccfd8", "#c4a7e7", "#ebbcba", "#e0def4",
         "#6e6a86", "#eb6f92", "#31748f", "#f6c177", "#9ccfd8", "#c4a7e7", "#ebbcba", "#e0def4"]),
    make("everforest", "everforest",    ["#232a2e", "#2d353b", "#343f44", "#d3c6aa", "#9da9a0", "#a7c080", "#2d353b", "#e69875", "#7fbbb3", "#475258"],
        ["#343f44", "#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3", "#d699b6", "#83c092", "#d3c6aa",
         "#859289", "#e67e80", "#a7c080", "#dbbc7f", "#7fbbb3", "#d699b6", "#83c092", "#d3c6aa"]),
    make("onedark", "one dark",         ["#21252b", "#282c34", "#2c313a", "#abb2bf", "#7f848e", "#61afef", "#21252b", "#c678dd", "#98c379", "#3e4451"],
        ["#282c34", "#e06c75", "#98c379", "#e5c07b", "#61afef", "#c678dd", "#56b6c2", "#abb2bf",
         "#5c6370", "#e06c75", "#98c379", "#e5c07b", "#61afef", "#c678dd", "#56b6c2", "#ffffff"]),
    make("solarized", "solarized",      ["#00212b", "#002b36", "#073642", "#93a1a1", "#839496", "#268bd2", "#002b36", "#d33682", "#2aa198", "#586e75"],
        ["#073642", "#dc322f", "#859900", "#b58900", "#268bd2", "#d33682", "#2aa198", "#eee8d5",
         "#586e75", "#cb4b16", "#859900", "#b58900", "#268bd2", "#6c71c4", "#2aa198", "#fdf6e3"]),
    make("kanagawa", "kanagawa",        ["#16161d", "#1f1f28", "#2a2a37", "#dcd7ba", "#c8c093", "#7e9cd8", "#16161d", "#957fb8", "#98bb6c", "#363646"],
        ["#16161d", "#c34043", "#76946a", "#c0a36e", "#7e9cd8", "#957fb8", "#6a9589", "#c8c093",
         "#727169", "#e82424", "#98bb6c", "#e6c384", "#7fb4ca", "#938aa9", "#7aa89f", "#dcd7ba"])
]

function get(key) {
    for (var i = 0; i < list.length; i++) if (list[i].key === key) return list[i]
    return null
}

function mixHex(a, b, t) {
    var out = "#"
    for (var i = 1; i < 7; i += 2) {
        var x = parseInt(a.substr(i, 2), 16), y = parseInt(b.substr(i, 2), 16)
        out += ("0" + Math.round(x + (y - x) * t).toString(16)).slice(-2)
    }
    return out
}

// A generated palette (matugen) has no terminal colors: lean the usual six
// hues toward its accent so the terminal sits in the same family.
function withAnsi(p) {
    var hues = ["#ff6b7d", "#7ddc8c", "#ffd27a", "#7ab8ff", "#d39bff", "#6fe0e0"].map(function(h) { return mixHex(h, p.accent, 0.25) })
    var bright = hues.map(function(h) { return mixHex(h, "#ffffff", 0.2) })
    p.ansi = [p.raised].concat(hues, [p.dim], [p.outline], bright, [p.fg])
    return p
}

function selfTest() {
    list.forEach(function(t) {
        console.assert(t.ansi.length === 16, t.key + ": needs 16 terminal colors")
        keys.concat(t.ansi.map(function(_, i) { return i })).forEach(function(k) {
            var v = typeof k === "number" ? t.ansi[k] : t[k]
            console.assert(/^#[0-9a-f]{6}$/.test(v), t.key + ": bad color " + k + " = " + v)
        })
    })
    console.assert(withAnsi({ accent: "#000000", raised: "#111111", dim: "#222222", outline: "#333333", fg: "#444444" }).ansi.length === 16)
    console.assert(mixHex("#000000", "#ffffff", 0.5) === "#808080")
}
