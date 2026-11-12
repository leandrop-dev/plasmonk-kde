#!/usr/bin/env bash
# Plasmonk installer for Arch-based systems (Arch, CachyOS, EndeavourOS, ...) and Fedora,
# running KDE Plasma 6.
#
# 1. Checks the system and lists every package it will install, before changing anything.
# 2. Installs missing packages (pacman + paru/yay on Arch; dnf + COPR on Fedora).
# 3. Backs up the KDE settings it is about to change.
# 4. Installs Plasmonk into your home folder and applies a color preset.
set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
# shellcheck source=lib/common.sh
. "$REPO/lib/common.sh"

# A set -e abort otherwise exits silently; say which line and command failed.
trap 'printf "%s[x]%s install failed at line %s: %s\n" "$_c_err" "$_c_off" "$LINENO" "$BASH_COMMAND" >&2' ERR

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

# Fedora-only sources: COPR packages, plus the pieces Fedora does not package
# (oh-my-zsh, zsh-history-substring-search, YAMIS icons, JetBrains Mono Nerd Font).
install_fedora_extras() {
    local entry project pkgs tmp enabled_coprs

    # Packages from COPRs. A COPR already enabled is left alone (not recorded), so uninstall
    # never removes a repository the user had before Plasmonk.
    enabled_coprs="$(dnf copr list 2>/dev/null || true)"
    for entry in "${missing_copr[@]}"; do
        project="${entry%%:*}" pkgs="${entry#*:}"
        if ! grep -qE "/$project$" <<<"$enabled_coprs"; then
            info "Enabling COPR $project"
            sudo dnf copr enable -y "$project" >/dev/null
            state_add coprs "$project"
        fi
        info "Installing from COPR $project: $pkgs"
        # shellcheck disable=SC2086  # $pkgs is a deliberate word list
        sudo dnf install -y $pkgs
    done

    # oh-my-zsh: the official installer puts it in ~/.oh-my-zsh (Fedora has no package).
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        info "Installing oh-my-zsh into ~/.oh-my-zsh"
        tmp="$(mktemp)"
        if download https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh "$tmp"; then
            if RUNZSH=no CHSH=no sh "$tmp" --unattended --keep-zshrc; then
                state_add fedora_assets oh-my-zsh
            else
                warn "oh-my-zsh installer failed"
            fi
        else
            warn "Could not download the oh-my-zsh installer"
        fi
        rm -f -- "$tmp"
    fi

    # zsh-history-substring-search: Fedora does not package it; clone it for plasmonk.zsh.
    local hs="$XDG_CONFIG_HOME/zsh/plugins/zsh-history-substring-search"
    if [ ! -d "$hs" ]; then
        info "Cloning zsh-history-substring-search"
        mkdir -p "$(dirname "$hs")"
        if git clone --depth 1 https://github.com/zsh-users/zsh-history-substring-search "$hs"; then
            state_add fedora_assets history-substring-search
        else
            warn "Could not clone zsh-history-substring-search"
        fi
    fi

    # YAMIS icons: an asset theme, copied into the user icon folder.
    local yamis="$XDG_DATA_HOME/icons/yet-another-monochrome-icon-set"
    if [ ! -d "$yamis" ]; then
        info "Installing YAMIS icons"
        mkdir -p "$XDG_DATA_HOME/icons"
        tmp="$(mktemp -d)"
        if git clone --depth 1 https://bitbucket.org/dirn-typo/yet-another-monochrome-icon-set "$tmp/yamis"; then
            rm -rf -- "$yamis"
            mv "$tmp/yamis" "$yamis"
            state_add fedora_assets yamis
        else
            warn "Could not clone the YAMIS icon theme"
        fi
        rm -rf -- "$tmp"
    fi

    install_nerd_font
}

# JetBrains Mono Nerd Font: Fedora has no package, so take the official Nerd Fonts release.
install_nerd_font() {
    if fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd Font'; then return 0; fi
    local dir="$XDG_DATA_HOME/fonts/JetBrainsMonoNerdFont" tmp
    info "Installing JetBrains Mono Nerd Font into $dir"
    mkdir -p "$dir"
    tmp="$(mktemp -d)"
    if download https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip "$tmp/jb.zip"; then
        if have unzip && unzip -o -q "$tmp/jb.zip" -d "$dir"; then
            fc-cache -f "$dir" >/dev/null 2>&1 || true
            state_add fedora_assets nerd-font
        else
            warn "Could not unzip the Nerd Font; install it from https://www.nerdfonts.com/font-downloads"
        fi
    else
        warn "Could not download the Nerd Font; install it from https://www.nerdfonts.com/font-downloads"
    fi
    rm -rf -- "$tmp"
}

# ---------- 1. checks ----------

refuse_root
have plasmashell || die "KDE Plasma is not installed."
plasma_major="$(plasmashell --version | grep -oE '[0-9]+' | sed -n 1p)"
[ "${plasma_major:-0}" -ge 6 ] || die "Plasma 6 is required (found: $(plasmashell --version))."
[ "${XDG_CURRENT_DESKTOP:-}" = KDE ] || warn "You don't seem to be in a Plasma session; settings will apply on next login."

case "$DISTRO" in
arch) have pacman || die "pacman was not found." ;;
fedora) have dnf || die "dnf was not found." ;;
*) die "Unsupported distribution: neither pacman nor dnf was found. This installer supports Arch-based and Fedora systems." ;;
esac

# The login-screen wallpaper step is SDDM-only. Detect it once for both the plan and step 2b;
# on Fedora 45+ KDE the display manager is plasmalogin, so this is empty there.
sddm_dir="$(sddm_theme_dir || true)"

AUR_HELPER=""
if [ "$DISTRO" = arch ]; then
    for h in paru yay; do
        if have "$h"; then AUR_HELPER="$h"; break; fi
    done
fi

missing_repo=() missing_aur=() missing_copr=()
if [ "$SKIP_PACKAGES" -eq 0 ]; then
    case "$DISTRO" in
    arch)
        while IFS= read -r p; do pkg_installed "$p" || missing_repo+=("$p"); done < <(read_list "$REPO/deps/pacman.txt")
        while IFS= read -r p; do pkg_installed "$p" || missing_aur+=("$p"); done < <(read_list "$REPO/deps/aur.txt")
        ;;
    fedora)
        while IFS= read -r p; do pkg_installed "$p" || missing_repo+=("$p"); done < <(read_list "$REPO/deps/fedora.txt")
        while IFS= read -r line; do
            [ -n "$line" ] || continue
            project="${line%% *}"
            pkgs="${line#* }"
            need=0
            for p in $pkgs; do pkg_installed "$p" || need=1; done
            [ "$need" -eq 0 ] || missing_copr+=("$project:$pkgs")
        done < <(read_list "$REPO/deps/fedora-copr.txt")
        ;;
    esac
fi

echo
info "Plasmonk will:"
if [ ${#missing_repo[@]} -gt 0 ]; then
    case "$DISTRO" in
    arch) echo "    - install from official repos (sudo pacman): ${missing_repo[*]}" ;;
    fedora) echo "    - install from official repos (sudo dnf): ${missing_repo[*]}" ;;
    esac
fi
if [ "$DISTRO" = arch ] && [ ${#missing_aur[@]} -gt 0 ]; then
    if [ -n "$AUR_HELPER" ]; then
        echo "    - install from the AUR ($AUR_HELPER): ${missing_aur[*]}"
    else
        echo "    - SKIP these AUR packages (no paru/yay found): ${missing_aur[*]}"
    fi
fi
if [ "$DISTRO" = fedora ] && [ "$SKIP_PACKAGES" -eq 0 ]; then
    for entry in "${missing_copr[@]}"; do
        echo "    - enable COPR ${entry%%:*} and install: ${entry#*:}"
    done
    echo "    - install oh-my-zsh, zsh-history-substring-search, YAMIS icons and the JetBrains Mono Nerd Font (GitHub releases)"
fi
any_pkg=0
if [ ${#missing_repo[@]} -gt 0 ]; then any_pkg=1; fi
if [ "$DISTRO" = arch ] && [ ${#missing_aur[@]} -gt 0 ]; then any_pkg=1; fi
if [ "$DISTRO" = fedora ] && [ ${#missing_copr[@]} -gt 0 ]; then any_pkg=1; fi
[ "$any_pkg" -eq 1 ] || echo "    - install no packages (all present or --skip-packages)"
echo "    - back up the KDE settings it changes to $PLASMONK_BACKUP_ROOT/"
echo "    - install the theme into $XDG_DATA_HOME and $XDG_CONFIG_HOME, and plasmonk into $PLASMONK_BIN_LINK"
echo "    - set the Bibata Modern Ice cursor, YAMIS icons, and Ghostty as the default terminal (Ctrl+Alt+T)"
echo "    - let GTK apps (Ghostty) compose dead keys (´ \` ~ ^) with GTK's simple input method"
echo "    - add one line to ~/.zshrc that loads the Plasmonk zsh setup (oh-my-zsh, starship, fastfetch)"
[ "$KEEP_SHELL" -eq 1 ] || echo "    - offer to make zsh your login shell"
[ "$PANELS" -eq 0 ] || echo "    - REPLACE all your panels with the saved Plasmonk layout (backed up first)"
if [ -n "$sddm_dir" ]; then
    echo "    - show your desktop wallpaper on the SDDM login screen (asks; sudo once)"
else
    dm_name="$(login_manager || true)"
    echo "    - skip the login-screen wallpaper (SDDM is not in use${dm_name:+; this system uses $dm_name})"
fi
echo "    - enable a user service that follows wallpaper changes ('plasmonk apply --wallpaper' colors, and the SDDM wallpaper when used)"
echo
confirm "Continue?" || die "Cancelled; nothing was changed."

# ---------- 2. packages ----------

# Remember which deps were already here, once, so uninstall --remove-packages leaves them.
if [ ! -f "$PREINSTALLED_PACKAGES" ]; then
    mkdir -p "$PLASMONK_STATE"
    while IFS= read -r p; do
        if pkg_installed "$p"; then echo "$p"; fi
    done < <(distro_package_names "$REPO") >"$PREINSTALLED_PACKAGES"
fi

if [ ${#missing_repo[@]} -gt 0 ]; then
    info "Installing official packages"
    pkg_install "${missing_repo[@]}"
fi
if [ "$DISTRO" = arch ] && [ ${#missing_aur[@]} -gt 0 ] && [ -n "$AUR_HELPER" ]; then
    info "Installing AUR packages with $AUR_HELPER"
    "$AUR_HELPER" -S --needed "${missing_aur[@]}"
fi
if [ "$DISTRO" = fedora ] && [ "$SKIP_PACKAGES" -eq 0 ]; then
    install_fedora_extras
fi
have matugen || die "matugen is still missing; it is required to generate colors."

# ---------- 2b. login screen wallpaper (sudo, once) ----------

# SDDM's greeter cannot read your home folder. Give it a folder you own that it can read, and
# point its theme's background there; plasmonk copies your wallpaper into it on every change.
if [ -n "$sddm_dir" ]; then
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
    "$PLASMONK_BIN_LINK" panels restore "$PLASMONK_SHARE/themes/mystical/panels/layout.js" --yes ||
        warn "Could not apply the saved panel layout; run 'plasmonk panels restore' yourself"
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
if [ -f /usr/lib64/qt6/plugins/kwin/effects/plugins/better_blur_dx.so ] ||
    [ -f /usr/lib/qt6/plugins/kwin/effects/plugins/better_blur_dx.so ]; then
    blur_hint="  - Blur: Better Blur DX is enabled for the apps in themes/mystical/better-blur-classes.txt.
    Add more in System Settings > Window Management > Desktop Effects > Better Blur DX."
else
    blur_hint="  - Blur: KWin's stock Blur is in use (Better Blur DX is not installed). Tune it in
    System Settings > Window Management > Desktop Effects > Blur."
fi
cat <<EOF

Next steps (manual, per upstream README):
  - Log out and back in so every app picks up the Kvantum style and font, the new cursor,
    and your login shell.
  - Terminal: Ctrl+Alt+T opens Ghostty. Your own zsh settings go in ~/.config/zsh/user.zsh,
    Ghostty overrides in ~/.config/ghostty/user.conf.
  - Launcher: Meta+Space opens Rofi.
$blur_hint
  - Panels: the saved layout (top bar + bottom dock) is applied on the first install;
    save your own with 'plasmonk panels save' and bring it back with 'plasmonk panels restore'.

Try:  plasmonk apply --preset red  |  plasmonk apply --wallpaper  |  plasmonk wallpaper-colors  |  plasmonk doctor
EOF
