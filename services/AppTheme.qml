pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Carries the palette to other apps (Config.themeApps). drift only writes
// files it owns; what each app needs to pick them up:
//
//   kitty, GTK 3/4, niri   one include line, added here the first time. Live for
//                          kitty and niri; GTK apps on their next start. Turning
//                          this off empties the files, so their own colors return.
//   Qt (qt6ct), KDE apps,  a theme named "drift" you select once in the app
//   vicinae, btop, neovim  (see the README); after that it follows along.
//
// Apps that aren't installed (no config folder) are skipped.
Singleton {
    id: at
    readonly property bool on: Config.opts.themeApps
    readonly property var p: Theme.palette
    property bool wrote: false          // only clean up if this session wrote something
    onPChanged: sync()
    onOnChanged: sync()

    readonly property string home: Quickshell.env("HOME")
    readonly property string cfg: Quickshell.env("XDG_CONFIG_HOME") || home + "/.config"
    readonly property string data: Quickshell.env("XDG_DATA_HOME") || home + "/.local/share"

    function sync() {
        if (!p || (!on && !wrote)) return
        wrote = on
        // [exists?, file, emptied when off?, text]
        var files = [
            [cfg + "/kitty", cfg + "/kitty/drift.conf", "1", kitty(p)],
            [cfg + "/gtk-3.0", cfg + "/gtk-3.0/drift.css", "1", gtk(p)],
            [cfg + "/gtk-4.0", cfg + "/gtk-4.0/drift.css", "1", gtk(p)],
            [cfg + "/niri", cfg + "/niri/drift.kdl", "1", niri(p)],
            [cfg + "/qt6ct", cfg + "/qt6ct/colors/drift.conf", "", qt(p)],
            [cfg + "/kdeglobals", data + "/color-schemes/Drift.colors", "", kde(p)],
            [data + "/vicinae", data + "/vicinae/themes/drift.toml", "", vicinae(p)],
            [cfg + "/btop", cfg + "/btop/themes/drift.theme", "", btop(p)],
            [cfg + "/nvim", cfg + "/nvim/colors/drift.lua", "", nvim(p)]
        ]
        writer.running = false
        writer.command = ["sh", "-c", script, "sh", on ? "1" : "", cfg].concat(...files)
        writer.running = true
    }

    // $1 = on, $2 = config dir, then groups of four: exists-test, file, emptied-when-off, text
    readonly property string script: '
        on="$1"; c="$2"; shift 2
        while [ $# -ge 4 ]; do
            if [ -e "$1" ]; then
                if [ -n "$on" ]; then mkdir -p "$(dirname "$2")" && printf %s "$4" > "$2"
                elif [ -n "$3" ] && [ -e "$2" ]; then : > "$2"; fi
            fi
            shift 4
        done
        if [ -n "$on" ]; then
            k="$c/kitty/kitty.conf"
            [ -f "$k" ] && ! grep -q "^include drift.conf" "$k" && printf "\\n# colors from the drift shell\\ninclude drift.conf\\n" >> "$k"
            for g in gtk-3.0 gtk-4.0; do
                [ -d "$c/$g" ] && ! grep -qs "drift.css" "$c/$g/gtk.css" && printf "\\n/* colors from the drift shell */\\n@import \\"drift.css\\";\\n" >> "$c/$g/gtk.css"
            done
            n="$c/niri/config.kdl"
            [ -f "$n" ] && ! grep -q "drift.kdl" "$n" && printf "\\n// colors from the drift shell\\ninclude \\"drift.kdl\\"\\n" >> "$n"
        fi
        pkill -USR1 -x kitty
        [ -e "$c/niri/drift.kdl" ] && niri msg action load-config-file >/dev/null 2>&1
        true'

    Process { id: writer }

    readonly property string note: "written by drift: edits here are overwritten"
    function rgb(h) { return [1, 3, 5].map(i => parseInt(h.substr(i, 2), 16)).join(",") }

    function kitty(p) {
        var l = ["# " + note,
            "foreground " + p.fg, "background " + p.bg,
            "selection_foreground " + p.accentText, "selection_background " + p.accent,
            "cursor " + p.accent, "cursor_text_color " + p.bg, "url_color " + p.accent3,
            "active_border_color " + p.accent, "inactive_border_color " + p.outline,
            "active_tab_foreground " + p.accentText, "active_tab_background " + p.accent,
            "inactive_tab_foreground " + p.dim, "inactive_tab_background " + p.raised]
        p.ansi.forEach((c, i) => l.push("color" + i + " " + c))
        return l.join("\n") + "\n"
    }

    function gtk(p) {
        var c = {
            accent_color: p.accent, accent_bg_color: p.accent, accent_fg_color: p.accentText,
            window_bg_color: p.bg, window_fg_color: p.fg, headerbar_bg_color: p.bg, headerbar_fg_color: p.fg,
            view_bg_color: p.surface, view_fg_color: p.fg, sidebar_bg_color: p.surface, sidebar_fg_color: p.fg,
            sidebar_backdrop_color: p.surface, card_bg_color: p.raised, card_fg_color: p.fg,
            popover_bg_color: p.raised, popover_fg_color: p.fg, dialog_bg_color: p.raised, dialog_fg_color: p.fg,
            // GTK 3 names
            theme_bg_color: p.bg, theme_fg_color: p.fg, theme_base_color: p.surface, theme_text_color: p.fg,
            theme_selected_bg_color: p.accent, theme_selected_fg_color: p.accentText, borders: p.outline
        }
        return "/* " + note + " */\n" + Object.keys(c).map(k => "@define-color " + k + " " + c[k] + ";").join("\n") + "\n"
    }

    function niri(p) {
        var set = (name) => "    " + name + " {\n        active-color \"" + p.accent + "\"\n        inactive-color \"" + p.outline
            + "\"\n        urgent-color \"" + p.ansi[1] + "\"\n    }\n"
        return "// " + note + "\nlayout {\n" + set("focus-ring") + set("border") + set("tab-indicator")
            + "    insert-hint {\n        color \"" + p.accent + "80\"\n    }\n}\n"
    }

    // QPalette roles in qt6ct's order
    function qt(p) {
        var row = (text) => [text, p.raised, p.outline, p.raised, p.surface, p.outline, text, "#ffffff", text, p.surface, p.bg, "#000000",
            p.accent, p.accentText, p.accent3, p.accent2, p.bg, text, p.raised, p.fg, p.dim].map(c => "#ff" + c.slice(1)).join(", ")
        return "[ColorScheme]\nactive_colors=" + row(p.fg) + "\ndisabled_colors=" + row(p.dim) + "\ninactive_colors=" + row(p.fg) + "\n"
    }

    function kde(p) {
        var group = (name, back, alt) => "[Colors:" + name + "]\nBackgroundAlternate=" + rgb(alt) + "\nBackgroundNormal=" + rgb(back)
            + "\nDecorationFocus=" + rgb(p.accent) + "\nDecorationHover=" + rgb(p.accent)
            + "\nForegroundActive=" + rgb(p.accent) + "\nForegroundInactive=" + rgb(p.dim) + "\nForegroundLink=" + rgb(p.accent3)
            + "\nForegroundNegative=" + rgb(p.ansi[1]) + "\nForegroundNeutral=" + rgb(p.ansi[3])
            + "\nForegroundNormal=" + rgb(name === "Selection" ? p.accentText : p.fg)
            + "\nForegroundPositive=" + rgb(p.ansi[2]) + "\nForegroundVisited=" + rgb(p.accent2) + "\n\n"
        return "# " + note + "\n" + group("Button", p.raised, p.bg) + group("Complementary", p.surface, p.bg) + group("Header", p.bg, p.surface)
            + group("Selection", p.accent, p.accent) + group("Tooltip", p.raised, p.bg) + group("View", p.surface, p.bg)
            + group("Window", p.bg, p.surface)
            + "[General]\nColorScheme=Drift\nName=Drift\n\n[WM]\nactiveBackground=" + rgb(p.bg) + "\nactiveForeground=" + rgb(p.fg)
            + "\ninactiveBackground=" + rgb(p.surface) + "\ninactiveForeground=" + rgb(p.dim) + "\n"
    }

    function vicinae(p) {
        var q = c => '"' + c + '"'
        return "# " + note + "\n[meta]\nversion = 1\nname = \"drift\"\ndescription = \"follows the drift shell\"\nvariant = \"dark\"\ninherits = \"vicinae-dark\"\n"
            + "\n[colors.core]\naccent = " + q(p.accent) + "\naccent_foreground = " + q(p.accentText) + "\nbackground = " + q(p.bg)
            + "\nforeground = " + q(p.fg) + "\nsecondary_background = " + q(p.surface) + "\nborder = " + q(p.outline)
            + "\n\n[colors.main_window]\nborder = " + q(p.outline) + "\n\n[colors.settings_window]\nborder = " + q(p.outline)
            + "\n\n[colors.accents]\nblue = " + q(p.ansi[4]) + "\ngreen = " + q(p.ansi[2]) + "\nmagenta = " + q(p.ansi[5]) + "\norange = " + q(p.accent2)
            + "\nred = " + q(p.ansi[1]) + "\nyellow = " + q(p.ansi[3]) + "\ncyan = " + q(p.ansi[6]) + "\npurple = " + q(p.ansi[5])
            + "\n\n[colors.text]\nmuted = " + q(p.dim) + "\ndanger = " + q(p.ansi[1]) + "\nsuccess = " + q(p.ansi[2]) + "\nplaceholder = " + q(p.dim)
            + "\nselection = { background = " + q(p.accent) + ", foreground = " + q(p.accentText) + " }"
            + "\n\n[colors.text.links]\ndefault = " + q(p.accent3) + "\nvisited = " + q(p.accent2)
            + "\n\n[colors.input]\nborder = " + q(p.outline) + "\nborder_focus = " + q(p.accent) + "\nborder_error = " + q(p.ansi[1])
            + "\n\n[colors.button.primary]\nbackground = " + q(p.raised) + "\nforeground = " + q(p.fg)
            + "\n\n[colors.list.item.hover]\nforeground = " + q(p.fg) + "\nsecondary_foreground = " + q(p.fg)
            + "\n\n[colors.list.item.selection]\nbackground = " + q(p.raised) + "\nforeground = " + q(p.fg)
            + "\nsecondary_background = " + q(p.raised) + "\nsecondary_foreground = " + q(p.fg)
            + "\n\n[colors.grid.item]\nbackground = " + q(p.surface) + "\n\n[colors.scrollbars]\nbackground = " + q(p.outline)
            + "\n\n[colors.loading]\nbar = " + q(p.accent) + "\nspinner = " + q(p.fg) + "\n"
    }

    function btop(p) {
        var a = p.ansi, c = {
            main_bg: p.bg, main_fg: p.fg, title: p.fg, hi_fg: p.accent, selected_bg: p.raised, selected_fg: p.accent,
            inactive_fg: p.outline, graph_text: p.dim, meter_bg: p.raised, proc_misc: p.accent3,
            cpu_box: p.accent, mem_box: p.accent3, net_box: p.accent2, proc_box: p.outline, div_line: p.outline,
            temp_start: a[2], temp_mid: a[3], temp_end: a[1], cpu_start: a[2], cpu_mid: a[3], cpu_end: a[1],
            free_start: a[6], free_mid: a[4], free_end: a[5], cached_start: a[4], cached_mid: a[6], cached_end: a[2],
            available_start: a[3], available_mid: a[2], available_end: a[6], used_start: a[2], used_mid: a[3], used_end: a[1],
            download_start: a[6], download_mid: a[4], download_end: a[5], upload_start: a[3], upload_mid: p.accent2, upload_end: a[1],
            process_start: a[2], process_mid: a[3], process_end: a[1]
        }
        return "# " + note + "\n" + Object.keys(c).map(k => "theme[" + k + "]=\"" + c[k] + "\"").join("\n") + "\n"
    }

    function nvim(p) {
        var a = p.ansi, hl = {
            Normal: { fg: p.fg, bg: p.bg }, NormalFloat: { fg: p.fg, bg: p.surface }, FloatBorder: { fg: p.outline, bg: p.surface },
            CursorLine: { bg: p.raised }, CursorLineNr: { fg: p.accent, bold: true }, LineNr: { fg: p.outline }, SignColumn: { bg: p.bg },
            Visual: { bg: p.outline }, Search: { fg: p.accentText, bg: p.accent }, IncSearch: { fg: p.accentText, bg: p.accent2 },
            Pmenu: { fg: p.fg, bg: p.surface }, PmenuSel: { fg: p.accentText, bg: p.accent }, StatusLine: { fg: p.fg, bg: p.raised },
            StatusLineNC: { fg: p.dim, bg: p.surface }, WinSeparator: { fg: p.outline }, VertSplit: { fg: p.outline },
            TabLine: { fg: p.dim, bg: p.surface }, TabLineSel: { fg: p.accentText, bg: p.accent }, Folded: { fg: p.dim, bg: p.surface },
            NonText: { fg: p.outline }, MatchParen: { fg: p.accent2, bold: true }, Directory: { fg: a[4] }, Title: { fg: p.accent, bold: true },
            Comment: { fg: p.dim, italic: true }, Constant: { fg: a[3] }, String: { fg: a[2] }, Number: { fg: p.accent2 },
            Identifier: { fg: p.fg }, Function: { fg: a[4] }, Statement: { fg: a[5] }, Keyword: { fg: a[5] }, Operator: { fg: a[6] },
            PreProc: { fg: a[6] }, Type: { fg: a[3] }, Special: { fg: p.accent }, Delimiter: { fg: p.dim }, Todo: { fg: p.accentText, bg: a[3] },
            Error: { fg: a[1] }, ErrorMsg: { fg: a[1] }, WarningMsg: { fg: a[3] },
            DiagnosticError: { fg: a[1] }, DiagnosticWarn: { fg: a[3] }, DiagnosticInfo: { fg: a[4] }, DiagnosticHint: { fg: a[6] },
            DiffAdd: { fg: a[2] }, DiffChange: { fg: a[3] }, DiffDelete: { fg: a[1] }, DiffText: { fg: a[4], bold: true }
        }
        var lua = v => "{ " + Object.keys(v).map(k => k + " = " + (typeof v[k] === "string" ? '"' + v[k] + '"' : v[k])).join(", ") + " }"
        return "-- " + note + "\nvim.cmd('highlight clear')\nvim.o.background = 'dark'\nvim.g.colors_name = 'drift'\n"
            + Object.keys(hl).map(k => "vim.api.nvim_set_hl(0, '" + k + "', " + lua(hl[k]) + ")").join("\n") + "\n"
            + p.ansi.map((c, i) => "vim.g.terminal_color_" + i + " = '" + c + "'").join("\n") + "\n"
    }
}
