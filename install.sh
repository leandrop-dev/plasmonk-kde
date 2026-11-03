#!/usr/bin/env bash
# Plasmonk installer for Arch-based systems (Arch, CachyOS, EndeavourOS, ...) running KDE Plasma 6.
#
# 1. Checks the system and lists every package it will install, before changing anything.
# 2. Installs missing packages (pacman for official repos, paru or yay for the AUR).
# 3. Backs up the KDE settings it is about to change.
# 4. Installs Plasmonk into your home folder and applies a color preset.
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# shellcheck source=lib/common.sh
. "$REPO/lib/common.sh"

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

  --preset NAME      Color preset to apply on first install (default: blue; see presets.conf)
  --opaque-menus     Make Plasma popups and menus opaque (default: translucent)
  --skip-packages    Do not install packages; only install the theme
  --keep-shell       Do not offer to make zsh your login shell
  --panels           Replace your panels with the saved Plasmonk layout (themes/mystical/panels/layout.js).
                     This is the default on the first install; later runs keep your panels.
  --keep-panels      Keep your current panels, also on the first install
  -y, --yes          Do not ask for confirmation
  -h, --help         Show this help
EOF
}

PRESET="" OPAQUE=0 SKIP_PACKAGES=0 ASSUME_YES=0 KEEP_SHELL=0 PANELS=""
while [ $# -gt 0 ]; do
    case "$1" in
    --preset) PRESET="${2:?--preset needs a name}"; shift ;;
    --opaque-menus) OPAQUE=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    --keep-shell) KEEP_SHELL=1 ;;
    --panels) PANELS=1 ;;
    --keep-panels) PANELS=0 ;;
    -y | --yes) ASSUME_YES=1 ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; die "Unknown option: $1" ;;
    esac
    shift
done
# The saved panel layout is part of the look: apply it on the first install unless told not to.
if [ -z "$PANELS" ]; then
    if [ -f "$ORIGINAL_SETTINGS" ]; then PANELS=0; else PANELS=1; fi
fi

confirm() {
    [ "$ASSUME_YES" -eq 0 ] || return 0
    [ -t 0 ] || die "Not running interactively; re-run with --yes to proceed without prompts."
    local reply
    read -r -p "$1 [Y/n] " reply
    [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

# ---------- 1. checks ----------

refuse_root
have pacman || die "This installer supports Arch-based systems only (pacman not found)."
have plasmashell || die "KDE Plasma is not installed."
plasma_major="$(plasmashell --version | grep -oE '[0-9]+' | sed -n 1p)"
[ "${plasma_major:-0}" -ge 6 ] || die "Plasma 6 is required (found: $(plasmashell --version))."
[ "${XDG_CURRENT_DESKTOP:-}" = KDE ] || warn "You don't seem to be in a Plasma session; settings will apply on next login."

AUR_HELPER=""
for h in paru yay; do
    if have "$h"; then AUR_HELPER="$h"; break; fi
done

missing_repo=() missing_aur=()
if [ "$SKIP_PACKAGES" -eq 0 ]; then
    while IFS= read -r p; do pacman -Q "$p" >/dev/null 2>&1 || missing_repo+=("$p"); done < <(read_list "$REPO/deps/pacman.txt")
    while IFS= read -r p; do pacman -Q "$p" >/dev/null 2>&1 || missing_aur+=("$p"); done < <(read_list "$REPO/deps/aur.txt")
fi

echo
info "Plasmonk will:"
if [ ${#missing_repo[@]} -gt 0 ]; then
    echo "    - install from official repos (sudo pacman): ${missing_repo[*]}"
fi
if [ ${#missing_aur[@]} -gt 0 ]; then
    if [ -n "$AUR_HELPER" ]; then
        echo "    - install from the AUR ($AUR_HELPER): ${missing_aur[*]}"
    else
        echo "    - SKIP these AUR packages (no paru/yay found): ${missing_aur[*]}"
    fi
fi
[ ${#missing_repo[@]} -gt 0 ] || [ ${#missing_aur[@]} -gt 0 ] || echo "    - install no packages (all present or --skip-packages)"
echo "    - back up the KDE settings it changes to $PLASMONK_BACKUP_ROOT/"
echo "    - install the theme into $XDG_DATA_HOME and $XDG_CONFIG_HOME, and plasmonk into $PLASMONK_BIN_LINK"
echo "    - set the Bibata Modern Ice cursor, YAMIS icons, and Ghostty as the default terminal (Ctrl+Alt+T)"
echo "    - add one line to ~/.zshrc that loads the Plasmonk zsh setup (oh-my-zsh, starship, fastfetch)"
[ "$KEEP_SHELL" -eq 1 ] || echo "    - offer to make zsh your login shell"
[ "$PANELS" -eq 0 ] || echo "    - REPLACE all your panels with the saved Plasmonk layout (backed up first)"
echo "    - show your desktop wallpaper on the SDDM login screen (asks; sudo once)"
echo "    - enable a user service that follows wallpaper changes (login screen; colors after 'plasmonk apply --wallpaper')"
echo
confirm "Continue?" || die "Cancelled; nothing was changed."

# ---------- 2. packages ----------

# Remember which deps were already here, once, so uninstall --remove-packages leaves them.
if [ ! -f "$PREINSTALLED_PACKAGES" ]; then
    mkdir -p "$PLASMONK_STATE"
    while IFS= read -r p; do
        if pacman -Q "$p" >/dev/null 2>&1; then echo "$p"; fi
    done < <(read_list "$REPO/deps/pacman.txt"; read_list "$REPO/deps/aur.txt") >"$PREINSTALLED_PACKAGES"
fi

if [ ${#missing_repo[@]} -gt 0 ]; then
    info "Installing official packages"
    sudo pacman -S --needed "${missing_repo[@]}"
fi
if [ ${#missing_aur[@]} -gt 0 ] && [ -n "$AUR_HELPER" ]; then
    info "Installing AUR packages with $AUR_HELPER"
    "$AUR_HELPER" -S --needed "${missing_aur[@]}"
fi
have matugen || die "matugen is still missing; it is required to generate colors."

# ---------- 2b. login screen wallpaper (sudo, once) ----------

# SDDM's greeter cannot read your home folder. Give it a folder you own that it can read, and
# point its theme's background there; plasmonk copies your wallpaper into it on every change.
if sddm_dir="$(sddm_theme_dir)"; then
    sddm_conf="$sddm_dir/theme.conf.user"
    # The greeter runs as the sddm user, so the file must be readable by all. A file you cannot
    # read here is one the greeter cannot read either: it needs fixing too.
    current_bg=""
    if [ -r "$sddm_conf" ]; then
        current_bg="$(kreadconfig6 --file "$sddm_conf" --group General --key background)"
    fi
    if [ "$current_bg" != "$SDDM_WALLPAPER" ] || [ ! -w "$SDDM_SHARED_DIR" ]; then
        if [ "$ASSUME_YES" -eq 1 ] && ! [ -t 0 ] && ! sudo -n true >/dev/null 2>&1; then
            warn "Skipping the login screen wallpaper (needs sudo); run ./install.sh in a terminal to set it up"
        elif confirm "Show your desktop wallpaper on the SDDM login screen? (sudo, once)"; then
            if [ -z "$(state_get sddm_conf)" ]; then
                if [ -e "$sddm_conf" ] && [ ! -r "$sddm_conf" ]; then
                    current_bg="$(sudo kreadconfig6 --file "$sddm_conf" --group General --key background)"
                fi
                state_set sddm_conf "$sddm_conf"
                state_set sddm_original_background "${current_bg:-$UNSET_MARK}"
            fi
            sudo install -d -m 755 "$SDDM_SHARED_ROOT"
            sudo install -d -m 755 -o "$(id -un)" -g "$(id -gn)" "$SDDM_SHARED_DIR"
            sudo kwriteconfig6 --file "$sddm_conf" --group General --key background "$SDDM_WALLPAPER"
            sudo chmod 644 -- "$sddm_conf"   # KConfig creates new files as 0600
            ok "SDDM ($sddm_dir) now shows the wallpaper from $SDDM_WALLPAPER"
        fi
    fi
fi

# ---------- 3. backups ----------

backup_dir="$PLASMONK_BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"
for f in kdeglobals kwinrc plasmarc kcminputrc konsolerc Kvantum/kvantum.kvconfig rofi/config.rasi \
    "${REPLACED_FILES[@]}" ghostty/config ghostty/config.ghostty; do
    if [ -f "$XDG_CONFIG_HOME/$f" ]; then
        mkdir -p "$backup_dir/$(dirname "$f")"
        cp -p "$XDG_CONFIG_HOME/$f" "$backup_dir/$f"
    fi
done
[ ! -f "$ZSHRC" ] || cp -p "$ZSHRC" "$backup_dir/zshrc"
ok "Backed up current settings to $backup_dir"

# Record each setting's original value once. Keys already recorded are skipped, so a reinstall
# never records Plasmonk's own values, while keys added in newer versions still get recorded.
first_install=0
[ -f "$ORIGINAL_SETTINGS" ] || first_install=1
recorded=0
for entry in "${MANAGED_KEYS[@]}"; do
    IFS='|' read -r file group key <<<"$entry"
    if [ "$first_install" -eq 0 ] && grep -qF "$file"$'\t'"$group"$'\t'"$key"$'\t' "$ORIGINAL_SETTINGS"; then
        continue
    fi
    value="$(kconfig kreadconfig6 "$file" "$group" --key "$key" --default "$UNSET_MARK")"
    value="${value//$'\n'/\\n}"   # one line per entry; uninstall.sh reverses this
    printf '%s\t%s\t%s\t%s\n' "$file" "$group" "$key" "$value" >>"$ORIGINAL_SETTINGS"
    recorded=$((recorded + 1))
done
# Remember whether rofi had a config before us, so uninstall restores or removes it.
if [ "$first_install" -eq 1 ] && [ -f "$XDG_CONFIG_HOME/rofi/config.rasi" ]; then
    cp -p "$XDG_CONFIG_HOME/rofi/config.rasi" "$PLASMONK_STATE/original-rofi-config.rasi"
fi
for f in "${REPLACED_FILES[@]}"; do
    if [ ! -e "$ORIGINALS_DIR/$f" ] && [ ! -e "$ORIGINALS_DIR/$f.none" ]; then
        mkdir -p "$(dirname "$ORIGINALS_DIR/$f")"
        if [ -f "$XDG_CONFIG_HOME/$f" ]; then
            cp -p "$XDG_CONFIG_HOME/$f" "$ORIGINALS_DIR/$f"
        else
            : >"$ORIGINALS_DIR/$f.none"
        fi
    fi
done
# The login shell, recorded once so uninstall.sh can offer to switch back.
[ -n "$(state_get original_shell)" ] || state_set original_shell "$(getent passwd "$(id -un)" | cut -d: -f7)"
[ "$recorded" -eq 0 ] || ok "Recorded $recorded original KDE setting(s) in $ORIGINAL_SETTINGS"

# ---------- 4. install ----------

info "Installing Plasmonk files to $PLASMONK_SHARE"
rm -rf "$PLASMONK_SHARE"
mkdir -p "$PLASMONK_SHARE" "$(dirname "$PLASMONK_BIN_LINK")"
cp -r "$REPO/bin" "$REPO/lib" "$REPO/themes" "$REPO/deps" "$REPO/presets.conf" "$PLASMONK_SHARE/"
ln -sfn "$PLASMONK_SHARE/bin/plasmonk" "$PLASMONK_BIN_LINK"
case ":$PATH:" in
*":$(dirname "$PLASMONK_BIN_LINK"):"*) ;;
*) warn "$(dirname "$PLASMONK_BIN_LINK") is not in your PATH; run plasmonk as $PLASMONK_BIN_LINK" ;;
esac

[ "$OPAQUE" -eq 0 ] || state_set menus 1.00
"$PLASMONK_BIN_LINK" setup

info "Enabling the wallpaper watcher"
mkdir -p "$SYSTEMD_USER_DIR"
cp "$REPO"/systemd/plasmonk-wallpaper.{path,service} "$SYSTEMD_USER_DIR/"
systemctl --user daemon-reload
systemctl --user enable --now plasmonk-wallpaper.path >/dev/null

if [ -n "$PRESET" ]; then
    "$PLASMONK_BIN_LINK" apply --preset "$PRESET"
else
    "$PLASMONK_BIN_LINK" apply   # last palette on reinstall, blue on first install
fi

if [ "$PANELS" -eq 1 ]; then
    "$PLASMONK_BIN_LINK" panels restore "$PLASMONK_SHARE/themes/mystical/panels/layout.js" --yes
fi

# ---------- 5. login shell ----------

zsh_path="$(command -v zsh || true)"
login_shell="$(getent passwd "$(id -un)" | cut -d: -f7)"
if [ "$KEEP_SHELL" -eq 0 ] && [ -n "$zsh_path" ] && [ "$login_shell" != "$zsh_path" ]; then
    echo
    if [ ! -t 0 ]; then
        warn "Not interactive; to make zsh your login shell run: chsh -s $zsh_path"
    elif confirm "Make zsh your login shell? (chsh asks for your password)"; then
        chsh -s "$zsh_path" || warn "chsh failed; run it yourself: chsh -s $zsh_path"
    fi
fi

echo
ok "Plasmonk is installed."
cat <<EOF

Next steps (manual, per upstream README):
  - Log out and back in so every app picks up the Kvantum style and font, the new cursor,
    and your login shell.
  - Terminal: Ctrl+Alt+T opens Ghostty. Your own zsh settings go in ~/.config/zsh/user.zsh,
    Ghostty overrides in ~/.config/ghostty/user.conf.
  - Launcher: Meta+Space opens Rofi.
  - Blur: Better Blur DX is enabled for the apps in themes/mystical/better-blur-classes.txt.
    Add more in System Settings > Window Management > Desktop Effects > Better Blur DX.
  - Panels: the saved layout (top bar + bottom dock) is applied on the first install;
    save your own with 'plasmonk panels save' and bring it back with 'plasmonk panels restore'.

Try:  plasmonk apply --preset red  |  plasmonk apply --wallpaper  |  plasmonk wallpaper-colors  |  plasmonk doctor
EOF
