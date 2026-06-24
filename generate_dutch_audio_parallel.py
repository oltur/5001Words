#!/usr/bin/env python3
"""Parallel Dutch TTS audio generation using macOS `say` + lame.
Splits work across multiple workers, then updates dutch_cards.json."""
import json, re, subprocess, sys, os, tempfile, shutil
from pathlib import Path
from multiprocessing import Pool, cpu_count

BASE     = Path(__file__).parent / "YetAnotherLearningCards/YetAnotherLearningCards"
JSON_PATH = BASE / "dutch_cards.json"
OUT_DIR   = BASE / "Audio.bundle/dutch"
WATCH_OUT = BASE.parent / "YetAnotherLearningCards Watch App/Audio.bundle/dutch"
VOICE     = "Xander"
WORKERS   = 4

OUT_DIR.mkdir(parents=True, exist_ok=True)
WATCH_OUT.mkdir(parents=True, exist_ok=True)

def extract_text(front: str) -> str:
    return re.sub(r'\s*\([^)]+\)\s*$', '', front).strip()

def generate_one(args):
    i, text = args
    mp3_path = OUT_DIR / f"dutch_{i}.mp3"
    watch_mp3 = WATCH_OUT / f"dutch_{i}.mp3"

    if mp3_path.exists() and watch_mp3.exists():
        return i, "skip"

    with tempfile.NamedTemporaryFile(suffix=".aiff", delete=False) as tmp:
        tmp_path = tmp.name

    try:
        subprocess.run(["say", "-v", VOICE, "-o", tmp_path, text],
                       check=True, capture_output=True)
        subprocess.run(["lame", "--quiet", "-V4", tmp_path, str(mp3_path)],
                       check=True, capture_output=True)
        shutil.copy2(str(mp3_path), str(watch_mp3))
        return i, "ok"
    except subprocess.CalledProcessError as e:
        return i, f"error: {e}"
    finally:
        try: os.unlink(tmp_path)
        except: pass

if __name__ == "__main__":
    with open(JSON_PATH, encoding="utf-8") as f:
        cards = json.load(f)

    tasks = [(i, extract_text(c["front"])) for i, c in enumerate(cards)]
    total = len(tasks)

    print(f"Starting {WORKERS} workers for {total} cards...", flush=True)

    done = skipped = errors = 0
    with Pool(WORKERS) as pool:
        for i, status in pool.imap_unordered(generate_one, tasks, chunksize=4):
            if status == "skip":
                skipped += 1
            elif status == "ok":
                done += 1
            else:
                errors += 1
                print(f"[{i}] {status}", file=sys.stderr)

            total_done = done + skipped + errors
            if total_done % 200 == 0:
                print(f"[{total_done}/{total}] new={done} skipped={skipped} errors={errors}", flush=True)

    # Update JSON with audioIndex
    for i, card in enumerate(cards):
        mp3 = OUT_DIR / f"dutch_{i}.mp3"
        card["audioIndex"] = i if mp3.exists() else None

    with open(JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(cards, f, ensure_ascii=False, indent=2)

    print(f"\nDone! new={done} skipped={skipped} errors={errors}")
    print(f"JSON updated: {JSON_PATH}")
