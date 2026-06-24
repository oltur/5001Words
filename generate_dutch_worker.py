#!/usr/bin/env python3
"""Single-range worker: generate Dutch audio for indices [start, end)."""
import json, re, subprocess, sys, os, tempfile, shutil
from pathlib import Path

BASE      = Path(__file__).parent / "YetAnotherLearningCards/YetAnotherLearningCards"
JSON_PATH = BASE / "dutch_cards.json"
OUT_DIR   = BASE / "Audio.bundle/dutch"
WATCH_OUT = BASE.parent / "YetAnotherLearningCards Watch App/Audio.bundle/dutch"
VOICE     = "Xander"

OUT_DIR.mkdir(parents=True, exist_ok=True)
WATCH_OUT.mkdir(parents=True, exist_ok=True)

def extract_text(front: str) -> str:
    return re.sub(r'\s*\([^)]+\)\s*$', '', front).strip()

start = int(sys.argv[1])
end   = int(sys.argv[2])

with open(JSON_PATH, encoding="utf-8") as f:
    cards = json.load(f)

for i in range(start, min(end, len(cards))):
    mp3_path  = OUT_DIR   / f"dutch_{i}.mp3"
    watch_mp3 = WATCH_OUT / f"dutch_{i}.mp3"

    if mp3_path.exists() and watch_mp3.exists():
        continue

    text = extract_text(cards[i]["front"])
    with tempfile.NamedTemporaryFile(suffix=".aiff", delete=False) as tmp:
        tmp_path = tmp.name
    try:
        subprocess.run(["say", "-v", VOICE, "-o", tmp_path, text],
                       check=True, capture_output=True)
        subprocess.run(["lame", "--quiet", "-V4", tmp_path, str(mp3_path)],
                       check=True, capture_output=True)
        shutil.copy2(str(mp3_path), str(watch_mp3))
    except Exception as e:
        print(f"[{i}] ERROR: {e}", file=sys.stderr)
    finally:
        try: os.unlink(tmp_path)
        except: pass

print(f"Worker {start}-{end} done.", flush=True)
