# Credits and licenses

Plasmonk's theme assets are modified from
[juxtopposed/Mystical-Blue-Theme](https://github.com/juxtopposed/Mystical-Blue-Theme) at commit `99e4705`.
The changes are recoloring and renaming; see the git history from commit `68be823`.

| Asset | Origin | License |
|---|---|---|
| Mystical-Blue-Theme (repo, color scheme, rofi config) | Juxtopposed | MIT, `licenses/Mystical-Blue-Theme.MIT` |
| Plasma style (`themes/mystical/plasma/Plasmonk`) | Juxtopposed, modified from "Ned for Plasma" | LGPL (per its `metadata.json`) |
| Window decoration (`themes/mystical/aurorae`, `templates/aurorae`) | Juxtopposed (JuxDeco), mask fix by Neshura87 (upstream PR #6) | GPL-3.0, `licenses/JuxDeco.GPL-3.0` |
| Kvantum theme (`templates/kvantum`) | Patrik Wyde (No Man's Sky), modified by Juxtopposed | GPL-3.0, `licenses/NoMansSky-Kvantum.GPL-3.0` |

The uninstaller's safety rules follow upstream PR #27 by 0xluc1an.

## Terminal and shell

The terminal and shell setup is adapted from [Ryoku-dev/ryoku](https://github.com/Ryoku-dev/ryoku)
(`ryoku/apps`, main at `f7197d7`), GPL-3.0, `licenses/Ryoku.GPL-3.0`. The changes are Plasmonk's colors in place of
Ryoku's, and removing Ryoku's own services and branding.

| File | Adapted from |
|---|---|
| `themes/mystical/terminal/plasmonk.zsh` | `ryoku/apps/zsh/ryoku.zsh` |
| `themes/mystical/terminal/ghostty.config`, `templates/terminal/ghostty-colors` | Ryoku's Ghostty config and color template |
| `templates/terminal/starship.toml` | `ryoku/apps/starship/starship.toml` (pill layout) |
| `templates/terminal/fastfetch.jsonc` | Ryoku's fastfetch config (dossier layout) |

## Apps

| File | Adapted from | License |
|---|---|---|
| `templates/apps/vesktop.theme.css` | [refact0r/midnight-discord](https://github.com/refact0r/midnight-discord) `themes/midnight.theme.css` 2.1.1 (imports its build) | MIT, `licenses/midnight-discord.MIT` |
| `templates/apps/zed-plasmonk.json` | Zed's One Dark (`assets/themes/one/one.json`), © GitHub Inc. | MIT, `licenses/zed-one-theme.MIT` |
| `templates/apps/zen.css` | Variable list from the earlier hyprmonk Zen output | — |
