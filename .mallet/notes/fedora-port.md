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
- plasmalogin login-screen wallpaper: `/etc/plasmalogin.conf` has no background key; needs research into its theme mechanism.
- Optional: add `papirus-icon-theme` so YAMIS inherits `Papirus-Dark` instead of warning and falling back to `breeze-dark`.

Done since:
- Better Blur DX on Fedora: `deps/fedora-copr.txt` enables `infinality/kwin-effects-better-blur-dx`, which builds against the installed KWin (2.6.0 for KWin 6.8.2 on f44/f45 at the time of writing) and installs the same `better_blur_dx.so` the Arch path expects. `configure_blur` now flips stock Blur off on both distros, and `doctor` compares the RPM's `Requires: kwin = X` with the installed KWin on Fedora (the Arch path keeps the build/install date heuristic).
- GTK dead keys (`´`, `` ` ``, `~`, `^`) on Plasma Wayland: GTK 4.20+ stopped composing them itself when no input method runs (Ghostty is a GTK app). `plasmonk setup` writes `GTK_IM_MODULE=simple` to `~/.config/environment.d/10-plasmonk-gtk-im.conf`, skipped when the session or an environment.d file already sets one; `uninstall.sh` removes it.
- matugen compatibility: Fedora 45 ships 3.1.0, which has neither `--show-source-colors` nor `--source-color-index` (both arrived in 4.0). plasmonk probes the CLI: on 3.x `wallpaper-colors` lists matugen's single source color (read from `--dry-run --json hex`) and `--color-index` falls back to it with a warning.

Decisions:
- [firm] Fedora uses dnf + COPR; no AUR helper.
- [firm] Better Blur DX comes from the `infinality` COPR on Fedora; stock Blur is only the fallback when the package cannot be installed.
- [tentative] Panel widgets are a follow-up, not part of the first Fedora pass.
