#!/usr/bin/env bash
# Developer tool (not used by install.sh): converts hardcoded colors in the vendored
# Plasma style SVGs into KSvg ColorScheme classes, so the style follows the active
# KDE color scheme (upstream issue #14). Run once; the converted SVGs are committed.
#
# Requires: xmlstarlet
# Usage: tools/convert-plasma-colors.sh [plasma-theme-dir]
set -euo pipefail

THEME_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)/themes/mystical/plasma/Plasmonk}"

command -v xmlstarlet >/dev/null || { echo "xmlstarlet is required" >&2; exit 1; }
[ -d "$THEME_DIR/widgets" ] || { echo "Not a Plasma theme dir: $THEME_DIR" >&2; exit 1; }

# hex => ColorScheme class. Tones refer to themes/mystical/templates/plasmonk.colors.
# Hue-neutral greys, invisible hit areas (opacity 0.01) and *-hint-* layout
# rectangles (never drawn) are deliberately left alone.
MAP="
1c1c23 ColorScheme-ViewBackground
252525 ColorScheme-ViewBackground
26272a ColorScheme-ViewBackground
343031 ColorScheme-ViewBackground
181b28 ColorScheme-ViewBackground
222329 ColorScheme-ViewBackground
0c0e15 ColorScheme-ButtonBackground
3a3f4a ColorScheme-HeaderBackground
373b43 ColorScheme-HeaderBackground
345db6 ColorScheme-ButtonFocus
276aec ColorScheme-ButtonFocus
567ecf ColorScheme-ButtonFocus
6084d2 ColorScheme-ComplementaryHover
6191e8 ColorScheme-ComplementaryHover
788dbe ColorScheme-ComplementaryHover
85a2dd ColorScheme-ComplementaryHover
17b58e ColorScheme-ComplementaryHover
c1d5ff ColorScheme-ComplementaryFocus
c2d5ff ColorScheme-ComplementaryFocus
dde7ff ColorScheme-ComplementaryFocus
52668e ColorScheme-Highlight
6a7889 ColorScheme-Highlight
da4453 ColorScheme-NegativeText
"

# Placeholder rules; KSvg replaces this element's content at render time.
STYLESHEET='.ColorScheme-Text{color:#232629;} .ColorScheme-Background{color:#eff0f1;} .ColorScheme-Highlight{color:#3daee9;} .ColorScheme-ViewBackground{color:#fcfcfc;} .ColorScheme-ButtonBackground{color:#eff0f1;} .ColorScheme-ButtonFocus{color:#3daee9;} .ColorScheme-HeaderBackground{color:#dee0e2;} .ColorScheme-ComplementaryHover{color:#3daee9;} .ColorScheme-ComplementaryFocus{color:#3daee9;} .ColorScheme-NegativeText{color:#da4453;}'

# Elements eligible for conversion: drawn, unclassed, outside <defs>, not a layout hint.
ELIGIBLE="not(@class) and not(ancestor::*[local-name()='defs']) and not(contains(@id,'hint'))"

convert_file() {
    local svg="$1" hex cls args=() changed=0

    while read -r hex cls; do
        [ -n "$hex" ] || continue
        local match="//*[$ELIGIBLE and contains(@style,'fill:#$hex')]"
        if [ "$(xmlstarlet sel -t -v "count($match)" "$svg")" -gt 0 ]; then
            changed=1
            # Tag first, then rewrite the fill on exactly the elements just tagged.
            args+=(-i "$match" -t attr -n class -v "$cls")
            args+=(-u "//*[@class='$cls' and contains(@style,'fill:#$hex')]/@style"
                   -x "concat(substring-before(.,'fill:#$hex'),'fill:currentColor',substring-after(.,'fill:#$hex'))")
        fi
    done <<<"$MAP"

    [ "$changed" -eq 1 ] || return 0

    xmlstarlet ed -L "${args[@]}" "$svg"

    if [ "$(xmlstarlet sel -t -v "count(//*[local-name()='style' and @id='current-color-scheme'])" "$svg")" -eq 0 ]; then
        xmlstarlet ed -L -s '/*' -t elem -n style -v "$STYLESHEET" \
            -i '/*/style[last()]' -t attr -n type -v text/css \
            -i '/*/style[last()]' -t attr -n id -v current-color-scheme "$svg"
    fi
    echo "converted: ${svg#"$THEME_DIR"/}"
}

while IFS= read -r -d '' svg; do
    convert_file "$svg"
done < <(find "$THEME_DIR/widgets" "$THEME_DIR/dialogs" -name '*.svg' -print0 | sort -z)
