#!/usr/bin/env python3
"""Recover genuine HaeSiivooja app screenshots from retained WordPress uploads.

Run on the HaeSiivooja Ubuntu VPS, BEFORE building Astro:
    python3 scripts/restore-wordpress-app-images.py --scan
    python3 scripts/restore-wordpress-app-images.py --apply

Optional: if auto-selection misses the original screenshots, use --select:
    python3 scripts/restore-wordpress-app-images.py --scan --select '*mobile*,*screenshot*'
    python3 scripts/restore-wordpress-app-images.py --apply --select 'MyScreen1.png,MyScreen2.png'

Original WordPress images are read-only. Copies land in public/app-screenshots/
and the local, gitignored manifest src/data/app-screenshots.local.json.
"""
from __future__ import annotations
import argparse
import fnmatch
import hashlib
import json
import re
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path

try:
    from PIL import Image, UnidentifiedImageError
except ImportError:
    print("Missing Pillow. Install with: sudo apt-get install -y python3-pil", file=sys.stderr)
    sys.exit(2)

ROOT = Path(__file__).resolve().parent.parent
DEST = ROOT / "public" / "app-screenshots"
MANIFEST = ROOT / "src" / "data" / "app-screenshots.local.json"
KNOWN = [
    Path("/var/www/html/wp-content/uploads"),
    Path("/var/www/html/wordpress/wp-content/uploads"),
]
EXTS = {".png", ".jpg", ".jpeg", ".webp"}
SCREENS = ("screenshot", "screen-shot", "screen_", "screencap", "kuvakaappaus",
           "sovellusnakyma", "sovellusnäkymä", "appscreen", "app-screen",
           "app_screen", "puhelin", "mobile-screen")
APP = ("haesiivooja", "hae-siivooja", "cleanerfinder", "app", "android",
       "iphone", "ios", "mobiili", "sovellus", "mobile", "varaus", "booking")
STOCK = ("pexels", "unsplash", "shutterstock", "adobestock", "istock",
         "depositphotos", "pixabay", "wp-logo", "avatar", "favicon",
         "icon-", "logo-", "hero-cleaner", "cleaning-lady")
THUMB = re.compile(r"-\d{2,4}x\d{2,4}(?=\.[a-z]{3,4}$)", re.I)

@dataclass
class Candidate:
    path: Path
    score: int
    width: int
    height: int

def sources(user_source: str | None) -> list[Path]:
    if user_source:
        p = Path(user_source).expanduser()
        return [p] if p.is_dir() else []
    return [p for p in KNOWN if p.is_dir()]

def candidates(root: Path, selects: list[str]) -> list[Candidate]:
    found = []
    for p in root.rglob("*"):
        if not p.is_file() or p.suffix.lower() not in EXTS or THUMB.search(p.name):
            continue
        name = p.name.lower()
        if any(t in name for t in STOCK) and not selects:
            continue
        explicit = bool(selects and any(fnmatch.fnmatch(name, pat) for pat in selects))
        if selects and not explicit:
            continue
        try:
            with Image.open(p) as img:
                w, h = img.size
                img.verify()
        except (UnidentifiedImageError, OSError, ValueError):
            continue
        if w < 300 or h < 420 or (p.stat().st_size > 18 * 1024 * 1024):
            continue
        ratio = h / w
        score = 0
        if any(term in name for term in SCREENS):
            score += 10
        if any(term in name for term in APP):
            score += 5
        if 1.45 <= ratio <= 2.8:
            score += 8  # Portrait phone screen
        elif ratio >= 1.20:
            score += 3
        if h >= 700:
            score += 2
        if p.suffix.lower() in (".png", ".webp"):
            score += 1
        if "2026" in str(p):
            score += 1
        if explicit:
            score += 100
        if score < 8:
            continue
        found.append(Candidate(p, score, w, h))
    return found

def main() -> int:
    ap = argparse.ArgumentParser()
    action = ap.add_mutually_exclusive_group(required=True)
    action.add_argument("--scan", action="store_true", help="Show candidate originals, do not copy")
    action.add_argument("--apply", action="store_true", help="Copy selected originals and write gallery manifest")
    ap.add_argument("--source", help="Original WordPress uploads directory")
    ap.add_argument("--select", help="Optional comma-separated original filenames/globs")
    ap.add_argument("--max", type=int, default=8, help="Max images to publish, default 8")
    args = ap.parse_args()
    roots = sources(args.source)
    if not roots:
        print("No WordPress uploads found. Inspect: /var/www/html/wp-content/uploads and /var/www/html/wordpress/wp-content/uploads", file=sys.stderr)
        return 2
    patterns = [x.strip().lower() for x in (args.select or "").split(",") if x.strip()]
    discovered = [item for root in roots for item in candidates(root, patterns)]
    # Prefer likely screenshots, and avoid exact duplicates and WordPress auto-generated sizes.
    discovered.sort(key=lambda x: (-x.score, -x.height, str(x.path)))
    unique: list[Candidate] = []
    digests: set[str] = set()
    for item in discovered:
        checksum = hashlib.sha256(item.path.read_bytes()).hexdigest()
        if checksum in digests:
            continue
        digests.add(checksum)
        unique.append(item)
    chosen = unique[:max(1, min(args.max, 12))]
    print("Original WordPress image directories:", ", ".join(map(str, roots)))
    for i, item in enumerate(unique[:25], 1):
        selected = "OMIT" if i in (4,5) else ("SELECTED" if i <= len(chosen) else "candidate")
        print(f"{selected:9} {i:02} | {item.width:4}x{item.height:<4} | score {item.score:2} | {item.path}")
    if not chosen:
        print("No app screenshots confidently detected. Try --scan --select '*app*,*mobile*,*screenshot*' or provide exact filenames.", file=sys.stderr)
        return 1
    if args.scan:
        print(f"DRY RUN: {len(chosen)} image(s) would be copied. Check the filenames before applying.")
        return 0
    DEST.mkdir(parents=True, exist_ok=True)
    # Retain unrelated files and only replace the gallery files created by this script.
    for old in DEST.glob("app-screen-*"):
        if old.is_file():
            old.unlink()
    manifest=[]
    for i, item in enumerate(chosen, 1):
        if i in (4, 5):
            continue  # Exclude explicitly rejected screens 4 and 5.
        extension = ".jpg" if item.path.suffix.lower() == ".jpeg" else item.path.suffix.lower()
        name=f"app-screen-{i:02}{extension}"
        shutil.copy2(item.path, DEST / name)
        manifest.append({
          "src": f"/app-screenshots/{name}",
          "altFi": f"HaeSiivooja-mobiilisovelluksen näkymä {i}",
          "altEn": f"HaeSiivooja mobile app interface {i}"
        })
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    temp = MANIFEST.with_name(MANIFEST.name + ".tmp")
    temp.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temp.replace(MANIFEST)
    print(f"IMPORTED {len(manifest)} application images to {DEST} (screens 4 and 5 omitted)")
    print(f"Local gallery manifest: {MANIFEST}")
    print("Now run npm run check, npm run predeploy, and prepare/activate a fresh Astro release.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
