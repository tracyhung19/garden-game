#!/usr/bin/env python3
"""Turn index.html into the fragment the Claude artifact publisher expects.

The publisher wraps a page in its own <!doctype>/<head>/<body>, so this strips the
document shell, the viewport/charset/theme meta tags and the PWA links, and keeps
the title, fonts, styles, body content and script.

Usage: python3 scripts/build-artifact.py [output-path]
"""
import re, sys, pathlib

src = pathlib.Path(__file__).resolve().parent.parent / "index.html"
out = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "zi-garden.artifact.html")
s = src.read_text(encoding="utf-8")

head = re.search(r"<head>(.*?)</head>", s, re.S).group(1)
body = re.search(r"<body>(.*?)</body>", s, re.S).group(1)
head = re.sub(r"<!--pwa-->.*?<!--/pwa-->\n?", "", head, flags=re.S)
head = re.sub(r"<meta (charset|name=\"(viewport|color-scheme|theme-color|description)\")[^>]*>\n?", "", head)
out.write_text(head.strip() + "\n" + body.strip() + "\n", encoding="utf-8")
print(f"wrote {out} ({out.stat().st_size} bytes)")
