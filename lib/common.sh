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

COLOR_SCHEME_DIR="$XDG_DATA_HOME/color-schemes"
PLASMA_THEME_DIR="$XDG_DATA_HOME/plasma/desktoptheme/$PLASMONK_NAME"
AURORAE_DIR="$XDG_DATA_HOME/aurorae/themes/$PLASMONK_NAME"
KVANTUM_DIR="$XDG_CONFIG_HOME/Kvantum/$PLASMONK_NAME"
ROFI_DIR="$XDG_CONFIG_HOME/rofi"
SYSTEMD_USER_DIR="$XDG_CONFIG_HOME/systemd/user"
APPLETSRC="$XDG_CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc"

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
    "kdeglobals|Icons|Theme"
    "kwinrc|org.kde.kdecoration2|library"
    "kwinrc|org.kde.kdecoration2|theme"
    "plasmarc|Theme|name"
    "$XDG_CONFIG_HOME/Kvantum/kvantum.kvconfig|General|theme"
)

# Lists non-comment, non-empty lines of a package list file.
read_list() {
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}
