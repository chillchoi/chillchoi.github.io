# Justin Joonseo Choi — Portfolio System

Live: **https://chillchoi.github.io** (main site) · **https://chillchoi.github.io/artportfolio/** (art gallery)

This file is the handoff guide. Everything about the site lives in two GitHub repos, so cloning them replicates the whole system.

## The two repositories (this is the entire system)
- **chillchoi.github.io** — the main site (home · work · photography · about · contact). One self-contained file: `index.html`. All photos live in `photos/`.
- **artportfolio** — the interactive art gallery, served at `/artportfolio/`. One file: `index.html`.

Both auto-deploy via GitHub Pages when you push to `main`.

## Layout of this repo
- `index.html` — the whole site (HTML + CSS + JS in one file, no build step, only Google Fonts loaded).
- `photos/<place>/NN.jpg` — photography, numbered two digits (`01.jpg`, `02.jpg`, …). Places: `capecod`, `chicago`, `japan`, `hawaii`, `california`, `seoul`.
- `photos/work/*.jpg` — work thumbnails (fixed names, referenced directly in the code — don't rename these).
- `photos/p-*.jpg` — home + section backdrops.
- `photos/counts.js` — auto-generated; tells the site the highest photo number per place. Rewritten by the publish script.
- `update-website.command` — double-click helper (macOS) that optimizes/numbers new photos and publishes.
- `.gitignore` — ignores `.DS_Store`.

## How photos work (the important part)
- The page shows `photos/<place>/01.jpg … NN.jpg`, where NN comes from `counts.js`. Any missing number is skipped automatically — no broken tiles.
- **Add photos:** drop any images (any filename, iPhone `.HEIC`, big camera `.JPG`, `.png`) into `photos/<place>/`, then publish. The script resizes them to ~1400px, renames them to the next number, removes exact duplicates, and rewrites `counts.js`.
- **Delete photos:** drag to Trash, then publish.
- You never renumber by hand.

## Publishing
Double-click **`update-website.command`** (macOS), or in **GitHub Desktop** select this repo and click Push. Live in ~1 minute (hard-refresh with Cmd+Shift+R to skip the cache).

## Design notes (for whoever continues this)
- Keep it single-file and dependency-free. Only external thing is Google Fonts.
- Photography is six "issues," each with its own font, palette, and background texture/pattern drawn on a `.loc-atmos` layer behind the photos: California (film grain + amber road ruler), Cape Cod (fog + tide rings + dotted spine), Chicago (red survey grid), Hawaii (pure black + thick coral photo frames), Japan (vermilion registration marks + keyline frames), Seoul (riso newsprint + blue halftone dots). The titles and the photo grid are never touched by these.
- Scroll parallax: each photo drifts vertically inside a fixed frame (`photoParallax` in the JS).
- Side rail on the photography page tracks which issue you're in; hidden until you scroll past the PHOTOGRAPHY masthead.
- Footer: giant JUSTIN JOONSEO CHOI that cycles through the seven display fonts, pauses on hover, click returns home, and adopts the color + texture of whatever section sits above it. The art gallery has the same footer in a blue-gradient theme.
- Aesthetic: cool, editorial, masculine. Public copy is NDA-safe (consulting client names genericized). No em-dashes in copy.

## Replicate on a new laptop / new Claude account
1. Install **GitHub Desktop** and sign in to the GitHub account that owns these repos (`chillchoi`).
2. Clone **both** repos into `~/Documents/GitHub/` (the paths matter — the publish script expects `~/Documents/GitHub/chillchoi.github.io`):
   - `https://github.com/chillchoi/chillchoi.github.io`
   - `https://github.com/chillchoi/artportfolio`
3. (For the AI workflow) Open the Claude desktop app on the new machine, sign into your Claude account, turn on Cowork, and **connect these two folders** as workspaces.
4. Point the new Claude at this README, and continue where you left off.

Because the whole website (code + photos) is in these two git repos, cloning them = replicating everything.

> The `FRIDAY` folder (job-search assistant, résumé format, etc.) is a **separate** system and is not in these repos. If you want that too, copy that folder to the new machine separately, or give it its own git repo.
