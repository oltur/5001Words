#!/usr/bin/env python3
"""Generate German TTS audio using macOS `say` + lame.
Writes MP3s to Audio.bundle/german/ in both iOS and Watch targets.
Usage: python3 generate_german_audio.py [start] [end]
"""
import json, re, subprocess, sys, os, tempfile, shutil
from pathlib import Path

BASE = Path(__file__).parent / "YetAnotherLearningCards/YetAnotherLearningCards"
JSON_PATH = BASE / "german_cards.json"
OUT_DIR   = BASE / "Audio.bundle/german"
WATCH_OUT = BASE.parent / "YetAnotherLearningCards Watch App/Audio.bundle/german"
VOICE     = "Petra (Premium)"

OUT_DIR.mkdir(exist_ok=True)
WATCH_OUT.mkdir(parents=True, exist_ok=True)

def extract_text(front: str) -> str:
    return re.sub(r'\s*\([^)]+\)\s*$', '', front).strip()

with open(JSON_PATH, encoding="utf-8") as f:
    cards = json.load(f)

start = int(sys.argv[1]) if len(sys.argv) > 1 else 0
end   = int(sys.argv[2]) if len(sys.argv) > 2 else len(cards)

total = end - start
done = 0
skipped = 0

for i in range(start, end):
    card = cards[i]
    mp3_path = OUT_DIR / f"german_{i}.mp3"

    if mp3_path.exists():
        skipped += 1
        if skipped % 500 == 0:
            print(f"[{i+1}] Skipping {skipped} already generated...")
        continue

    text = extract_text(card["front"])

    with tempfile.NamedTemporaryFile(suffix=".aiff", delete=False) as tmp:
        tmp_path = tmp.name

    try:
        subprocess.run(["say", "-v", VOICE, "-o", tmp_path, text],
                       check=True, capture_output=True)
        subprocess.run(["lame", "--quiet", "-V4", tmp_path, str(mp3_path)],
                       check=True, capture_output=True)
        shutil.copy2(str(mp3_path), WATCH_OUT / f"german_{i}.mp3")
        done += 1
        if (i + 1) % 100 == 0:
            print(f"[{i+1}] Generated {done} files in this batch...")
    except subprocess.CalledProcessError as e:
        print(f"Error at index {i} ({text!r}): {e}")
    finally:
        try:
            os.unlink(tmp_path)
        except Exception:
            pass

print(f"Done: {done} generated, {skipped} skipped (range {start}-{end})")
