# Zi Garden

A Chinese word game for a Primary 1 learner. Each word is a plant that grows with spaced-repetition practice. A grown-ups corner holds the word list, uploaded recordings and a before-the-visit summary.

Single self-contained page: open `index.html` in a browser, or host it as a static file (for example GitHub Pages). Progress and recordings stay in the browser on the device where she plays.

## 听写 spelling test practice (`tingxie.html`)

A second page, linked from a card on the garden. Add the week's word list and the test day; the page plans the days left, runs practice (look, cover, write on paper, check) and a mock test, and marks each character in 田字格 boxes. Words move through New, Missed, Getting there and Ready; Ready means right on two different days and not missed since. After the real test, enter the result and add the words to the garden, where they keep being reviewed. Recordings made in the garden's Words & sounds play here for the same words. Data lives in `zitingxie.v1` and its own trial log in `zitingxie.log.v1`. Stroke order and on-screen writing use Hanzi Writer (vendored in `vendor/`, MIT). In the Look step she watches each character being drawn and can trace it over a grey outline. In the Write step a grown-up can switch from paper to the screen: she draws each character stroke by stroke, the page checks every stroke against the correct order and shape, and the check step is pre-filled from the result (more than 2 slips, or a skipped character, counts as wrong; a grown-up can still change any mark). Mock tests give no hints. Stroke data (one small file per character) is fetched once from jsDelivr and kept in the browser, so the first use of a new list needs a web connection. This works on the GitHub Pages address; inside a Claude artifact the data fetch is blocked, so the page falls back to paper. Pencil on paper cannot be read, so on paper a grown-up marks the writing. See `vendor/NOTICE.md` for licences.

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
