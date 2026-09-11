# gpx2server

Render a GPX hike **online**, without installing anything: a web form on GitHub Pages sends the
GPX and your choices to a GitHub Actions workflow, which runs
[gpx2map](https://github.com/YannickRiou/gpx2map) (themed PNG) or
[gpx2anim](https://github.com/YannickRiou/gpx2anim) (GIF / MP4, 16:9, square or vertical) and
hands the result back as a downloadable artifact. Free on a GitHub Free account: the repository
is public, so the Actions minutes are unlimited.

```
browser (GitHub Pages form) ──gist──▶ GitHub Actions (ubuntu runner) ──▶ artifact (PNG / GIF / MP4)
        │                                     │
        └── dispatches the workflow           └── gpx2map / gpx2anim / gpx2core, IGN data
```

## How the GPX travels

A static page cannot store a file and a workflow input is limited to a few kilobytes, so the form
gzips the GPX in the browser (a 14 MB track becomes about 1.5 MB), base64-encodes it, splits it
in 900 kB parts and creates a **secret gist** with them. The workflow rebuilds the file from the
gist, renders, and the page **deletes the gist** as soon as the run is over. Nothing is ever
committed to this repository; the artifact is kept 7 days.

You can also skip the form: run the workflow from the **Actions** tab with URL(s) of the GPX
(Dropbox and Google Drive share links are accepted).

## Setting it up (once)

1. **Fork or create the repository** with the two submodules, then enable **GitHub Pages**:
   Settings → Pages → *Deploy from a branch* → `main`, folder `/docs`. The form is then at
   `https://<user>.github.io/gpx2server/`.
2. **Create a personal access token** (classic) at Settings → Developer settings → Personal access
   tokens, with the scopes `repo` (to dispatch the workflow) and `gist` (to upload the GPX).
   Paste it in the form; tick *Remember* to keep it in your browser's local storage only.
   The token never leaves your browser except towards `api.github.com`.
3. Open the page, choose a GPX, a title, PNG or MP4 or GIF, a theme, and press **Render**.
   The page follows the run and links to it when done; the file is in the run's *Artifacts* box.

Cloning for local work needs the submodules: `git clone --recursive`.

## Workflow inputs

| Input | Default | Meaning |
|---|---|---|
| `gpx` | | URL(s) separated by spaces, or the id of a gist made by the form |
| `output` | `mp4` | `png`, `gif` or `mp4` |
| `title` | track name | engraved title |
| `lang` | `en` | `en` or `fr`; keep it in the language of the title |
| `theme` | `wood` | any gpx2map theme; several with commas for `png` |
| `format` | `landscape` | `auto` (png only), `landscape`, `square`, `portrait` |
| `summit` | `true` | highest point in the title |
| `extra` | | anything gpx2map / gpx2anim accepts: `--track-smooth 8 --despike 10 --speed 1.5 --fps 24 --dpi 200 --track-color #DBE64C --water osm --distance 12.4`… |

The form composes `extra` from its fields (dpi, fps, drawing time or pace, hold times,
smoothing, despike) and shows the equivalent command line.

## What a run costs

About 1 to 2 minutes to install the dependencies (pip cache), a few seconds for the IGN
elevation model (cached between runs), then 1 minute for a PNG or 2 to 4 minutes for a 15 s
MP4 at 1080p. Fonts (Funnel Display and Mulish, Google Fonts) are fetched and cached on the
first run; without network to Google Fonts the runner's DejaVu is used.

## Files

| Path | Role |
|---|---|
| `.github/workflows/render.yml` | the workflow: checkout with submodules, Python 3.12, caches, fetch, render, upload |
| `scripts/fetch_gpx.sh` | URL(s) or gist → `work/01.gpx`, `02.gpx`… |
| `scripts/render.sh` | builds the gpx2map / gpx2anim command from the inputs, collects `out/` |
| `scripts/fonts.sh` | downloads the variable fonts and instances the static weights the engine expects |
| `docs/index.html` | the form (GitHub Pages) |
| `gpx2map/`, `gpx2anim/` | submodules, each with its own `core/` submodule (gpx2core) |

## Privacy

The repository is public, so: the GPX never lands in it, the gist is secret (not listed, only
reachable by its id) and deleted after the run, the run log shows file sizes but not coordinates,
and the artifact is only downloadable by people with access to the repository's Actions (you).
If you would rather keep even that private, make the repository private: the same setup works
within the 2 000 free minutes per month.

## Licence

MIT.
