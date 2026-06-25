#!/usr/bin/env python3
"""
Generates Hebrew TTS audio using edge-tts (Microsoft neural voices).
Writes MP3s to Audio.bundle/hebrew/ in both iOS and Watch targets.
Usage: python3 generate_hebrew_audio.py [start] [end]
Safe to re-run — skips already generated files.
"""
import asyncio, json, re, sys
from pathlib import Path

BASE      = Path(__file__).parent / "YetAnotherLearningCards/YetAnotherLearningCards"
JSON_PATH = BASE / "hebrew_cards.json"
OUT_DIR   = BASE / "Audio.bundle/hebrew"
WATCH_OUT = BASE.parent / "YetAnotherLearningCards Watch App/Audio.bundle/hebrew"
VOICE     = "he-IL-HilaNeural"

OUT_DIR.mkdir(parents=True, exist_ok=True)
WATCH_OUT.mkdir(parents=True, exist_ok=True)

try:
    import edge_tts
except ImportError:
    print("Run: pip3 install edge-tts")
    sys.exit(1)

with open(JSON_PATH, encoding="utf-8") as f:
    cards = json.load(f)

start = int(sys.argv[1]) if len(sys.argv) > 1 else 0
end   = int(sys.argv[2]) if len(sys.argv) > 2 else len(cards)

async def generate(i: int, text: str):
    mp3_path = OUT_DIR / f"hebrew_{i}.mp3"
    if mp3_path.exists():
        return False
    comm = edge_tts.Communicate(text, VOICE)
    await comm.save(str(mp3_path))
    watch_path = WATCH_OUT / f"hebrew_{i}.mp3"
    watch_path.write_bytes(mp3_path.read_bytes())
    return True

async def main():
    done = skipped = errors = 0
    for i in range(start, end):
        text = cards[i]["front"]
        try:
            generated = await generate(i, text)
            if generated:
                done += 1
                if done % 100 == 0:
                    print(f"[{i+1}] Generated {done} files...")
            else:
                skipped += 1
                if skipped % 500 == 0:
                    print(f"[{i+1}] Skipping {skipped} already done...")
        except Exception as e:
            print(f"Error at {i} ({text!r}): {e}")
            errors += 1
            await asyncio.sleep(2)

    print(f"Done: {done} generated, {skipped} skipped, {errors} errors (range {start}-{end})")

asyncio.run(main())
