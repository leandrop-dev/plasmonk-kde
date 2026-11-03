---
name: plasmonk-sandbox-test
description: Test bin/plasmonk (apply, setup, menus, opacity, on-wallpaper-change) without changing the live Plasma session. Use after editing plasmonk, lib/common.sh, templates or the Plasma style, before deploying to the real desktop.
---

# Sandbox-test plasmonk

`lib/common.sh` honors `XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_STATE_HOME` and `PLASMA_CHANGEICONS`, so pointing
them (and `HOME`, for `~/.zshrc`) at the scratchpad keeps every file write out of the real home. The commands that
talk to the running session are replaced with shims that log their arguments.

Write this as a script file in the scratchpad and run it with `bash` (the login shell is zsh, which does not
word-split the way the snippet expects). The scratchpad can be emptied between turns: recreate the script when it is
gone. When `setup` gains a new command that talks to the session, add it to the shim list first.

```bash
#!/bin/bash
set -u
SB=<scratchpad>/sandbox
rm -rf "$SB"; mkdir -p "$SB"/shim "$SB"/config "$SB"/data "$SB"/state "$SB"/home
for c in plasma-apply-colorscheme plasma-apply-wallpaperimage plasma-apply-desktoptheme plasma-apply-cursortheme \
         qdbus6 gdbus kbuildsycoca6 kvantummanager changeicons systemctl chsh; do
  printf '#!/bin/sh\necho "SHIM %s $*" >> %s/calls.log\n' "$c" "$SB" > "$SB/shim/$c"; chmod +x "$SB/shim/$c"
done
cp "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "$SB/config/"   # for --wallpaper tests
# App themes are only rendered for apps whose config folder or profile exists:
mkdir -p "$SB/config/vesktop" "$SB/config/zed" "$SB/config/zen/p1"
printf '[Profile0]\nName=d\nIsRelative=1\nPath=p1\nDefault=1\n' > "$SB/config/zen/profiles.ini"
export PATH="$SB/shim:$PATH" XDG_CONFIG_HOME="$SB/config" XDG_DATA_HOME="$SB/data" XDG_STATE_HOME="$SB/state" \
       HOME="$SB/home" PLASMA_CHANGEICONS="$SB/shim/changeicons"
P=/home/leandrop-dev/Projects/plasmonk-kde/bin/plasmonk
$P setup && $P apply --preset red && $P apply --seed '#22aa66' && $P apply --wallpaper && $P on-wallpaper-change
$P menus 0.9 && $P menus opaque && $P opacity 0.5
```

Then check:
- `cat "$SB/calls.log"`: the session commands that would have run.
- No placeholders are left: `grep -rl '@PLASMONK_\|{{' "$SB/config" "$SB/data"` (skip `matugen.toml`), and
  `zcat` each `"$SB/data/plasma/desktoptheme/Plasmonk"/*/*.svgz` through the same grep.
- `xmllint --noout` passes on every rendered SVG (pipe the `.svgz` files through `zcat ... | xmllint --noout -`).
- `kreadconfig6`/`grep` on `$SB/config/kwinrc`, `kdeglobals`, `kglobalshortcutsrc` and
  `Kvantum/kvantum.kvconfig` for setup's writes.

Limits:
- Do not run `install.sh` or `uninstall.sh` here. `systemctl --user` and `sudo` act on the real system regardless of
  XDG overrides.
- In the sandbox, scheme alternation always picks `PlasmonkA`, because the shimmed `plasma-apply-colorscheme` never
  writes `kdeglobals`. Verify alternation live.
- Recoloring and translucency (KSvg, Aurorae, Kvantum) can only be verified live: take a screenshot with
  `spectacle -b -n -f -o`, crop with `magick -crop` before reading it, and sample pixels with
  `magick img -format '%[pixel:p{x,y}]' info:`.
