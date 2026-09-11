#!/usr/bin/env bash
# Fetch the GPX file(s) into a folder, as 01.gpx, 02.gpx...
#
#   fetch_gpx.sh "<gist id>" work            gist made by the web form: gzip + base64, in parts
#   fetch_gpx.sh "https://... https://..." work   one or several URLs (Dropbox and Google Drive
#                                                 share links are turned into direct downloads)
set -euo pipefail
SRC="${1:?gpx source}"
DEST="${2:-work}"
mkdir -p "$DEST"

direct_url() {
    local u="$1"
    # Dropbox share link -> direct download
    if [[ "$u" == *dropbox.com* ]]; then
        u="${u/\?dl=0/?dl=1}"; u="${u/&dl=0/&dl=1}"
        [[ "$u" == *dl=1* ]] || u="$u?dl=1"
    fi
    # Google Drive "file/d/<id>/view" -> uc?export=download
    if [[ "$u" =~ drive\.google\.com/file/d/([^/]+) ]]; then
        u="https://drive.google.com/uc?export=download&id=${BASH_REMATCH[1]}"
    fi
    echo "$u"
}

check_gpx() {
    if ! head -c 4096 "$1" | grep -qi "<gpx"; then
        echo "::error::$1 does not look like a GPX file"; head -c 300 "$1"; echo; exit 1
    fi
    echo "  $1: $(du -h "$1" | cut -f1)"
}

if [[ "$SRC" =~ ^[0-9a-f]{20,40}$ ]]; then
    echo "Gist $SRC"
    # secret gists are readable by id without authentication
    curl -fsSL -H "Accept: application/vnd.github+json" "https://api.github.com/gists/$SRC" > "$DEST/gist.json"
    python3 - "$DEST" <<'EOF'
import json, os, re, subprocess, sys
dest = sys.argv[1]
g = json.load(open(os.path.join(dest, "gist.json")))
files = g["files"]
# form layout: NN_name.gpx.gz.b64.partMMM  (gzip, base64, 900 kB parts); plain .gpx also accepted
groups = {}
for name, f in files.items():
    m = re.match(r"^(\d+)_.*\.part(\d+)$", name)
    key = m.group(1) if m else name
    groups.setdefault(key, []).append((m.group(2) if m else "000", f["raw_url"], name))
for i, key in enumerate(sorted(groups), 1):
    parts = sorted(groups[key])
    out = os.path.join(dest, f"{i:02d}.gpx")
    if parts[0][2].endswith(".gpx"):
        subprocess.check_call(["curl", "-fsSL", "-o", out, parts[0][1]])
    else:
        b64 = os.path.join(dest, f"{i:02d}.b64")
        with open(b64, "wb") as fh:
            for _, url, _ in parts:
                fh.write(subprocess.check_output(["curl", "-fsSL", url]))
        with open(out, "wb") as fh:
            gz = subprocess.check_output(["base64", "-d", b64])
            fh.write(subprocess.run(["gunzip", "-c"], input=gz, check=True, stdout=subprocess.PIPE).stdout)
        os.remove(b64)
    print("  rebuilt", out, "from", len(parts), "part(s)")
EOF
    rm -f "$DEST/gist.json"
else
    i=0
    for u in $SRC; do
        i=$((i + 1))
        out=$(printf "%s/%02d.gpx" "$DEST" "$i")
        url=$(direct_url "$u")
        echo "Download $url"
        curl -fsSL -A "gpx2server" -o "$out" "$url"
    done
fi

shopt -s nullglob
files=("$DEST"/*.gpx)
[[ ${#files[@]} -gt 0 ]] || { echo "::error::no GPX fetched"; exit 1; }
for f in "${files[@]}"; do check_gpx "$f"; done
