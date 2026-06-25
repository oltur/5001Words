#!/usr/bin/env python3
"""
Creates .pack files for each language, including word list JSON + audio MP3s.
Run from the repo root: python3 create_packs.py
Upload the resulting *.pack files to a GitHub Release.
"""
import struct
from pathlib import Path

BASE  = Path(__file__).parent / "YetAnotherLearningCards/YetAnotherLearningCards"
AUDIO = BASE / "Audio.bundle"

def create_pack(deck_id: str, audio_folder: str, output: Path):
    json_file  = BASE / f"{deck_id}_cards.json"
    audio_dir  = AUDIO / audio_folder
    mp3_files  = sorted(audio_dir.glob("*.mp3"))

    entries = []
    if json_file.exists():
        entries.append(json_file)
        print(f"  + {json_file.name}")
    entries.extend(mp3_files)
    print(f"  + {len(mp3_files)} mp3 files from {audio_folder}/")

    with open(output, "wb") as out:
        out.write(b"PACK")
        out.write(struct.pack(">I", len(entries)))
        for path in entries:
            name = path.name.encode("utf-8")
            data = path.read_bytes()
            out.write(struct.pack(">H", len(name)))
            out.write(name)
            out.write(struct.pack(">I", len(data)))
            out.write(data)

    mb = output.stat().st_size / 1024 / 1024
    print(f"  → {output.name}  {mb:.1f} MB\n")

print("Packing Spanish...")
create_pack("spanish", "spanish", Path("spanish_audio.pack"))

print("Packing Dutch...")
create_pack("dutch", "dutch", Path("dutch_audio.pack"))

print("Done. Upload both .pack files to a GitHub Release, then update packDownloadURLs in PackManager.swift.")
