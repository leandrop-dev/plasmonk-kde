# Blur consistency and neutral surfaces

Round 1 encoded the live machine's look into the repo (menu opacity 0.53, `kvantum-dark`, blue
`#0B57A4`, Better Blur DX look + regex window classes, `plasmonk blur`), and the follow-up neutralized
the dark surfaces to Dolphin's greys. This note records what shipped and what is still pinned for a
later session.

## Why System Settings still blurs in parts

KDE splits rendering across three systems with no shared opacity model:

- Qt Widgets apps (Dolphin, Konsole, Kate) -> Kvantum, with true body translucency
  (`themes/mystical/templates/kvantum/Plasmonk.kvconfig`).
- Plasma chrome (popups, drawers, applet backgrounds) -> desktop-theme SVGs carrying
  `@PLASMONK_MENU_OPACITY@`.
- Kirigami app page backgrounds (System Settings content, Discover) -> a hard-coded opaque
  rectangle: `/usr/lib64/qt6/qml/org/kde/desktop/Page.qml` (lines ~25-27) and `Pane.qml`
  (lines ~18-20) use `Rectangle { color: Kirigami.Theme.backgroundColor }`, which resolves to the
  color scheme's opaque `[Colors:View]` / `[Colors:Window]`.

The `.colors` format is RGB only (no alpha), and there is no Kvantum-equivalent for QML.

## Shipped since the plan

- `plasmonk blur` manages Better Blur DX's look (strength, brightness, contrast, corner, saturation), runs from
  `setup`/`apply`, and persists overrides in state.
- Live defaults encoded: menu opacity 0.53, widget style `kvantum-dark`, blue preset `#0B57A4`, and blur classes
  seeded with `/^org\.kde\..*/` plus `zendo`.
- Neutral surfaces adopted from Dolphin (Kvantum `#101010`): the 9 panel pieces are `#101010` at 0.88 opacity,
  the 9 tooltip pieces are `#101010` (they were `#252525` at 0.6 and `#3a3f4a`), and the Vesktop Midnight theme
  uses neutral greys while keeping the palette's blue accents.
- Qt/Kvantum menus (Dolphin right-click and similar) use `@PLASMONK_KVANTUM_MENU_OPACITY@` = menu + 0.32
  (0.85 at the default menu 0.53) so context menus stay readable; Plasma popups stay at the menu value.
- Finding: the values in `kwinrc` (`BlurStrength=4`, `Brightness=30`, `Contrast=105`, `CornerRadius=15`,
  `Saturation=0`) were written on 2026-11-12 16:50, after the effect had loaded at boot. Nothing reconfigured
  the effect until `plasmonk blur` did, so it ran on Better Blur DX defaults in between. That is why the bars
  changed appearance on the first deploy.

## Pinned items

- **Do not implement yet: shadow `org.kde.desktop/Page.qml`.** A per-user copy (to force Kirigami
  page-body translucency) would fix System Settings and Discover, but it shadows a system QML
  module, breaks on Plasma updates, and has a system-wide blast radius. Decide whether that
  fragility is worth it before writing anything.
- **Audit which Plasma SVG each surface actually consumes.** Needs live screenshots:
  `spectacle -b -n -f -o`, crop with `magick -crop`, sample pixels with
  `magick img -format '%[pixel:p{x,y}]' info:`, per `.claude/skills/plasmonk-sandbox-test/SKILL.md`.

## Reference

Live values captured 2026-11 and now encoded as repo defaults:

| Setting | Live |
|---|---|
| menus opacity | 0.53 |
| Qt widget style | kvantum-dark |
| seed color | #0B57A4 |
| Better Blur BlurStrength | 4 |
| Better Blur Brightness | 30 |
| Better Blur Contrast | 105 |
| Better Blur CornerRadius | 15 |
| Better Blur Saturation | 0 |
