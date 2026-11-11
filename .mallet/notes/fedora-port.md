# Fedora port

Goal: run plasmonk-kde on Fedora (dnf + COPR) while keeping the Arch path unchanged.

Done (2026-11-11, PR #1 merged into `main` as `0e65754`):
- Distro abstraction in `lib/common.sh`: `DISTRO`, `pkg_installed`/`pkg_install`/`pkg_remove`, `distro_package_names`.
- `deps/fedora.txt` (dnf) and `deps/fedora-copr.txt` (owner/project -> packages).
- Fedora extras: COPRs (ghostty, starship, mise, bibata), oh-my-zsh, zsh-history-substring-search, YAMIS icons, JetBrains Mono Nerd Font.
- Distro paths: `plasma-changeicons` under /usr/libexec, `QDBUS` (qdbus6/qdbus-qt6), fd/fdfind, /usr/lib64 plugin lookups.
- SDDM login-screen wallpaper skipped when SDDM is not the active DM (plasmalogin on Fedora 45). Stock KWin Blur kept.
- Uninstall records and offers to remove the Fedora extras and enabled COPR repositories.
- `state_set` fixed for the only-line case; install/uninstall print the failing line on a `set -e` abort.

Pending / deferred:
- Panel widgets referenced by `themes/mystical/panels/layout.js`: `luisbocanegra.audio.visualizer` (needs cava), `org.kde.plasma.catwalk`, `org.kde.olib.thermalmonitor`, plasma-drawer. Build from source or a COPR, then add to the Fedora lists.
- Better Blur DX on Fedora: stock Blur is used. For blur behind translucent app windows, either build `kwin-effects-better-blur-dx` against `kwin-devel` or add per-window Blur rules.
- plasmalogin login-screen wallpaper: `/etc/plasmalogin.conf` has no background key; needs research into its theme mechanism.
- Optional: add `papirus-icon-theme` so YAMIS inherits `Papirus-Dark` instead of warning and falling back to `breeze-dark`.

Decisions:
- [firm] Fedora uses dnf + COPR; no AUR helper.
- [firm] Better Blur DX is Arch-only for now; stock Blur on Fedora.
- [tentative] Panel widgets are a follow-up, not part of the first Fedora pass.
