# Zi Garden

A Chinese word game for a Primary 1 learner. Each word is a plant that grows with spaced-repetition practice. A grown-ups corner holds the word list, uploaded recordings and a before-the-visit summary.

Single self-contained page: open `index.html` in a browser, or host it as a static file (for example GitHub Pages). Progress and recordings stay in the browser on the device where she plays.

## Hosting

The game is one static file, so any static host works. With GitHub Pages: Settings → Pages → Deploy from a branch → `main` / root. It is then served at `https://tracyhung19.github.io/garden-game/`.

## Where data lives

- Words, progress, the play log and settings: `localStorage` (key `zigarden.v1`) in the browser that plays the game.
- Uploaded recordings: IndexedDB (database `zigarden`) in the same browser.
- Nothing is sent to a server. Each device and browser keeps its own separate copy, and a new web address starts empty.
- Use Grown-ups → Settings → Backup to copy progress and recordings as text. Paste it into the game on another device and choose Restore to move everything there.
- In-page recording (Grown-ups → Words & sounds → Record) needs the game on its own web address; inside a Claude artifact the microphone is blocked.
- On iPad/iPhone Safari, add the page to the Home Screen: Safari can clear site data for sites not visited for 7 days, and Home Screen web apps are exempt.
