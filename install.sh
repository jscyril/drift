#!/usr/bin/env bash
# drift installer (for a git clone; Arch users can also use the PKGBUILD).
#
#   ./install.sh            link this folder into ~/.config/quickshell/drift
#   ./install.sh --copy     copy instead of link (lets you delete the clone)
#   ./install.sh --no-fonts don't download fonts
#
# Installs the `drift` command to ~/.local/bin, fetches the two fonts drift
# needs if they're missing, and reports any missing programs.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mode=link
fonts=yes
for a in "$@"; do
    case "$a" in
        --copy) mode=copy ;;
        --no-fonts) fonts=no ;;
        -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $a" >&2; exit 2 ;;
    esac
done

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }

# ── programs ──
bold "checking programs"
# command:package (Arch names)
required=(qs:quickshell niri:niri matugen:matugen jq:jq socat:socat nmcli:networkmanager
          brightnessctl:brightnessctl notify-send:libnotify wl-copy:wl-clipboard)
optional=(cliphist:cliphist grim:grim slurp:slurp swappy:swappy gpu-screen-recorder:gpu-screen-recorder
          checkupdates:pacman-contrib paru:paru fuser:psmisc kitty:kitty bluetoothctl:bluez vicinae:vicinae)
missing_req=() missing_opt=()
for e in "${required[@]}"; do command -v "${e%%:*}" >/dev/null || missing_req+=("${e#*:}"); done
for e in "${optional[@]}"; do command -v "${e%%:*}" >/dev/null || missing_opt+=("${e#*:}"); done
if ((${#missing_req[@]})); then
    warn "missing (required): ${missing_req[*]}"
    warn "on Arch: sudo pacman -S --needed ${missing_req[*]}"
else
    ok "all required programs found"
fi
((${#missing_opt[@]})) && warn "missing (optional features): ${missing_opt[*]}"

# ── fonts ──
if [[ $fonts == yes ]]; then
    bold "checking fonts"
    fdir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
    mkdir -p "$fdir"
    got_new=no
    if fc-list | grep -i "Departure Mono" >/dev/null; then   # no -q: with pipefail an early exit fails the pipe
        ok "Departure Mono"
    else
        tmp="$(mktemp -d)"
        curl -fsSL -o "$tmp/dm.zip" https://github.com/rektdeckard/departure-mono/releases/download/v1.500/DepartureMono-1.500.zip
        unzip -oqj "$tmp/dm.zip" "*/DepartureMono-Regular.otf" -d "$fdir"
        rm -rf "$tmp"
        ok "Departure Mono (downloaded)"; got_new=yes
    fi
    if fc-list | grep -i "Material Design Icons Desktop" >/dev/null; then
        ok "Material Design Icons Desktop"
    else
        curl -fsSL -o "$fdir/MaterialDesignIconsDesktop.ttf" \
            https://raw.githubusercontent.com/Templarian/MaterialDesign-Font/master/MaterialDesignIconsDesktop.ttf
        ok "Material Design Icons Desktop (downloaded)"; got_new=yes
    fi
    [[ $got_new == yes ]] && fc-cache -f >/dev/null
fi

# ── config ──
bold "installing drift"
cfg="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell"
dest="$cfg/drift"
mkdir -p "$cfg"
if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$(readlink -f "$dest")" == "$here" ]]; then
        ok "$dest already points here"
    else
        bak="$dest.bak-$(date +%s)"
        mv "$dest" "$bak"
        warn "moved the existing $dest to $bak"
    fi
fi
if [[ ! -e "$dest" ]]; then
    if [[ $mode == link ]]; then
        ln -s "$here" "$dest"; ok "linked $dest -> $here"
    else
        mkdir -p "$dest"
        tar -C "$here" --exclude=.git --exclude=docs -cf - . | tar -C "$dest" -xf -
        ok "copied to $dest"
    fi
fi

bin="$HOME/.local/bin"
mkdir -p "$bin"
ln -sf "$dest/bin/drift" "$bin/drift"
ok "installed the drift command to $bin/drift"
case ":$PATH:" in *":$bin:"*) ;; *) warn "$bin isn't on your PATH; add it in your shell profile" ;; esac

# ── next steps ──
bold "done"
cat <<'EOF'
  start it now:   drift
  autostart: add this to ~/.config/niri/config.kdl
      spawn-at-startup "drift"
      spawn-at-startup "wl-paste" "--watch" "cliphist" "store"
  keybinds: see the README (Keybinds section)
  stop any other bar / notification daemon (waybar, swaync, dunst, mako...)
EOF
