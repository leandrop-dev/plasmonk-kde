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

# ---------- login shell ----------

# Offered first: --remove-packages must not remove the shell you log in with.
original_shell="$(state_get original_shell)"
login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
if [ -n "$original_shell" ] && [ "$login_shell" != "$original_shell" ] && [ "$(basename "$login_shell")" = zsh ]; then
    if [ ! -t 0 ]; then
        warn "Your login shell is still zsh; to switch back run: chsh -s $original_shell"
    else
        read -r -p "Switch your login shell back to $original_shell? (chsh asks for your password) [Y/n] " reply
        if [[ -z "$reply" || "$reply" =~ ^[Yy] ]]; then
            chsh -s "$original_shell" || warn "chsh failed; run it yourself: chsh -s $original_shell"
        fi
    fi
fi

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
        value="${value//\\n/$'\n'}"   # install.sh stored newlines as \n
        if [ "$value" = "$UNSET_MARK" ]; then
            kconfig kwriteconfig6 "$file" "$group" --key "$key" --delete
        else
            kconfig kwriteconfig6 "$file" "$group" --key "$key" "$value"
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
    "$PLASMA_CHANGEICONS" "$icons" >/dev/null 2>&1 || true
    cursor="$(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme --default breeze_cursors)"
    plasma-apply-cursortheme "$cursor" >/dev/null 2>&1 || warn "Could not re-apply cursor theme $cursor"
    qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
    # Swap blur effects back live: Better Blur DX off unless it was on before, stock Blur back on
    # unless it was off before (KWin's default for blur is on).
    if [ "$(kreadconfig6 --file kwinrc --group Plugins --key better_blur_dxEnabled --default false)" != true ]; then
        qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect better_blur_dx >/dev/null 2>&1 || true
    fi
    if [ "$(kreadconfig6 --file kwinrc --group Plugins --key blurEnabled --default true)" = true ]; then
        qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect blur >/dev/null 2>&1 || true
    fi
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

# Starship and fastfetch configs: put back yours, or remove ours if you had none.
for f in "${REPLACED_FILES[@]}"; do
    if [ -f "$ORIGINALS_DIR/$f" ]; then
        cp -p "$ORIGINALS_DIR/$f" "$XDG_CONFIG_HOME/$f"
        ok "Restored your previous $XDG_CONFIG_HOME/$f"
    elif [ -e "$ORIGINALS_DIR/$f.none" ]; then
        safe_remove "$XDG_CONFIG_HOME/$f"
    fi
done
rmdir "$FASTFETCH_DIR" >/dev/null 2>&1 || true

# Terminal and shell. Ghostty's config is yours to edit, so it is only removed if untouched.
safe_remove "$GHOSTTY_DIR/plasmonk-colors"
if [ -f "$GHOSTTY_DIR/config" ] && [ -f "$PLASMONK_SHARE/themes/mystical/terminal/ghostty.config" ] &&
    cmp -s "$GHOSTTY_DIR/config" "$PLASMONK_SHARE/themes/mystical/terminal/ghostty.config"; then
    safe_remove "$GHOSTTY_DIR/config"
    rmdir "$GHOSTTY_DIR" >/dev/null 2>&1 || true
elif [ -f "$GHOSTTY_DIR/config" ]; then
    warn "Kept $GHOSTTY_DIR/config (you modified it); remove its 'config-file = plasmonk-colors' line"
fi
safe_remove "$KONSOLE_DATA_DIR/$PLASMONK_NAME.profile"
safe_remove "$KONSOLE_DATA_DIR/$PLASMONK_NAME.colorscheme"
safe_remove "$ZSH_CFG_DIR/plasmonk.zsh"
safe_remove "$ZSH_CFG_DIR/plasmonk-colors.zsh"
rmdir "$ZSH_CFG_DIR" >/dev/null 2>&1 || true   # kept if it holds your user.zsh
if [ -f "$ZSHRC" ] && grep -qxF "$ZSHRC_LINE" "$ZSHRC"; then
    grep -vxF "$ZSHRC_LINE" "$ZSHRC" >"$ZSHRC.plasmonk-tmp" || true
    if [ -s "$ZSHRC.plasmonk-tmp" ]; then
        cat "$ZSHRC.plasmonk-tmp" >"$ZSHRC"   # keeps the file's permissions
        ok "Removed the Plasmonk line from $ZSHRC"
    else
        safe_remove "$ZSHRC"   # it only held our line
    fi
    rm -f -- "$ZSHRC.plasmonk-tmp"
fi

# SDDM: put the theme's background setting back and remove the shared wallpaper folder (sudo).
sddm_conf="$(state_get sddm_conf)"
if [ -n "$sddm_conf" ] || [ -d "$SDDM_SHARED_ROOT" ]; then
    sddm_bg="$(state_get sddm_original_background)"
    if [ ! -t 0 ] && ! sudo -n true >/dev/null 2>&1; then
        warn "Login screen wallpaper left as is (needs sudo). To undo it: sudo rm -r $SDDM_SHARED_ROOT" \
            "and remove background= from ${sddm_conf:-theme.conf.user in the SDDM theme folder}"
    else
        info "Restoring the SDDM login screen background (sudo)"
        if [ -n "$sddm_conf" ] && [ -f "$sddm_conf" ]; then
            if [ -z "$sddm_bg" ] || [ "$sddm_bg" = "$UNSET_MARK" ]; then
                sudo kwriteconfig6 --file "$sddm_conf" --group General --key background --delete
                # theme.conf.user did not exist before Plasmonk: remove it if nothing else is in it.
                if ! sudo grep -q '=' "$sddm_conf"; then sudo rm -f -- "$sddm_conf"; fi
            else
                sudo kwriteconfig6 --file "$sddm_conf" --group General --key background "$sddm_bg"
            fi
        fi
        sudo rm -rf -- "$SDDM_SHARED_ROOT"
        ok "SDDM background restored"
    fi
fi

# Apps: Vesktop theme off, Zed back to your theme, Zen/Thunderbird chrome files restored.
vesktop_settings="$VESKTOP_DIR/settings/settings.json"
vesktop_transparent="$(state_get vesktop_original_transparent)"
if [ -f "$vesktop_settings" ] && { [ -n "$vesktop_transparent" ] ||
    jq -e --arg t "$VESKTOP_THEME" '(.enabledThemes // []) | index($t)' "$vesktop_settings" >/dev/null; }; then
    printf '%s' "$(jq --indent 4 --arg t "$VESKTOP_THEME" --argjson tr "${vesktop_transparent:-null}" \
        '.enabledThemes -= [$t] | if $tr == null then . else .transparent = $tr end' "$vesktop_settings")" >"$vesktop_settings.plasmonk-tmp"
    cat "$vesktop_settings.plasmonk-tmp" >"$vesktop_settings"
    rm -f -- "$vesktop_settings.plasmonk-tmp"
fi
safe_remove "$VESKTOP_DIR/themes/$VESKTOP_THEME"
zed_original="$(state_get zed_original_theme)"
if [ -n "$zed_original" ] && [ -f "$ZED_DIR/settings.json" ] && [ "$(zed_dark_theme "$ZED_DIR/settings.json")" = "$ZED_THEME" ]; then
    zed_set_dark_theme "$ZED_DIR/settings.json" "$zed_original"
    ok "Zed theme set back to $zed_original"
fi
safe_remove "$ZED_DIR/themes/plasmonk.json"
for app_dir in "$ZEN_DIR" "$THUNDERBIRD_DIR"; do
    if profile="$(mozilla_profile "$app_dir")"; then safe_remove "$profile/chrome/plasmonk.css"; fi
done
# Every file plasmonk replaced in place (userChrome.css, user.js, ...): put yours back.
if [ -d "$ORIGINALS_DIR/home" ]; then
    while IFS= read -r -d '' kept; do
        rel="${kept#"$ORIGINALS_DIR/home/"}"
        case "$rel" in
        *.none) safe_remove "$HOME/${rel%.none}" ;;
        *) cp -p "$kept" "$HOME/$rel" && ok "Restored $HOME/$rel" ;;
        esac
    done < <(find "$ORIGINALS_DIR/home" -type f -print0)
fi

# Launcher and shortcut overrides (only the .desktop files plasmonk wrote).
safe_remove "$APPS_DIR/plasmonk-rofi.desktop"
for f in "$APPS_DIR"/*.desktop; do
    if [ -f "$f" ] && grep -qxF "$DESKTOP_MARKER" "$f"; then safe_remove "$f"; fi
done
kbuildsycoca6 >/dev/null 2>&1 || true
# Hand Ctrl+Alt+T back to Konsole in the running session too, when it had its default before.
if [ -z "$(kconfig kreadconfig6 kglobalshortcutsrc "services][org.kde.konsole.desktop" --key _launch)" ]; then
    set_live_shortcut com.mitchellh.ghostty.desktop _launch Ghostty "[]" || true
    set_live_shortcut org.kde.konsole.desktop _launch Konsole "[([201326676],)]" ||
        warn "Could not update shortcuts in the running session; Ctrl+Alt+T returns to Konsole after next login"
fi

safe_remove "$PLASMONK_BIN_LINK"
safe_remove "$PLASMONK_SHARE"
safe_remove "$ORIGINALS_DIR"
for f in state state.tmp matugen.toml "$PLASMONK_NAME.colors" palette.env original-settings.tsv original-rofi-config.rasi; do
    safe_remove "$PLASMONK_STATE/$f"
done

# ---------- packages ----------

if [ "$REMOVE_PACKAGES" -eq 1 ]; then
    pkgs=() kept=()
    login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
    while IFS= read -r p; do
        pacman -Q "$p" >/dev/null 2>&1 || continue
        if { [ -f "$PREINSTALLED_PACKAGES" ] && grep -qxF "$p" "$PREINSTALLED_PACKAGES"; } ||
            { [ "$p" = zsh ] && [ "$(basename "$login_shell")" = zsh ]; }; then
            kept+=("$p")
        else
            pkgs+=("$p")
        fi
    done < <(read_list "$REPO/deps/pacman.txt"; read_list "$REPO/deps/aur.txt")
    [ ${#kept[@]} -eq 0 ] || info "Keeping packages you had before Plasmonk (or your login shell): ${kept[*]}"
    if [ ${#pkgs[@]} -gt 0 ]; then
        info "Removing packages: ${pkgs[*]}"
        sudo pacman -Rns "${pkgs[@]}"
    fi
fi
safe_remove "$PREINSTALLED_PACKAGES"

ok "Plasmonk removed. Backups are kept in $PLASMONK_BACKUP_ROOT"
echo "Log out and back in so every app drops the Kvantum style."
