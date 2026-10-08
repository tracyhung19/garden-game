#!/usr/bin/env python3
"""Build the files for the Claude artifact copy of the site.

The artifact publisher wraps the main page in its own document shell and only allows
a few external hosts, so this script:
  - turns index.html (landing page) into a fragment: no <html>/<head>/<body>, no viewport,
    theme-color or PWA tags
  - inlines theme.css into every page
  - copies garden.html, tingxie.html and vendor/ unchanged otherwise

Usage: python3 scripts/build-artifact.py <output-dir>
Then publish <output-dir>/index.html as the page and the other files through `files`.
"""
import re, sys, pathlib, shutil

root = pathlib.Path(__file__).resolve().parent.parent
out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "artifact-build")
out.mkdir(parents=True, exist_ok=True)
theme = (root / "theme.css").read_text(encoding="utf-8")

def inline_theme(html):
    return html.replace('<link rel="stylesheet" href="theme.css">', "<style>\n" + theme + "\n</style>")

def strip_pwa(html):
    return re.sub(r"<!--pwa-->.*?<!--/pwa-->\n?", "", html, flags=re.S)

# landing page as a fragment
s = inline_theme(strip_pwa((root / "index.html").read_text(encoding="utf-8")))
head = re.search(r"<head>(.*?)</head>", s, re.S).group(1)
body = re.search(r"<body[^>]*>(.*?)</body>", s, re.S).group(1)
head = re.sub(r"<meta (charset|name=\"(viewport|color-scheme|theme-color|description)\")[^>]*>\n?", "", head)
(out / "index.html").write_text(head.strip() + "\n<script>document.body.classList.add('hasnav')</script>\n" + body.strip() + "\n", encoding="utf-8")

# other pages stay full documents
for name in ("garden.html", "tingxie.html"):
    (out / name).write_text(inline_theme(strip_pwa((root / name).read_text(encoding="utf-8"))), encoding="utf-8")

(out / "vendor").mkdir(exist_ok=True)
shutil.copy(root / "vendor" / "hanzi-writer.min.js", out / "vendor" / "hanzi-writer.min.js")
print("built", ", ".join(sorted(p.name for p in out.iterdir())), "in", out)
