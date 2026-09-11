#!/usr/bin/env bash
# Run gpx2map or gpx2anim on the fetched GPX files and collect the result in the output folder.
# Parameters come from the environment (set by the workflow): OUTPUT (png|gif|mp4), TITLE, LANG_,
# THEME, FORMAT, SUMMIT (true|false), EXTRA (free options, quotes allowed).
set -euo pipefail
WORK="${1:-work}"
OUT="${2:-out}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$OUT" "$HERE/cache"

# the engine looks for fonts next to the tool: point both tools to the shared folder
for tool in gpx2map gpx2anim; do
    [[ -e "$HERE/$tool/fonts" ]] || ln -s "$HERE/fonts" "$HERE/$tool/fonts"
done

shopt -s nullglob
gpx=("$WORK"/*.gpx)
[[ ${#gpx[@]} -gt 0 ]] || { echo "::error::no GPX in $WORK"; exit 1; }

args=("${gpx[@]}" --lang "${LANG_:-en}" --cache-dir "$HERE/cache")
[[ -n "${TITLE:-}" ]] && args+=(--title "$TITLE")
[[ "${SUMMIT:-true}" == "true" ]] && args+=(--summit)
# split the free options like a shell would (quotes allowed), without eval: a colour such as
# "#DBE64C" would otherwise start a bash comment
mapfile -t extra < <(python3 -c 'import shlex, sys; sys.stdout.write("".join(a + "\n" for a in shlex.split(sys.argv[1], comments=False)))' "${EXTRA:-}")

slug=$(echo "${TITLE:-track}" | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null | tr -cs 'A-Za-z0-9' '_' | sed 's/^_//; s/_$//')
[[ -n "$slug" ]] || slug=track
theme="${THEME:-wood}"
fmt="${FORMAT:-landscape}"

case "${OUTPUT:-mp4}" in
    png)
        python3 "$HERE/gpx2map/gpx2map.py" "${args[@]}" --theme "$theme" --format "$fmt" "${extra[@]}"
        for f in "$WORK"/*.png; do mv "$f" "$OUT/${slug}_$(basename "$f" | sed 's/^[0-9]*_//')"; done
        ;;
    gif|mp4)
        [[ "$fmt" == "auto" ]] && fmt=landscape
        python3 "$HERE/gpx2anim/gpx2anim.py" "${args[@]}" --theme "$theme" --format "$fmt" "${extra[@]}" \
            -o "$OUT/${slug}_${fmt}_${theme}.${OUTPUT}"
        ;;
    *)
        echo "::error::unknown output '$OUTPUT'"; exit 1 ;;
esac

echo "Results:"
ls -la "$OUT"
if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    {
        echo "### Result"
        echo
        for f in "$OUT"/*; do echo "- \`$(basename "$f")\` ($(du -h "$f" | cut -f1))"; done
        echo
        echo "Download it from the **Artifacts** box of this run (kept 7 days)."
    } >> "$GITHUB_STEP_SUMMARY"
fi
