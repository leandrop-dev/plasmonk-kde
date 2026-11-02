#!/usr/bin/env bash
# Developer tool (not used by install.sh): converts hardcoded colors in the vendored
# Plasma style SVGs into KSvg ColorScheme classes, so the style follows the active
# KDE color scheme (upstream issue #14). Idempotent; the converted SVGs are committed.
#
# KSvg recolors an element only when it has a ColorScheme-* class AND paints with
# currentColor AND carries no inline `color:` (an inline color beats the class rule).
# This mirrors how Breeze's own Plasma style is authored.
#
# Requires: xmlstarlet
# Usage: tools/convert-plasma-colors.sh [plasma-theme-dir]
set -euo pipefail

THEME_DIR="${1:-$(cd "$(dirname "$0")/.." && pwd)/themes/mystical/plasma/Plasmonk}"

command -v xmlstarlet >/dev/null || { echo "xmlstarlet is required" >&2; exit 1; }
[ -d "$THEME_DIR/widgets" ] || { echo "Not a Plasma theme dir: $THEME_DIR" >&2; exit 1; }

# Tones refer to themes/mystical/templates/plasmonk.colors:
#   ButtonFocus = primary 50 (accent)      ComplementaryHover = primary 60 (lighter accent)
#   ComplementaryFocus = primary 80 (pale) Highlight = secondary 35 (muted selection)
#   ViewBackground / ButtonBackground / HeaderBackground = tinted neutrals

# Pass 1: unclassed elements with hardcoded fills (hex class).
# Hue-neutral greys, invisible hit areas and *-hint-* layout rectangles are left alone.
MAP_UNCLASSED="
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

# Pass 2: elements that already have a ColorScheme class but paint a hardcoded blue,
# so the class is inert. Their class is replaced to match the intended tone.
# Classed elements painting neutral greys are upstream's deliberate choice and stay.
MAP_CLASSED="
6084d2 ColorScheme-ComplementaryHover
788dbe ColorScheme-ComplementaryHover
7890c5 ColorScheme-ComplementaryHover
738cc2 ColorScheme-ComplementaryHover
6a85c0 ColorScheme-ComplementaryHover
345db6 ColorScheme-ButtonFocus
3f527c ColorScheme-Highlight
52668e ColorScheme-Highlight
6a7889 ColorScheme-Highlight
"

# Pass 3: blue gradient stops (task indicators, glow bar, clock hands).
MAP_STOPS="
6191e8 ColorScheme-ComplementaryHover
85a2dd ColorScheme-ComplementaryHover
3354a9 ColorScheme-ButtonFocus
1755d1 ColorScheme-ButtonFocus
3daee9 ColorScheme-ButtonFocus
345db6 ColorScheme-ButtonFocus
91b5fb ColorScheme-ComplementaryFocus
c2d5ff ColorScheme-ComplementaryFocus
42506c ColorScheme-Highlight
4d576f ColorScheme-Highlight
"
STOP_FILES="widgets/tasks.svg widgets/glowbar.svg widgets/clock.svg"

# Placeholder rules; KSvg replaces this element's content at render time.
STYLESHEET='.ColorScheme-Text{color:#232629;} .ColorScheme-Background{color:#eff0f1;} .ColorScheme-Highlight{color:#3daee9;} .ColorScheme-ViewBackground{color:#fcfcfc;} .ColorScheme-ButtonBackground{color:#eff0f1;} .ColorScheme-ButtonFocus{color:#3daee9;} .ColorScheme-HeaderBackground{color:#dee0e2;} .ColorScheme-ComplementaryHover{color:#3daee9;} .ColorScheme-ComplementaryFocus{color:#3daee9;} .ColorScheme-NegativeText{color:#da4453;}'

DRAWN="not(ancestor::*[local-name()='defs']) and not(contains(@id,'hint'))"
RECOLORED="starts-with(@class,'ColorScheme-') and contains(@style,'currentColor')"

count() { xmlstarlet sel -t -v "count($1)" "$2"; }

# Appends xmlstarlet ops to ARGS: retag elements matching $1 whose style has `$2:#hex`.
# $1 = element predicate, $2 = CSS property (fill | stop-color), $3 = map, $4 = svg
add_ops() {
    local pred="$1" prop="$2" map="$3" svg="$4" hex cls match
    while read -r hex cls; do
        [ -n "$hex" ] || continue
        match="//*[$pred and contains(@style,'$prop:#$hex')]"
        [ "$(count "$match" "$svg")" -gt 0 ] || continue
        # Mark matches with a temporary attribute, then retag and rewrite only those.
        ARGS+=(-i "$match" -t attr -n data-pm -v "$cls")
        ARGS+=(-d "//*[@data-pm='$cls']/@class")
        ARGS+=(-i "//*[@data-pm='$cls']" -t attr -n class -v "$cls")
        ARGS+=(-u "//*[@data-pm='$cls' and contains(@style,'$prop:#$hex')]/@style"
               -x "concat(substring-before(.,'$prop:#$hex'),'$prop:currentColor',substring-after(.,'$prop:#$hex'))")
        ARGS+=(-d "//*[@data-pm='$cls']/@data-pm")
    done <<<"$map"
}

# Removes inline `color:#rrggbb` from recolored elements (it would override the class).
strip_inline_color() {
    local svg="$1" n
    n="$(count "//*[$RECOLORED and (starts-with(@style,'color:#') or contains(@style,';color:#'))]" "$svg")"
    [ "$n" -gt 0 ] || return 0
    local style el
    while IFS= read -r el; do
        style="$(xmlstarlet sel -t -v "//*[@id='$el']/@style" "$svg")"
        style="$(sed -E 's/(^|;)color:#[0-9a-fA-F]{6}(;|$)/\1/; s/;$//' <<<"$style")"
        xmlstarlet ed -L -u "//*[@id='$el']/@style" -v "$style" "$svg"
    done < <(xmlstarlet sel -t -m "//*[$RECOLORED and (starts-with(@style,'color:#') or contains(@style,';color:#'))]" -v @id -n "$svg")
}

convert_file() {
    local svg="$1" rel="${1#"$THEME_DIR"/}"
    ARGS=()
    add_ops "not(@class) and $DRAWN" fill "$MAP_UNCLASSED" "$svg"
    add_ops "starts-with(@class,'ColorScheme-') and $DRAWN" fill "$MAP_CLASSED" "$svg"
    case " $STOP_FILES " in
    *" $rel "*) add_ops "local-name()='stop'" stop-color "$MAP_STOPS" "$svg" ;;
    esac

    if [ ${#ARGS[@]} -gt 0 ]; then
        xmlstarlet ed -L "${ARGS[@]}" "$svg"
        echo "converted: $rel"
    fi
    strip_inline_color "$svg"

    if [ "$(count "//*[$RECOLORED]" "$svg")" -gt 0 ] &&
        [ "$(count "//*[local-name()='style' and @id='current-color-scheme']" "$svg")" -eq 0 ]; then
        xmlstarlet ed -L -s '/*' -t elem -n style -v "$STYLESHEET" \
            -i '/*/style[last()]' -t attr -n type -v text/css \
            -i '/*/style[last()]' -t attr -n id -v current-color-scheme "$svg"
    fi
}

while IFS= read -r -d '' svg; do
    convert_file "$svg"
done < <(find "$THEME_DIR/widgets" "$THEME_DIR/dialogs" -name '*.svg' -print0 | sort -z)
