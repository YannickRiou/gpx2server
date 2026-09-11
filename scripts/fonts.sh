#!/usr/bin/env bash
# Fetch Funnel Display and Mulish (Google Fonts, OFL) and build the static instances the engine
# looks for (FunnelDisplay-Bold.ttf, Mulish-Regular.ttf). Skipped when already cached.
# Falls back silently: without them the engine uses DejaVu, present on the runner.
set -uo pipefail
DIR="${1:-fonts}"
mkdir -p "$DIR"
if [[ -f "$DIR/FunnelDisplay-Bold.ttf" && -f "$DIR/Mulish-Regular.ttf" ]]; then
    echo "fonts cached"; exit 0
fi
BASE="https://github.com/google/fonts/raw/main/ofl"
curl -fsSL -o "$DIR/FunnelDisplay-var.ttf" "$BASE/funneldisplay/FunnelDisplay%5Bwght%5D.ttf" || true
curl -fsSL -o "$DIR/Mulish-var.ttf" "$BASE/mulish/Mulish%5Bwght%5D.ttf" || true
[[ -s "$DIR/FunnelDisplay-var.ttf" ]] && python3 -m fontTools.varLib.instancer -q "$DIR/FunnelDisplay-var.ttf" wght=700 -o "$DIR/FunnelDisplay-Bold.ttf" || echo "Funnel Display unavailable, fallback font"
[[ -s "$DIR/Mulish-var.ttf" ]] && python3 -m fontTools.varLib.instancer -q "$DIR/Mulish-var.ttf" wght=400 -o "$DIR/Mulish-Regular.ttf" || echo "Mulish unavailable, fallback font"
rm -f "$DIR"/*-var.ttf
ls -la "$DIR"
exit 0
