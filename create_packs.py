#!/usr/bin/env python3
"""
Creates .pack files for each language's audio, ready to upload to a GitHub Release.
Run from the repo root: python3 create_packs.py
"""
import struct
from pathlib import Path

def create_pack(folder: Path, output: Path):
    files = sorted(folder.glob("*.mp3"))
    print(f"Packing {len(files)} files from {folder.name}/ → {output.name} ...", flush=True)
    with open(output, "wb") as out:
        out.write(b"PACK")                          # magic
        out.write(struct.pack(">I", len(files)))    # file count (uint32 big-endian)
        for path in files:
            name = path.name.encode("utf-8")
            data = path.read_bytes()
            out.write(struct.pack(">H", len(name))) # name length (uint16)
            out.write(name)
            out.write(struct.pack(">I", len(data))) # data length (uint32)
            out.write(data)
    mb = output.stat().st_size / 1024 / 1024
    print(f"  ✓ {mb:.1f} MB")

base = Path(__file__).parent / "YetAnotherLearningCards/YetAnotherLearningCards/Audio.bundle"
create_pack(base / "spanish", Path("spanish_audio.pack"))
create_pack(base / "dutch",   Path("dutch_audio.pack"))

print()
print("Upload spanish_audio.pack and dutch_audio.pack to a GitHub Release,")
print("then update packDownloadURLs in PackManager.swift.")
