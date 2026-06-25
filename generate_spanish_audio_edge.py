#!/usr/bin/env python3
"""
Generates Spanish TTS audio using edge-tts (Microsoft neural voices).
Writes MP3s to Audio.bundle/spanish/ in both iOS and Watch targets.
Usage: python3 generate_spanish_audio_edge.py [start] [end]
Safe to re-run — skips already generated files.
"""
import asyncio, json, re, sys
from pathlib import Path

BASE      = Path(__file__).parent / "YetAnotherLearningCards/YetAnotherLearningCards"
JSON_PATH = BASE / "spanish_cards.json"
OUT_DIR   = BASE / "Audio.bundle/spanish"
WATCH_OUT = BASE.parent / "YetAnotherLearningCards Watch App/Audio.bundle/spanish"
VOICE     = "es-ES-ElviraNeural"

OUT_DIR.mkdir(parents=True, exist_ok=True)
WATCH_OUT.mkdir(parents=True, exist_ok=True)

try:
    import edge_tts
except ImportError:
    print("Run: pip3 install edge-tts")
    sys.exit(1)

def strip_annotation(text: str) -> str:
    return re.sub(r'\s*\([^)]+\)\s*$', '', text).strip()

with open(JSON_PATH, encoding="utf-8") as f:
    cards = json.load(f)

start = int(sys.argv[1]) if len(sys.argv) > 1 else 0
end   = int(sys.argv[2]) if len(sys.argv) > 2 else len(cards)

async def generate(audio_index: int, text: str):
    mp3_path = OUT_DIR / f"spanish_{audio_index}.mp3"
    if mp3_path.exists():
        return False
    comm = edge_tts.Communicate(text, VOICE)
    await comm.save(str(mp3_path))
    watch_path = WATCH_OUT / f"spanish_{audio_index}.mp3"
    watch_path.write_bytes(mp3_path.read_bytes())
    return True

async def main():
    done = skipped = errors = 0
    for i in range(start, end):
        card = cards[i]
        audio_index = card.get("audioIndex", i)
        text = strip_annotation(card["front"])
        try:
            generated = await generate(audio_index, text)
            if generated:
                done += 1
                if done % 100 == 0:
                    print(f"[{i+1}] Generated {done} files...")
            else:
                skipped += 1
        except Exception as e:
            print(f"Error at {i} ({text!r}): {e}")
            errors += 1
            await asyncio.sleep(2)

    print(f"Done: {done} generated, {skipped} skipped, {errors} errors (range {start}-{end})")

asyncio.run(main())
