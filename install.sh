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
  -y, --yes          Do not ask for confirmation
  -h, --help         Show this help
EOF
}

PRESET="" OPAQUE=0 SKIP_PACKAGES=0 ASSUME_YES=0
while [ $# -gt 0 ]; do
    case "$1" in
    --preset) PRESET="${2:?--preset needs a name}"; shift ;;
    --opaque-menus) OPAQUE=1 ;;
    --skip-packages) SKIP_PACKAGES=1 ;;
    -y | --yes) ASSUME_YES=1 ;;
    -h | --help) usage; exit 0 ;;
    *) usage >&2; die "Unknown option: $1" ;;
    esac
    shift
done

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
echo "    - enable a user service that recolors the theme when you change wallpaper (only after 'plasmonk apply --wallpaper')"
echo
confirm "Continue?" || die "Cancelled; nothing was changed."

# ---------- 2. packages ----------

if [ ${#missing_repo[@]} -gt 0 ]; then
    info "Installing official packages"
    sudo pacman -S --needed "${missing_repo[@]}"
fi
if [ ${#missing_aur[@]} -gt 0 ] && [ -n "$AUR_HELPER" ]; then
    info "Installing AUR packages with $AUR_HELPER"
    "$AUR_HELPER" -S --needed "${missing_aur[@]}"
fi
have matugen || die "matugen is still missing; it is required to generate colors."

# ---------- 3. backups ----------

backup_dir="$PLASMONK_BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$backup_dir"
for f in kdeglobals kwinrc plasmarc Kvantum/kvantum.kvconfig rofi/config.rasi; do
    if [ -f "$XDG_CONFIG_HOME/$f" ]; then
        mkdir -p "$backup_dir/$(dirname "$f")"
        cp -p "$XDG_CONFIG_HOME/$f" "$backup_dir/$f"
    fi
done
ok "Backed up current settings to $backup_dir"

# Record original values once, so a reinstall never records Plasmonk's own values.
if [ ! -f "$ORIGINAL_SETTINGS" ]; then
    for entry in "${MANAGED_KEYS[@]}"; do
        IFS='|' read -r file group key <<<"$entry"
        value="$(kreadconfig6 --file "$file" --group "$group" --key "$key" --default "$UNSET_MARK")"
        printf '%s\t%s\t%s\t%s\n' "$file" "$group" "$key" "$value"
    done >"$ORIGINAL_SETTINGS"
    # Remember whether rofi had a config before us, so uninstall restores or removes it.
    if [ -f "$XDG_CONFIG_HOME/rofi/config.rasi" ]; then cp -p "$XDG_CONFIG_HOME/rofi/config.rasi" "$PLASMONK_STATE/original-rofi-config.rasi"; fi
    ok "Recorded original KDE settings in $ORIGINAL_SETTINGS"
fi

# ---------- 4. install ----------

info "Installing Plasmonk files to $PLASMONK_SHARE"
rm -rf "$PLASMONK_SHARE"
mkdir -p "$PLASMONK_SHARE" "$(dirname "$PLASMONK_BIN_LINK")"
cp -r "$REPO/bin" "$REPO/lib" "$REPO/themes" "$REPO/presets.conf" "$PLASMONK_SHARE/"
ln -sfn "$PLASMONK_SHARE/bin/plasmonk" "$PLASMONK_BIN_LINK"
case ":$PATH:" in
*":$(dirname "$PLASMONK_BIN_LINK"):"*) ;;
*) warn "$(dirname "$PLASMONK_BIN_LINK") is not in your PATH; run plasmonk as $PLASMONK_BIN_LINK" ;;
esac

[ "$OPAQUE" -eq 0 ] || state_set menus opaque
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

echo
ok "Plasmonk is installed."
cat <<EOF

Next steps (manual, per upstream README):
  - Log out and back in so every app picks up the Kvantum style and font.
  - Better Blur DX: System Settings > Window Management > Desktop Effects > enable "Better Blur DX".
  - Transparent panel: add the "Panel Colorizer" widget to your panel, then
    Appearance > Native Panel > uncheck "Background".

Try:  plasmonk apply --preset red   |   plasmonk apply --wallpaper   |   plasmonk doctor
EOF
