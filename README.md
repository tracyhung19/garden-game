# Zi Garden

A Chinese word game for a Primary 1 learner. Each word is a plant that grows with spaced-repetition practice. A grown-ups corner holds the word list, uploaded recordings and a before-the-visit summary.

Single self-contained page: open `index.html` in a browser, or host it as a static file (for example GitHub Pages). Progress and recordings stay in the browser on the device where she plays.

## Mobile fit and install

`index.html` is a full document with a mobile viewport tag, safe-area padding, theme colours and a web manifest, so on a phone it lays out at device width and can be added to the Home Screen as a full-screen app (Chrome: ⋮ → Add to Home screen or Install app). The Android Back gesture returns from a round or the Grown-ups corner to the garden instead of leaving the game.

The Claude artifact copy needs a stripped fragment. Rebuild it with `python3 scripts/build-artifact.py <output>`.

Design review: the page was checked against Vercel's Web Interface Guidelines (https://github.com/vercel-labs/web-interface-guidelines): focus states, touch targets, labels and autocomplete on inputs, reduced motion, safe areas, colour-scheme and theme-color, heading order, and `lang="zh-Hans"` on Chinese text so Android picks Simplified Chinese glyphs.

## Hosting

The game is one static file, so any static host works. With GitHub Pages: Settings → Pages → Deploy from a branch → `main` / root. It is then served at `https://tracyhung19.github.io/garden-game/`.

## Trial log

While `Keep the trial log` is on (Grown-ups → Trial log), the game keeps a private event log in the browser (`zigarden.log.v1`): questions shown, taps, answer times, wrong picks, replays, silent audio failures, errors, notes and ⚑ flags. It holds no recordings and no names. To share it, open Grown-ups → Trial log → Copy trial log and paste the text to Claude. The log is separate from the backup and is not touched by Reset progress.

## Where data lives

- Words, progress, the play log and settings: `localStorage` (key `zigarden.v1`) in the browser that plays the game.
- Uploaded recordings: IndexedDB (database `zigarden`) in the same browser.
- Nothing is sent to a server. Each device and browser keeps its own separate copy, and a new web address starts empty.
- Use Grown-ups → Settings → Backup to copy progress and recordings as text. Paste it into the game on another device and choose Restore to move everything there.
- In-page recording (Grown-ups → Words & sounds → Record) needs the game on its own web address; inside a Claude artifact the microphone is blocked.
- On iPad/iPhone Safari, add the page to the Home Screen: Safari can clear site data for sites not visited for 7 days, and Home Screen web apps are exempt.
