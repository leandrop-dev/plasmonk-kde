#!/usr/bin/env bash
# Plasmonk uninstaller. Restores the KDE settings recorded at install time, removes only the
# files Plasmonk installed (all under $HOME), and leaves packages alone unless asked.
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# shellcheck source=lib/common.sh
. "$REPO/lib/common.sh"

usage() {
    cat <<'EOF'
Usage: ./uninstall.sh [options]

  --remove-packages  Also uninstall the packages listed in deps/ (asks pacman to confirm)
  -y, --yes          Do not ask for confirmation
  -h, --help         Show this help

Backups in ~/.local/state/plasmonk/backup are kept.
EOF
}

REMOVE_PACKAGES=0 ASSUME_YES=0
while [ $# -gt 0 ]; do
    case "$1" in
    --remove-packages) REMOVE_PACKAGES=1 ;;
    -y | --yes) ASSUME_YES=1 ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; die "Unknown option: $1" ;;
    esac
    shift
done

refuse_root

if [ "$ASSUME_YES" -eq 0 ]; then
    [ -t 0 ] || die "Not running interactively; re-run with --yes."
    read -r -p "Remove Plasmonk and restore your previous KDE settings? [y/N] " reply
    [[ "$reply" =~ ^[Yy] ]] || die "Cancelled; nothing was changed."
fi

# Only ever deletes one exact path inside $HOME (rule from upstream PR #27).
safe_remove() {
    case "$1" in
    "$HOME"/?*) ;;
    *) warn "Refusing to remove a path outside HOME: $1"; return 1 ;;
    esac
    if [ -e "$1" ] || [ -L "$1" ]; then
        rm -rf -- "$1"
        ok "Removed $1"
    fi
}

# ---------- restore settings ----------

if systemctl --user is-enabled plasmonk-wallpaper.path >/dev/null 2>&1; then
    systemctl --user disable --now plasmonk-wallpaper.path >/dev/null
fi
safe_remove "$SYSTEMD_USER_DIR/plasmonk-wallpaper.path"
safe_remove "$SYSTEMD_USER_DIR/plasmonk-wallpaper.service"
systemctl --user daemon-reload

if [ -f "$ORIGINAL_SETTINGS" ]; then
    info "Restoring your original KDE settings"
    orig_scheme="BreezeDark" orig_plasma="breeze-dark"
    while IFS=$'\t' read -r file group key value; do
        if [ "$value" = "$UNSET_MARK" ]; then
            kwriteconfig6 --file "$file" --group "$group" --key "$key" --delete
        else
            kwriteconfig6 --file "$file" --group "$group" --key "$key" "$value"
        fi
        case "$file|$group|$key" in
        "kdeglobals|General|ColorScheme") [ "$value" = "$UNSET_MARK" ] || orig_scheme="$value" ;;
        "plasmarc|Theme|name") [ "$value" = "$UNSET_MARK" ] || orig_plasma="$value" ;;
        esac
    done <"$ORIGINAL_SETTINGS"
    # Apply live; kdeglobals now names the original scheme, so switch through another first.
    plasma-apply-colorscheme BreezeClassic >/dev/null 2>&1 || true
    plasma-apply-colorscheme "$orig_scheme" >/dev/null 2>&1 || warn "Could not re-apply color scheme $orig_scheme"
    plasma-apply-desktoptheme "$orig_plasma" >/dev/null 2>&1 || warn "Could not re-apply Plasma style $orig_plasma"
    icons="$(kreadconfig6 --file kdeglobals --group Icons --key Theme --default breeze-dark)"
    /usr/lib/plasma-changeicons "$icons" >/dev/null 2>&1 || true
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
else
    warn "No record of original settings ($ORIGINAL_SETTINGS); switch theme manually in System Settings."
fi

# Rofi: put back the user's own config if they had one, else remove ours if unmodified.
if [ -f "$PLASMONK_STATE/original-rofi-config.rasi" ]; then
    cp -p "$PLASMONK_STATE/original-rofi-config.rasi" "$ROFI_DIR/config.rasi"
    ok "Restored your previous rofi config"
elif [ -f "$ROFI_DIR/config.rasi" ] && [ -f "$PLASMONK_SHARE/themes/mystical/rofi/config.rasi" ] &&
    cmp -s "$ROFI_DIR/config.rasi" "$PLASMONK_SHARE/themes/mystical/rofi/config.rasi"; then
    safe_remove "$ROFI_DIR/config.rasi"
else
    [ ! -f "$ROFI_DIR/config.rasi" ] || warn "Kept $ROFI_DIR/config.rasi (you modified it)"
fi

# ---------- remove files ----------

safe_remove "$PLASMA_THEME_DIR"
safe_remove "$AURORAE_DIR"
safe_remove "$KVANTUM_DIR"
safe_remove "$COLOR_SCHEME_DIR/${PLASMONK_NAME}A.colors"
safe_remove "$COLOR_SCHEME_DIR/${PLASMONK_NAME}B.colors"
safe_remove "$ROFI_DIR/plasmonk-colors.rasi"
safe_remove "$PLASMONK_BIN_LINK"
safe_remove "$PLASMONK_SHARE"
for f in state state.tmp matugen.toml "$PLASMONK_NAME.colors" original-settings.tsv original-rofi-config.rasi; do
    safe_remove "$PLASMONK_STATE/$f"
done

# ---------- packages ----------

if [ "$REMOVE_PACKAGES" -eq 1 ]; then
    pkgs=()
    while IFS= read -r p; do
        if pacman -Q "$p" >/dev/null 2>&1; then pkgs+=("$p"); fi
    done < <(read_list "$REPO/deps/pacman.txt"; read_list "$REPO/deps/aur.txt")
    if [ ${#pkgs[@]} -gt 0 ]; then
        info "Removing packages: ${pkgs[*]}"
        sudo pacman -Rns "${pkgs[@]}"
    fi
fi

ok "Plasmonk removed. Backups are kept in $PLASMONK_BACKUP_ROOT"
echo "Log out and back in so every app drops the Kvantum style."
