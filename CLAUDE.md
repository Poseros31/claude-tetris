# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Classic Tetris implemented in vanilla JavaScript with HTML5 Canvas — no dependencies, no build step, no package manager. The entire game is 3 files.

## Running / testing

There is no build, lint, or test tooling (no `package.json`). To run the game:

```bash
open index.html        # macOS
xdg-open index.html    # Linux
```

Or serve it locally (needed if a browser blocks local file access for canvas/assets):

```bash
python3 -m http.server 8000
# then open http://localhost:8000
```

Verify changes by opening the page and playing: check piece movement, rotation (including wall kicks near the edges), line clearing, scoring, level speed-up, pause, and game over/restart.

## Architecture

Three files, each with one responsibility:

- **`index.html`** — DOM structure only: the `board` canvas (300×600, i.e. `COLS×BLOCK` × `ROWS×BLOCK`), the `next-canvas` preview, HUD spans (`score`/`lines`/`level`), and the pause/game-over `overlay`.
- **`style.css`** — dark/retro visual theme (flexbox layout, `backdrop-filter` overlay).
- **`game.js`** — all game logic, single global scope, no modules.

### Core model (`game.js`)

- `board`: a `ROWS × COLS` matrix; each cell is `0` (empty), a piece-color index `1–8`, or `-1` (solid-but-invisible hole cell — see below).
- `PIECES`: the 7 classic tetrominoes plus an 8th 3×3 "tuerca" (nut) piece with a `-1` marker at its center; square matrices; `COLORS[i]` gives the fill color for index `i`.
- The `-1` hole marker is truthy, so `collide()`/`merge()`/`clearLines()` treat it as solid/filled with no code changes — only `drawBlock()` special-cases it (`colorIndex <= 0` skips painting), leaving the board background visible through the nut's center once it locks.
- `current` / `next`: `{ type, shape, x, y }` — `next` is generated ahead of time and swapped in by `spawn()`.
- Rotation is done by matrix transpose+reverse (`rotateCW`), not by lookup tables.
- `tryRotate()` implements wall kicks by retrying the rotated shape at x-offsets `[0, -1, 1, -2, 2]` until one doesn't collide.
- `collide(shape, ox, oy)` is the single collision check used by movement, rotation, and ghost-piece projection — reuse it rather than writing new bounds/overlap checks.
- Game loop (`loop`) uses `requestAnimationFrame`, accumulating `dt` and dropping the piece once `dropAccum >= dropInterval`.
- `lockPiece()` → `merge()` (bake piece into `board`) → `clearLines()` → `spawn()` next piece. If the newly spawned piece immediately collides, `endGame()` fires.
- Scoring: `LINE_SCORES = [0, 100, 300, 500, 800]` × `level`; hard drop = 2 pts/row traveled, soft drop = 1 pt/row.
- Level = `floor(lines / 10) + 1`; `dropInterval = max(100, 1000 - (level-1)*90)` ms.
- Rendering (`draw`) redraws the whole board every frame: grid → locked blocks → ghost piece (`globalAlpha = 0.2`, position from `ghostY()`) → current piece. `drawNext()` renders the preview canvas the same way.

### Tunable constants (top of `game.js`)

`COLS`, `ROWS`, `BLOCK`, `COLORS`, `LINE_SCORES`, `dropInterval`. If `COLS`/`ROWS`/`BLOCK` change, update the `board` canvas `width`/`height` in `index.html` to match (`COLS×BLOCK`, `ROWS×BLOCK`).

## Notes

- README is in Spanish; comments/HUD strings ("Reiniciar", "PAUSA") are Spanish — match that language for user-facing text.
- Keep everything framework-free and single-file-per-concern; don't introduce a bundler/build step for a project whose whole point is "open and play."
