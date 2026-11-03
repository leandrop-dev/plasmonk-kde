# shellcheck shell=bash
# shellcheck disable=SC2034  # variables are consumed by the scripts that source this file
# Shared helpers for install.sh, uninstall.sh and bin/plasmonk. Source, don't execute.

PLASMONK_NAME="Plasmonk"

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

PLASMONK_SHARE="$XDG_DATA_HOME/plasmonk"          # installed copy of this repo's runtime files
PLASMONK_STATE="$XDG_STATE_HOME/plasmonk"         # state file, staging output, backups
PLASMONK_STATE_FILE="$PLASMONK_STATE/state"
PLASMONK_BACKUP_ROOT="$PLASMONK_STATE/backup"
PLASMONK_BIN_LINK="$HOME/.local/bin/plasmonk"
# Overridable so the sandbox test can shim it (it is not on PATH).
PLASMA_CHANGEICONS="${PLASMA_CHANGEICONS:-/usr/lib/plasma-changeicons}"

COLOR_SCHEME_DIR="$XDG_DATA_HOME/color-schemes"
PLASMA_THEME_DIR="$XDG_DATA_HOME/plasma/desktoptheme/$PLASMONK_NAME"
AURORAE_DIR="$XDG_DATA_HOME/aurorae/themes/$PLASMONK_NAME"
KVANTUM_DIR="$XDG_CONFIG_HOME/Kvantum/$PLASMONK_NAME"
ROFI_DIR="$XDG_CONFIG_HOME/rofi"
SYSTEMD_USER_DIR="$XDG_CONFIG_HOME/systemd/user"
APPLETSRC="$XDG_CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc"
GHOSTTY_DIR="$XDG_CONFIG_HOME/ghostty"
ZSH_CFG_DIR="$XDG_CONFIG_HOME/zsh"
STARSHIP_FILE="$XDG_CONFIG_HOME/starship.toml"
FASTFETCH_DIR="$XDG_CONFIG_HOME/fastfetch"
KONSOLE_DATA_DIR="$XDG_DATA_HOME/konsole"
APPS_DIR="$XDG_DATA_HOME/applications"
ZSHRC="$HOME/.zshrc"
DESKTOP_MARKER="# plasmonk override: removed by uninstall.sh"   # first line of .desktop files plasmonk writes
# shellcheck disable=SC2016  # literal line for ~/.zshrc; zsh expands it there
ZSHRC_LINE='[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plasmonk.zsh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/plasmonk.zsh"   # plasmonk'

if [ -t 1 ]; then
    _c_info=$'\e[34m' _c_ok=$'\e[32m' _c_warn=$'\e[33m' _c_err=$'\e[31m' _c_off=$'\e[0m'
else
    _c_info="" _c_ok="" _c_warn="" _c_err="" _c_off=""
fi
info() { printf '%s[*]%s %s\n' "$_c_info" "$_c_off" "$*"; }
ok()   { printf '%s[+]%s %s\n' "$_c_ok" "$_c_off" "$*"; }
warn() { printf '%s[!]%s %s\n' "$_c_warn" "$_c_off" "$*" >&2; }
die()  { printf '%s[x]%s %s\n' "$_c_err" "$_c_off" "$*" >&2; exit 1; }

have() { command -v "$1" >/dev/null 2>&1; }

refuse_root() {
    [ "$(id -u)" -ne 0 ] || die "Do not run this as root or with sudo; it installs into your home folder and asks for sudo itself when needed."
    [ -n "${HOME:-}" ] && [ -d "$HOME" ] || die "HOME is not set to a valid folder."
}

# Read key from the plasmonk state file (key=value lines). Prints nothing if absent.
state_get() {
    [ -f "$PLASMONK_STATE_FILE" ] || return 0
    sed -n "s/^$1=//p" "$PLASMONK_STATE_FILE" | tail -n 1
}

# Write key=value into the state file, replacing any previous value.
state_set() {
    mkdir -p "$PLASMONK_STATE"
    local tmp="$PLASMONK_STATE_FILE.tmp"
    { [ -f "$PLASMONK_STATE_FILE" ] && grep -v "^$1=" "$PLASMONK_STATE_FILE"; printf '%s=%s\n' "$1" "$2"; } >"$tmp"
    mv "$tmp" "$PLASMONK_STATE_FILE"
}

# KDE settings plasmonk changes, as "file|group|key". install.sh records their original values
# once (ORIGINAL_SETTINGS); uninstall.sh writes those values back.
ORIGINAL_SETTINGS="$PLASMONK_STATE/original-settings.tsv"
UNSET_MARK="__plasmonk_unset__"
MANAGED_KEYS=(
    "kdeglobals|General|ColorScheme"
    "kdeglobals|General|AccentColor"
    "kdeglobals|General|accentColorFromWallpaper"
    "kdeglobals|General|fixed"
    "kdeglobals|KDE|widgetStyle"
    "kdeglobals|KDE|AnimationDurationFactor"
    "kdeglobals|Icons|Theme"
    "kwinrc|org.kde.kdecoration2|library"
    "kwinrc|org.kde.kdecoration2|theme"
    "plasmarc|Theme|name"
    "$XDG_CONFIG_HOME/Kvantum/kvantum.kvconfig|General|theme"
    "kwinrc|Plugins|blurEnabled"
    "kwinrc|Plugins|better_blur_dxEnabled"
    "kwinrc|Effect-better-blur-dx|WindowClasses"
    "kwinrc|Effect-better-blur-dx|BlurDecorations"
    "kcminputrc|Mouse|cursorTheme"
    "kdeglobals|General|TerminalApplication"
    "kdeglobals|General|TerminalService"
    "konsolerc|Desktop Entry|DefaultProfile"
    # KDE's shortcut daemon reads Konsole's default (Ctrl+Alt+T) from /usr/share/kglobalaccel, not
    # from the applications/ override, so Konsole's own entry is cleared too.
    "kglobalshortcutsrc|services][org.kde.konsole.desktop|_launch"
)

# Runs kreadconfig6/kwriteconfig6 ($1) on file $2, group path $3, then the remaining arguments.
# Nested groups are written as in the file: "services][org.kde.konsole.desktop".
kconfig() {
    local tool="$1" file="$2" path="$3"
    shift 3
    local args=(--file "$file")
    while [[ "$path" == *"]["* ]]; do
        args+=(--group "${path%%"]["*}")
        path="${path#*"]["}"
    done
    "$tool" "${args[@]}" --group "$path" "$@"
}

# Konsole's default terminal shortcut, which Plasmonk gives to Ghostty, as text and as the Qt key
# code KDE's shortcut daemon takes over D-Bus (Ctrl 0x04000000 + Alt 0x08000000 + T 0x54).
TERMINAL_SHORTCUT="Ctrl+Alt+T"
TERMINAL_KEY=201326676

# Sets the keys of a global shortcut in the running session ($1 = desktop file id, $2 = action,
# $3 = friendly name, $4 = GVariant key list such as "[]" or "[([201326676],)]"). KDE's shortcut
# daemon keeps its own copy in memory and would write it back over kglobalshortcutsrc.
set_live_shortcut() {
    gdbus call --session --dest org.kde.kglobalaccel --object-path /kglobalaccel \
        --method org.kde.KGlobalAccel.setForeignShortcutKeys "['$1', '$2', '$3', '$3']" "@a(ai) $4" >/dev/null 2>&1
}

# Config files (relative to XDG_CONFIG_HOME) that plasmonk renders over. install.sh keeps your
# original once in ORIGINALS_DIR (or a .none marker if there was none); uninstall.sh puts it back.
ORIGINALS_DIR="$PLASMONK_STATE/originals"
REPLACED_FILES=(starship.toml fastfetch/config.jsonc)

# Keeps the pre-Plasmonk version of file $1 (under HOME) once, in ORIGINALS_DIR/home/<path>, or a
# .none marker if it did not exist. uninstall.sh puts each one back (or removes the file).
keep_original() {
    local dst="$ORIGINALS_DIR/home/${1#"$HOME"/}"
    if [ -e "$dst" ] || [ -e "$dst.none" ]; then return 0; fi
    mkdir -p "$(dirname "$dst")"
    if [ -f "$1" ]; then cp -p "$1" "$dst"; else : >"$dst.none"; fi
}

# Apps Plasmonk themes when you have used them (their config folder exists).
VESKTOP_DIR="$XDG_CONFIG_HOME/vesktop"
ZED_DIR="$XDG_CONFIG_HOME/zed"
ZEN_DIR="$XDG_CONFIG_HOME/zen"
THUNDERBIRD_DIR="$XDG_CONFIG_HOME/thunderbird"
VESKTOP_THEME="plasmonk.theme.css"
ZED_THEME="Plasmonk"

# Prints the profile folder a Mozilla-based app ($1 = folder with profiles.ini) opens by
# default: its install's locked default, else the profile marked Default=1.
mozilla_profile() {
    local ini="$1/profiles.ini" rel
    [ -f "$ini" ] || return 1
    rel="$(awk -F= '/^\[Install/ { s = 1; next } /^\[/ { s = 0 } s && $1 == "Default" { print $2; exit }' "$ini")"
    if [ -z "$rel" ]; then
        rel="$(awk -F= '/^\[Profile/ { p = ""; d = 0 } $1 == "Path" { p = $2 } $1 == "Default" && $2 == "1" { d = 1 }
            d && p != "" { print p; exit }' "$ini")"
    fi
    [ -n "$rel" ] || return 1
    case "$rel" in /*) ;; *) rel="$1/$rel" ;; esac
    [ -d "$rel" ] || return 1
    printf '%s\n' "$rel"
}

# Packages from deps/ that were already installed before Plasmonk; uninstall.sh never removes them.
PREINSTALLED_PACKAGES="$PLASMONK_STATE/preinstalled-packages.txt"

# Lists non-comment, non-empty lines of a package list file.
read_list() {
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}

# Prints the theme Zed uses in dark mode: the "dark" entry of a "theme": {...} object, or the
# name of a plain "theme": "Name" setting. $1 = settings.json (JSON with comments).
zed_dark_theme() {
    awk '
        /"theme"[[:space:]]*:[[:space:]]*"/ { sub(/.*"theme"[[:space:]]*:[[:space:]]*"/, ""); sub(/".*/, ""); print; exit }
        /"theme"[[:space:]]*:[[:space:]]*\{/ { inside = 1 }
        inside && /"dark"[[:space:]]*:/ { sub(/.*"dark"[[:space:]]*:[[:space:]]*"/, ""); sub(/".*/, ""); print; exit }
        inside && /\}/ { inside = 0 }' "$1"
}

# Sets Zed's dark-mode theme to $2 in settings.json $1, in place (Zed reloads it live).
zed_set_dark_theme() {
    local tmp="$1.plasmonk-tmp"
    awk -v name="$2" '
        /"theme"[[:space:]]*:[[:space:]]*"/ { sub(/"theme"[[:space:]]*:[[:space:]]*"[^"]*"/, "\"theme\": \"" name "\"") }
        /"theme"[[:space:]]*:[[:space:]]*\{/ { inside = 1 }
        inside && /"dark"[[:space:]]*:/ { sub(/"dark"[[:space:]]*:[[:space:]]*"[^"]*"/, "\"dark\": \"" name "\""); inside = 0 }
        inside && /\}/ { inside = 0 }
        { print }' "$1" >"$tmp"
    cat "$tmp" >"$1"   # keeps the file's permissions
    rm -f -- "$tmp"
}

# SDDM login screen wallpaper. The greeter runs as the sddm user and cannot read your home
# folder, so install.sh creates this folder once (sudo), owned by you and readable by all, and
# points the SDDM theme's background at SDDM_WALLPAPER; plasmonk keeps it in sync after that.
SDDM_SHARED_ROOT="/var/lib/plasmonk"
SDDM_SHARED_DIR="$SDDM_SHARED_ROOT/sddm"
SDDM_WALLPAPER="$SDDM_SHARED_DIR/wallpaper.jpg"

# Prints the folder of the SDDM theme in use, if SDDM is the display manager. SDDM reads
# /usr/lib/sddm/sddm.conf.d, then /etc/sddm.conf.d, then /etc/sddm.conf; the last value wins.
sddm_theme_dir() {
    case "$(readlink -f /etc/systemd/system/display-manager.service)" in
    */sddm.service) ;;
    *) return 1 ;;
    esac
    local f current
    current="$(for f in /usr/lib/sddm/sddm.conf.d/*.conf /etc/sddm.conf.d/*.conf /etc/sddm.conf; do
        if [ -f "$f" ]; then cat "$f"; fi
    done | awk -F= '/^\[/ { s = ($0 == "[Theme]") } s && $1 == "Current" { c = $2 } END { print c }')"
    [ -n "$current" ] && [ -f "/usr/share/sddm/themes/$current/theme.conf" ] || return 1
    grep -q '^background=' "/usr/share/sddm/themes/$current/theme.conf" || return 1
    printf '%s\n' "/usr/share/sddm/themes/$current"
}
