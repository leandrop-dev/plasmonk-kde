# Plasmonk

**A recolorable KDE Plasma 6 theme.** Plasmonk is a port of
[juxtopposed/Mystical-Blue-Theme](https://github.com/juxtopposed/Mystical-Blue-Theme): the same look, but the
colors come from [matugen](https://github.com/InioX/matugen), so the desktop can be blue, red, orange, any color
you pick, or follow your wallpaper.

![KDE Plasma 6](https://img.shields.io/badge/KDE_Plasma-6-1d99f3)
![Arch Linux](https://img.shields.io/badge/Arch-AUR-1793d1)
![Fedora](https://img.shields.io/badge/Fedora-dnf_%2B_COPR-51a2da)

<!--
Screenshots: add an image to the repo (for example assets/screenshot.png) and replace this comment:
![Plasmonk desktop](assets/screenshot.png)
-->

<details>
<summary>Contents</summary>

- [About](#about)
- [Features](#features)
- [Requirements](#requirements)
- [Install](#install)
  - [Packages](#packages)
  - [Fedora notes](#fedora-notes)
  - [After installing](#after-installing)
  - [Shortcuts](#shortcuts)
- [Terminal and shell](#terminal-and-shell)
- [Usage](#usage)
- [Apps](#apps)
- [Translucency](#translucency)
- [Login screen](#login-screen)
- [Panel layout](#panel-layout)
- [Uninstall](#uninstall)
- [How it works](#how-it-works)
- [Upstream issues addressed](#upstream-issues-addressed)
- [Credits](#credits)
- [License](#license)

</details>

## About

Plasmonk restyles KDE Plasma 6 in one palette and then recolors the whole desktop from a single seed color or
from your wallpaper. It covers the Plasma style, window decorations, the Kvantum application style, Rofi, the
terminal, the shell prompt and, when those apps are present, Vesktop, Zed, Zen and Thunderbird.

The installer is per-user: it writes into your home folder, backs up the KDE settings it changes, and ships an
uninstaller that restores them. It supports Arch-based systems (via pacman and the AUR) and Fedora (via dnf and
COPR).

## Features

- **Recolor everything from one color.** `plasmonk apply --seed '#8a5cf5'`, a named preset, or the dominant color
  of your wallpaper. Follow the wallpaper automatically as it changes.
- **A coherent desktop.** Plasma style, window decoration, Kvantum, Rofi, Ghostty, Konsole and the shell prompt all
  take their accents from the same palette.
- **A ready-made terminal.** Ghostty and zsh with oh-my-zsh, autosuggestions, syntax highlighting, zoxide, fzf,
  mise, eza, Starship and fastfetch, styled with the Plasmonk colors.
- **App themes** for Vesktop, Zed, Zen and Thunderbird, applied only to apps you already use.
- **Independent translucency** for windows (`plasmonk opacity`) and for popups and menus (`plasmonk menus`).
- **A saved panel layout**: a floating top bar and a bottom dock, applied on the first install.
- **Your wallpaper on the login screen** (SDDM), kept in sync by a user service.
- **Reversible.** Settings and config files are backed up, and `uninstall.sh` restores them.

## Requirements

- KDE Plasma 6 (KWin).
- An Arch-based distro (Arch, CachyOS, EndeavourOS, ...) with `paru` or `yay` for the AUR packages, or
  Fedora (Workstation or KDE), which uses `dnf` and COPR.

## Install

```sh
git clone https://github.com/leandrop-dev/plasmonk-kde.git
cd plasmonk-kde
./install.sh
```

The installer lists every package it is going to install and asks before changing anything. It then:

1. installs the missing packages below,
2. backs up the KDE settings and config files it changes (`~/.local/state/plasmonk/backup/`),
3. installs the theme into your home folder and applies the blue preset,
4. sets the Bibata Modern Ice cursor, YAMIS icons, Ghostty as the default terminal and GTK's simple input
   method (dead keys work in Ghostty and other GTK apps),
5. offers to make zsh your login shell (`chsh`; skip with `--keep-shell`),
6. on the first install, replaces your panels with the saved layout (keep yours with `--keep-panels`).

Options: `--preset red`, `--opaque-menus`, `--skip-packages`, `--keep-shell`, `--panels`, `--keep-panels`,
`--yes`. Run `./install.sh --help`.

### Packages

| Purpose | Arch package | Fedora package |
|---|---|---|
| Palette generation | `matugen` (official repos) | `matugen` (dnf) |
| Application style | `kvantum` (official repos) | `kvantum` (dnf) |
| Font (Nerd Font variant, as used in the original video) | `ttf-jetbrains-mono-nerd` (official repos) | JetBrainsMono Nerd Font from the official Nerd Fonts release, installed into `~/.local/share/fonts` |
| Launcher (native Wayland since 2.0) | `rofi` (official repos) | `rofi` (dnf) |
| Terminal | `ghostty` (official repos) | `ghostty` (COPR `scottames/ghostty`) |
| Shell, prompt | `zsh`, `starship` (official repos) | `zsh` (dnf), `starship` (COPR `atim/starship`) |
| Shell tools | `zoxide`, `fzf`, `eza`, `fd`, `fastfetch`, `mise` (official repos) | `zoxide`, `fzf`, `eza`, `fd-find`, `fastfetch` (dnf), `mise` (COPR `jdxcode/mise`) |
| zsh plugins | `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-history-substring-search` (official repos) | `zsh-autosuggestions`, `zsh-syntax-highlighting` (dnf); `zsh-history-substring-search` cloned into `~/.config/zsh/plugins` |
| zsh framework | `oh-my-zsh-git` (AUR) | oh-my-zsh official installer (into `~/.oh-my-zsh`) |
| Icons (Yet Another Monochrome Icon Set) | `yamis-icon-theme-git` (AUR) | cloned from Bitbucket into `~/.local/share/icons` |
| Cursor (Bibata Modern Ice) | `bibata-cursor-theme-bin` (AUR) | `bibata-cursor-themes` (COPR `peterwu/rendezvous`) |
| Window blur | `kwin-effects-better-blur-dx` (AUR) | `kwin-effects-better-blur-dx` (COPR `infinality/kwin-effects-better-blur-dx`) |
| Panel widgets used by the saved layout: Audio Visualizer (with `cava`), CatWalk, Thermal Monitor | `plasma6-applets-audio-visualizer`, `plasma6-applets-catwalk`, `plasma6-applets-thermalmonitor` (AUR) | not installed yet (see below) |
| Full-screen launcher (installed, not on a panel) | `plasma6-applets-plasma-drawer-git` (AUR) | not installed yet (see below) |

### Fedora notes

On Fedora the installer uses `dnf` for the base packages and enables the noted COPRs; it lists both and asks
before changing anything. The panel widgets are not installed on Fedora yet, so the saved layout leaves them out.
If Better Blur DX is missing (for example with `--skip-packages`), KWin's stock Blur stays on: it blurs Plasma
panels, popups and menus, and translucent app windows may need a per-window "Blur" rule.

### After installing

Log out and back in so every app picks up the Kvantum style and font, the new cursor, and your login shell. Then:

- **Blur:** the installer replaces KWin's stock Blur with *Better Blur DX* (they conflict) and blurs the apps in
  `themes/mystical/better-blur-classes.txt`; add more in System Settings → Window Management → Desktop Effects →
  Better Blur DX. Classes you remove stay removed on reinstall. Better Blur DX is compiled against one KWin
  release: after a Plasma upgrade it can stop working until its package is rebuilt (`plasmonk doctor` says so).
  If it cannot be installed (e.g. `--skip-packages`), KWin's stock Blur stays on and blurs panels, popups and menus.

### Shortcuts

| Keys | Opens |
|---|---|
| Meta+Space | Rofi app launcher |
| Ctrl+Alt+T | Ghostty (taken over from Konsole) |

Both are registered through `.desktop` files in `~/.local/share/applications`; change them in System Settings →
Keyboard → Shortcuts. Ctrl+Alt+T works by placing local copies of Ghostty's and Konsole's `.desktop` files there,
which shadow the system ones. If a Konsole or Ghostty update changes its `.desktop` file, re-run
`plasmonk setup && plasmonk apply`.

## Terminal and shell

The terminal setup follows [Ryoku](https://github.com/Ryoku-dev/ryoku)'s, with Plasmonk's colors:

- **Ghostty**, translucent and blurred, with the Plasmonk title bar. New windows start at 110x30 cells so
  fastfetch's layout fits. `~/.config/ghostty/config` is written once and then left to you; put color overrides
  in `~/.config/ghostty/user.conf`. Konsole gets a matching *Plasmonk* profile.
- **zsh** with oh-my-zsh, autosuggestions, syntax highlighting, history substring search, zoxide (`cd`), fzf, mise
  and eza (`ls`, `lt`). `~/.zshrc` gets one line that loads `~/.config/zsh/plasmonk.zsh`; your own settings go in
  `~/.config/zsh/user.zsh`, or anywhere in `~/.zshrc`.
- **Starship** with Ryoku's pill prompt, and **fastfetch** on every new terminal.

Ghostty is a GTK app, and GTK 4.20+ no longer composes dead keys (`´` `` ` `` `~` `^`) itself on Wayland when no
input method runs. Plasma does not run one by default, so `plasmonk setup` writes
`GTK_IM_MODULE=simple` to `~/.config/environment.d/10-plasmonk-gtk-im.conf`, which restores GTK's built-in
compose handling for every GTK app; it applies at the next login. If you configure IBus or Fcitx, delete that file
so your input method is used instead.

Foreground, cursor, selection, prompt pills and syntax highlighting follow the palette. The background stays the
original Mystical dark grey on every palette, like the panels. The 16 ANSI
colors keep fixed hues, so red still means an error on every preset. New terminals pick up a new palette; open
terminals keep the old one.

## Usage

```sh
plasmonk apply --preset red          # blue, red, orange (see presets.conf)
plasmonk apply --seed '#8a5cf5'      # any color
plasmonk apply --wallpaper           # colors from the current wallpaper, and keep following it
plasmonk apply --wallpaper ~/pic.jpg # set a wallpaper and take colors from it
plasmonk wallpaper-colors            # list the wallpaper's candidate colors (0 = most dominant)
plasmonk apply --color-index 1       # use the 2nd candidate; remembered for later wallpapers
plasmonk menus 0.85                  # popups, menus, tooltips; or: opaque, translucent
plasmonk opacity 0.73                # title bars, windows, terminals, app themes (see below)
plasmonk status
plasmonk doctor                      # checks packages, files, and whether Better Blur needs a rebuild
```

Your own presets go in `~/.config/plasmonk/presets.conf` (`name=#rrggbb` per line); they survive reinstalls.

matugen 4.x finds 1 to 5 candidate colors per image. When the remembered index does not exist for a new wallpaper,
plasmonk uses the most dominant color and says so. Fedora 45 ships matugen 3.1.0, which reports only the single
color it picked: `wallpaper-colors` lists that one, and `--color-index` beyond 0 needs matugen 4.0+.

Already-running Qt apps only switch to new Kvantum colors after a restart. Plasma, window decorations and newly
opened apps update immediately.

Wallpaper following only works with the *Image* wallpaper type. Slideshows are not tracked.

## Apps

If you have used them (their config folder exists), Plasmonk themes these apps with the same rule as the
desktop: Mystical dark-grey backgrounds, accents from the palette.

| App | How | Translucent + blurred | Picks up a new palette |
|---|---|---|---|
| Vesktop | `~/.config/vesktop/themes/plasmonk.theme.css`, based on [Midnight](https://github.com/refact0r/midnight-discord) (imported from its site, so it needs network), enabled in Vencord | yes: Vencord's transparent window + Midnight's transparency options | when Vencord reloads the theme file |
| Zed | `~/.config/zed/themes/plasmonk.json`, derived from Zed's One Dark; set as the dark theme | yes: `background.appearance: blurred` | when Zed reloads the theme file |
| Zen | `chrome/plasmonk.css` in the default profile; `userChrome.css` and `userContent.css` import it | yes: `zen.widget.linux.transparency` | on restart |
| Thunderbird | `chrome/plasmonk.css` in the default profile, imported by `userChrome.css`, using Thunderbird's own layout variables | no: Thunderbird has no transparency setting | on restart |

Zen and Thunderbird need `toolkit.legacyUserProfileCustomizations.stylesheets`; Plasmonk adds it to the
profile's `user.js`. Your previous `userChrome.css`, `userContent.css` and `user.js` are kept, and
`uninstall.sh` puts them back, turns the Vesktop theme off and restores your Zed theme. Your own Vesktop tweaks
go in QuickCSS.

Translucent surfaces share one opacity, 0.63 by default, and Better Blur DX blurs what is behind them. Title bars
too: the Plasmonk window decoration uses it and `BlurDecorations` is on. Vesktop's transparency only applies
after quitting it fully (tray icon > Quit) and starting it again.

## Translucency

Two values, each from 0.20 (see-through) to 1.00 (solid). Setting one re-renders everything.

```sh
plasmonk opacity          # show the current value (default 0.63)
plasmonk opacity 0.73     # title bars, windows, terminals, app themes
plasmonk menus            # show the current value (default 0.80)
plasmonk menus 0.85       # popups, menus and tooltips; also: opaque (1.00), translucent (0.80)
```

`plasmonk opacity` applies to title bars and window frames, Qt app window backgrounds and their file and list
areas (Kvantum), Ghostty and Konsole, and the Vesktop, Zen and Zed themes. In Dolphin the file area is drawn on
top of the window background, so the two layers stack and look more solid than a title bar at the same value.

`plasmonk menus` applies to Plasma popups (app launcher, tray, calendar), Qt app menus and tooltips (Kvantum),
and Plasma tooltips, which stay 0.10 more solid than popups as upstream draws them. Shadows keep their own values.

Ghostty picks changes up on a config reload (ctrl+shift+,); already-running Qt apps after a restart.

On Arch and Fedora alike, blur strength, brightness, contrast and saturation are Better Blur DX's own settings:
System Settings > Window Management > Desktop Effects > Better Blur DX. With the stock Blur fallback, they are
under Blur instead.

## Login screen

The SDDM login screen and the lock screen keep their Breeze look. With your OK, `install.sh` (sudo, once) makes
SDDM show your desktop wallpaper: it creates `/var/lib/plasmonk/sddm`, owned by you and readable by SDDM, and sets
`background=` in the SDDM theme's `theme.conf.user`. From then on, every wallpaper change is copied there (as a
JPEG, at most 4K) by the wallpaper watcher, whatever the palette mode. SDDM cannot read your home folder, hence the
copy. The lock screen's wallpaper is set separately in System Settings > Screen Locking.

This step only runs when SDDM is installed and is the active display manager. Fedora 45+ KDE uses
plasma-login-manager (`plasmalogin`) instead, whose config has no background key, so the login-screen wallpaper is
skipped there; `install.sh` says so in its plan.

## Panel layout

`themes/mystical/panels/layout.js` is a saved panel layout: a floating top bar (launcher, pager, global menu,
audio visualizer between two spacers, CatWalk CPU meter, thermal monitor, tray, clock) and a bottom dock (icon
tasks), both translucent. It is a Plasma layout script, the same format KDE global themes use, with every
widget's settings. The first install applies it; later runs leave your panels alone.

```sh
plasmonk panels save                 # save your current panels to ~/.config/plasmonk/panels.js
plasmonk panels save FILE            # ...or anywhere, e.g. themes/mystical/panels/layout.js in this repo
plasmonk panels restore              # replace all panels with your saved layout (else the shipped one)
./install.sh --panels                # apply the shipped layout on a reinstall too
```

Restore backs up your panels first and prints how to undo. For the system tray it saves which items it holds, not
each item's own settings (e.g. a weather location). Widgets that are not installed are left out, with a warning.

## Uninstall

```sh
./uninstall.sh                     # restores your previous KDE settings and removes Plasmonk's files
./uninstall.sh --remove-packages   # also uninstalls the packages above that Plasmonk installed
```

The uninstaller offers to switch your login shell back, restores your previous cursor, icons, terminal and any
Starship or fastfetch config you had, and removes Plasmonk's line from `~/.zshrc`. It keeps a Ghostty config you
edited. `--remove-packages` never removes packages you had before installing Plasmonk.

On Fedora it also asks whether to remove the assets it installed (oh-my-zsh, YAMIS icons, the Nerd Font and a
cloned zsh plugin) and the COPR repositories it enabled. It only removes what `install.sh` recorded, so anything
you had before Plasmonk stays; with `--yes` it keeps them unless `--remove-packages` is also given.

## How it works

| Component | Source | How it gets colors |
|---|---|---|
| Color scheme | `themes/mystical/templates/plasmonk.colors` | matugen template |
| Plasma style | `themes/mystical/plasma/Plasmonk/` | KSvg `ColorScheme-*` classes, follows the color scheme |
| Window decoration | `themes/mystical/aurorae/` + `templates/aurorae/` | matugen template (buttons only; the frame is neutral) |
| Kvantum | `themes/mystical/templates/kvantum/` | matugen template |
| Rofi | `themes/mystical/rofi/config.rasi` + `templates/rofi/` | matugen template, imported by the config |
| Ghostty, Konsole | `themes/mystical/terminal/` + `templates/terminal/` | matugen template, included by the static config |
| Starship, fastfetch, zsh highlighting | `templates/terminal/` | matugen template |

`tools/convert-plasma-colors.sh` is the one-off developer script that converted the upstream Plasma style's
hardcoded colors into ColorScheme classes. It is not needed to install.

## Upstream issues addressed

| Upstream | Fix here |
|---|---|
| #14 Plasma style hardcodes blue · #18 menus can't be opaque | Plasma style follows the color scheme; `plasmonk menus opaque` (or any value) |
| #15 Rofi text unreadable | Every Rofi element state has explicit colors |
| #19 #20 #21 wrong font link | `ttf-jetbrains-mono-nerd` from the official repos |
| #22 Better Blur unmaintained · #10 breaks after Plasma updates | Better Blur DX fork; `plasmonk doctor` flags when it needs a rebuild |
| #11 colors don't apply | Installer turns off custom and wallpaper accent colors so the scheme's accent wins |
| #25 #26 apt-only installer | Native pacman + AUR and dnf + COPR installers |
| #27 no uninstaller | `uninstall.sh`, using that PR's safety rules |

Not addressed: #24 says the original screenshots use YAMIS *for COSMIC*. This installs the KDE YAMIS set (from the
AUR on Arch, cloned from Bitbucket on Fedora).

## Credits

Plasmonk is built on [Mystical-Blue-Theme](https://github.com/juxtopposed/Mystical-Blue-Theme) by Juxtopposed,
and its terminal and shell setup is adapted from [Ryoku](https://github.com/Ryoku-dev/ryoku). See
[CREDITS.md](CREDITS.md) for every upstream asset and its license.

## License

Plasmonk's own scripts and configuration are released under the MIT License; see [LICENSE](LICENSE).

The bundled theme assets and templates keep their upstream licenses, listed in [CREDITS.md](CREDITS.md) and in
`licenses/`. Those include MIT, GPL-3.0 and LGPL components, so check `CREDITS.md` before redistributing. Because
the repository combines these licenses, GitHub reports it as "Other" rather than as a single SPDX license.
