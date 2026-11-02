# plasmonk-kde

Personal KDE Plasma 6 customizations. The first piece is **Plasmonk**, a recolorable port of
[juxtopposed/Mystical-Blue-Theme](https://github.com/juxtopposed/Mystical-Blue-Theme): the same look, but the
colors come from [matugen](https://github.com/InioX/matugen), so it can be blue, red, orange, any color you pick,
or follow your wallpaper.

## Install

Requirements: an Arch-based distro (Arch, CachyOS, EndeavourOS, ...), KDE Plasma 6, and `paru` or `yay` for the
AUR packages.

```sh
git clone <this repo> && cd plasmonk-kde
./install.sh
```

The installer lists every package it is going to install and asks before changing anything. It then:

1. installs the missing packages below,
2. backs up the KDE settings and config files it changes (`~/.local/state/plasmonk/backup/`),
3. installs the theme into your home folder and applies the blue preset,
4. sets the Bibata Modern Ice cursor, YAMIS icons and Ghostty as the default terminal,
5. offers to make zsh your login shell (`chsh`; skip with `--keep-shell`).

Options: `--preset red`, `--opaque-menus`, `--skip-packages`, `--keep-shell`, `--panels`, `--yes`. Run
`./install.sh --help`.

After installing, log out and back in. Then:

- **Blur:** the installer replaces KWin's stock Blur with *Better Blur DX* (they conflict) and blurs the apps in
  `themes/mystical/better-blur-classes.txt`. Add more in System Settings → Window Management → Desktop Effects →
  Better Blur DX. Classes you remove stay removed on reinstall.
- **Transparent panel:** add the *Panel Colorizer* widget to your panel → Appearance → Native Panel → uncheck
  *Background*.

### Shortcuts

| Keys | Opens |
|---|---|
| Meta+Space | Rofi app launcher |
| Ctrl+Alt+T | Ghostty (taken over from Konsole) |

Both are registered through `.desktop` files in `~/.local/share/applications`; change them in System Settings →
Keyboard → Shortcuts. Ctrl+Alt+T works by placing local copies of Ghostty's and Konsole's `.desktop` files there,
which shadow the system ones. If a Konsole or Ghostty update changes its `.desktop` file, re-run
`plasmonk setup && plasmonk apply`.

### Terminal and shell

The terminal setup follows [Ryoku](https://github.com/Ryoku-dev/ryoku)'s, with Plasmonk's colors:

- **Ghostty**, translucent and blurred, with the Plasmonk title bar. `~/.config/ghostty/config` is written once and
  then left to you; put color overrides in `~/.config/ghostty/user.conf`. Konsole gets a matching *Plasmonk* profile.
- **zsh** with oh-my-zsh, autosuggestions, syntax highlighting, history substring search, zoxide (`cd`), fzf, mise
  and eza (`ls`, `lt`). `~/.zshrc` gets one line that loads `~/.config/zsh/plasmonk.zsh`; your own settings go in
  `~/.config/zsh/user.zsh`, or anywhere in `~/.zshrc`.
- **Starship** with Ryoku's pill prompt, and **fastfetch** on every new terminal.

Foreground, cursor, selection, prompt pills and syntax highlighting follow the palette. The background stays the
original Mystical dark grey on every palette, like the panels. The 16 ANSI
colors keep fixed hues, so red still means an error on every preset. New terminals pick up a new palette; open
terminals keep the old one.

### Packages installed

| Purpose | Package | Source |
|---|---|---|---|
| Palette generation | `matugen` | official repos |
| Application style | `kvantum` | official repos |
| Font (Nerd Font variant, as used in the original video) | `ttf-jetbrains-mono-nerd` | official repos |
| Launcher (native Wayland since 2.0) | `rofi` | official repos |
| Terminal | `ghostty` | official repos |
| Shell, prompt | `zsh`, `starship` | official repos |
| Shell tools | `zoxide`, `fzf`, `eza`, `fd`, `fastfetch`, `mise` | official repos |
| zsh plugins | `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-history-substring-search` | official repos |
| zsh framework | `oh-my-zsh-git` | AUR |
| Icons (Yet Another Monochrome Icon Set) | `yamis-icon-theme-git` | AUR |
| Cursor (Bibata Modern Ice) | `bibata-cursor-theme-bin` | AUR |
| Window blur | `kwin-effects-better-blur-dx` | AUR |
| Transparent panel | `plasma6-applets-panel-colorizer` | AUR |
| Flexible panel spacer (used by the saved layout) | `plasma6-applets-panel-spacer-extended` | AUR |

## Usage

```sh
plasmonk apply --preset red          # blue, red, orange (see presets.conf)
plasmonk apply --seed '#8a5cf5'      # any color
plasmonk apply --wallpaper           # colors from the current wallpaper, and keep following it
plasmonk apply --wallpaper ~/pic.jpg # set a wallpaper and take colors from it
plasmonk wallpaper-colors            # list the wallpaper's candidate colors (0 = most dominant)
plasmonk apply --color-index 1       # use the 2nd candidate; remembered for later wallpapers
plasmonk menus opaque                # or: translucent
plasmonk opacity 0.75                # translucency of title bars, windows, terminals (see below)
plasmonk status
plasmonk doctor                      # checks packages, files, and whether Better Blur needs a rebuild
```

Your own presets go in `~/.config/plasmonk/presets.conf` (`name=#rrggbb` per line); they survive reinstalls.

matugen finds 1 to 5 candidate colors per image. When the remembered index does not exist for a new wallpaper,
plasmonk uses the most dominant color and says so.

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

### Translucency

```sh
plasmonk opacity          # show the current value
plasmonk opacity 0.75     # 0.20 (see-through) .. 1.00 (solid); re-renders everything
```

The value applies to title bars and window frames, the file and list areas of Qt apps (Kvantum `base.color`),
Ghostty and Konsole, and the Vesktop, Zen and Zed themes. Ghostty picks it up on a config reload (ctrl+shift+,);
other apps after a restart.

Not covered by it:

- The Kvantum window background behind toolbars and sidebars is fixed at 0.75 (upstream value). In Dolphin the
  file area is drawn on top of it, so the two layers stack and look more solid than a title bar at the same value.
- Plasma popups (app launcher, tray, calendar) and Plasma tooltips use the Plasma style, about 0.8 opaque
  upstream; `plasmonk menus opaque` makes them solid.
- Qt app menus and tooltips use Kvantum's menu and tooltip elements (0.8).
- Blur strength, brightness, contrast and saturation are Better Blur DX's own settings: System Settings >
  Window Management > Desktop Effects > Better Blur DX.

## Login screen

The SDDM login screen and the lock screen keep their Breeze look. With your OK, `install.sh` (sudo, once) makes
SDDM show your desktop wallpaper: it creates `/var/lib/plasmonk/sddm`, owned by you and readable by SDDM, and sets
`background=` in the SDDM theme's `theme.conf.user`. From then on, every wallpaper change is copied there (as a
JPEG, at most 4K) by the wallpaper watcher, whatever the palette mode. SDDM cannot read your home folder, hence the
copy. The lock screen's wallpaper is set separately in System Settings > Screen Locking.

## Panel layout

`themes/mystical/panels/layout.js` is a saved panel layout: a top bar (launcher, pager, global menu, spacer, tray,
clock, show desktop) and a bottom dock (Panel Colorizer + icon tasks). It is a Plasma layout script, the same
format KDE global themes use, with every widget's settings.

```sh
plasmonk panels save                 # save your current panels to ~/.config/plasmonk/panels.js
plasmonk panels save FILE            # ...or anywhere, e.g. themes/mystical/panels/layout.js in this repo
plasmonk panels restore              # replace all panels with your saved layout (else the shipped one)
./install.sh --panels                # apply the shipped layout as part of installing
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

## How it works

| Component | Source | How it gets colors |
|---|---|---|---|
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
| #14 Plasma style hardcodes blue · #18 menus can't be opaque | Plasma style follows the color scheme; `plasmonk menus opaque` |
| #15 Rofi text unreadable | Every Rofi element state has explicit colors |
| #19 #20 #21 wrong font link | `ttf-jetbrains-mono-nerd` from the official repos |
| #22 Better Blur unmaintained · #10 breaks after Plasma updates | Better Blur DX fork; `plasmonk doctor` flags when it needs a rebuild |
| #11 colors don't apply | Installer turns off custom and wallpaper accent colors so the scheme's accent wins |
| #25 #26 apt-only installer | Native pacman + AUR installer |
| #27 no uninstaller | `uninstall.sh`, using that PR's safety rules |

Not addressed: #24 says the original screenshots use YAMIS *for COSMIC*. This installs the KDE YAMIS set from the
AUR.

## Credits

See [CREDITS.md](CREDITS.md).
