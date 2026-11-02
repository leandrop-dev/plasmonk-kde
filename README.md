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
2. backs up the KDE settings it changes (`~/.local/state/plasmonk/backup/`),
3. installs the theme into your home folder and applies the blue preset.

Options: `--preset red`, `--opaque-menus`, `--skip-packages`, `--yes`. Run `./install.sh --help`.

After installing, log out and back in. Then:

- **Blur:** the installer replaces KWin's stock Blur with *Better Blur DX* (they conflict) and blurs the apps in
  `themes/mystical/better-blur-classes.txt`. Add more in System Settings → Window Management → Desktop Effects →
  Better Blur DX.
- **Transparent panel:** add the *Panel Colorizer* widget to your panel → Appearance → Native Panel → uncheck
  *Background*.

### Packages installed

| Purpose | Package | Source |
|---|---|---|
| Palette generation | `matugen` | official repos |
| Application style | `kvantum` | official repos |
| Font (Nerd Font variant, as used in the original video) | `ttf-jetbrains-mono-nerd` | official repos |
| Launcher (native Wayland since 2.0) | `rofi` | official repos |
| Icons | `yamis-icon-theme-git` | AUR |
| Window blur | `kwin-effects-better-blur-dx` | AUR |
| Transparent panel | `plasma6-applets-panel-colorizer` | AUR |

## Usage

```sh
plasmonk apply --preset red          # blue, red, orange (see presets.conf)
plasmonk apply --seed '#8a5cf5'      # any color
plasmonk apply --wallpaper           # colors from the current wallpaper, and keep following it
plasmonk apply --wallpaper ~/pic.jpg # set a wallpaper and take colors from it
plasmonk menus opaque                # or: translucent
plasmonk status
plasmonk doctor                      # checks packages, files, and whether Better Blur needs a rebuild
```

Your own presets go in `~/.config/plasmonk/presets.conf` (`name=#rrggbb` per line); they survive reinstalls.

Already-running Qt apps only switch to new Kvantum colors after a restart. Plasma, window decorations and newly
opened apps update immediately.

Wallpaper following only works with the *Image* wallpaper type. Slideshows are not tracked.

## Uninstall

```sh
./uninstall.sh                     # restores your previous KDE settings and removes Plasmonk's files
./uninstall.sh --remove-packages   # also uninstalls the packages above
```

## How it works

| Component | Source | How it gets colors |
|---|---|---|
| Color scheme | `themes/mystical/templates/plasmonk.colors` | matugen template |
| Plasma style | `themes/mystical/plasma/Plasmonk/` | KSvg `ColorScheme-*` classes, follows the color scheme |
| Window decoration | `themes/mystical/aurorae/` + `templates/aurorae/` | matugen template (buttons only; the frame is neutral) |
| Kvantum | `themes/mystical/templates/kvantum/` | matugen template |
| Rofi | `themes/mystical/rofi/config.rasi` + `templates/rofi/` | matugen template, imported by the config |

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
