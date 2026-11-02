---
name: plasmonk-sandbox-test
description: Test bin/plasmonk (apply, setup, menus, on-wallpaper-change) without changing the live Plasma session. Use after editing plasmonk, lib/common.sh, templates or the Plasma style, before deploying to the real desktop.
---

# Sandbox-test plasmonk

`lib/common.sh` honors `XDG_CONFIG_HOME`, `XDG_DATA_HOME` and `XDG_STATE_HOME`, so pointing them at the scratchpad
keeps every file write out of the real home. The commands that talk to the running session are replaced with shims
that log their arguments.

```bash
SB=<scratchpad>/sandbox
rm -rf "$SB"; mkdir -p "$SB"/shim "$SB"/config "$SB"/data "$SB"/state
for c in plasma-apply-colorscheme plasma-apply-wallpaperimage plasma-apply-desktoptheme qdbus6; do
  printf '#!/bin/sh\necho "SHIM %s $*" >> %s/calls.log\n' "$c" "$SB" > "$SB/shim/$c"; chmod +x "$SB/shim/$c"
done
cp ~/.config/plasma-org.kde.plasma.desktop-appletsrc "$SB/config/"   # for --wallpaper tests
export PATH="$SB/shim:$PATH" XDG_CONFIG_HOME="$SB/config" XDG_DATA_HOME="$SB/data" XDG_STATE_HOME="$SB/state"
P=~/Projects/plasmonk-kde/bin/plasmonk
$P apply --preset red && $P apply --seed '#22aa66' && $P apply --wallpaper && $P on-wallpaper-change
$P setup && $P menus opaque
```

Then check:
- `cat "$SB/calls.log"`: the session commands that would have run.
- `grep -c '{{' <rendered files>` is 0, and `xmllint --noout` passes on every rendered SVG.
- `kreadconfig6`/`grep` on `$SB/config/kwinrc`, `kdeglobals` and `Kvantum/kvantum.kvconfig` for setup's writes.

Limits:
- Do not run `install.sh` or `uninstall.sh` here. `systemctl --user` acts on the real user manager regardless of
  XDG overrides.
- In the sandbox, scheme alternation always picks `PlasmonkA`, because the shimmed `plasma-apply-colorscheme` never
  writes `kdeglobals`. Verify alternation live.
- Recoloring (KSvg, Aurorae, Kvantum) can only be verified live: apply a preset, take a screenshot with
  `spectacle -b -n -f -o`, crop with `magick -crop`, and sample pixels with
  `magick img -format '%[pixel:p{x,y}]' info:`.
