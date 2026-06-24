#!/usr/bin/env python3
"""Generate Dutch TTS audio using macOS `say` + lame.
Writes MP3s to DutchAudio/ and updates dutch_cards.json with audioIndex.
"""
import json, re, subprocess, sys, os, tempfile
from pathlib import Path

BASE = Path(__file__).parent / "YetAnotherLearningCards/YetAnotherLearningCards"
JSON_PATH = BASE / "dutch_cards.json"
OUT_DIR   = BASE / "Audio.bundle/dutch"
WATCH_OUT = BASE.parent / "YetAnotherLearningCards Watch App/Audio.bundle/dutch"
VOICE     = "Xander"   # nl_NL

OUT_DIR.mkdir(exist_ok=True)
WATCH_OUT.mkdir(exist_ok=True)

def extract_text(front: str) -> str:
    """Strip grammatical label like (adj), (v), (nm), (expr) etc."""
    return re.sub(r'\s*\([^)]+\)\s*$', '', front).strip()

with open(JSON_PATH, encoding="utf-8") as f:
    cards = json.load(f)

total = len(cards)
updated = 0
skipped = 0

for i, card in enumerate(cards):
    mp3_path = OUT_DIR / f"dutch_{i}.mp3"

    if mp3_path.exists():
        card["audioIndex"] = i
        skipped += 1
        if skipped % 500 == 0:
            print(f"[{i+1}/{total}] Skipping already generated files...")
        continue

    text = extract_text(card["front"])

    with tempfile.NamedTemporaryFile(suffix=".aiff", delete=False) as tmp:
        tmp_path = tmp.name

    try:
        subprocess.run(
            ["say", "-v", VOICE, "-o", tmp_path, text],
            check=True, capture_output=True
        )
        subprocess.run(
            ["lame", "--quiet", "-V4", tmp_path, str(mp3_path)],
            check=True, capture_output=True
        )
        # Copy to Watch target
        watch_mp3 = WATCH_OUT / f"dutch_{i}.mp3"
        import shutil
        shutil.copy2(str(mp3_path), str(watch_mp3))

        card["audioIndex"] = i
        updated += 1

        if (i + 1) % 100 == 0:
            # Save progress checkpoint
            with open(JSON_PATH, "w", encoding="utf-8") as f:
                json.dump(cards, f, ensure_ascii=False, indent=2)
            print(f"[{i+1}/{total}] Generated {updated} new, skipped {skipped}", flush=True)

    except subprocess.CalledProcessError as e:
        print(f"[{i+1}/{total}] ERROR on '{text}': {e}", file=sys.stderr)
        card["audioIndex"] = None
    finally:
        try:
            os.unlink(tmp_path)
        except Exception:
            pass

# Final save
with open(JSON_PATH, "w", encoding="utf-8") as f:
    json.dump(cards, f, ensure_ascii=False, indent=2)

print(f"\nDone! Generated {updated} new files, skipped {skipped} existing. Total: {total}")
