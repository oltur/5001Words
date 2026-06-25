#!/usr/bin/env python3
"""
Downloads language packs from GitHub and extracts MP3s to audio_source/{lang}/.
Run from the repo root: python3 extract_audio.py
"""
import struct
from pathlib import Path

PACKS = {
    "dutch":   "https://github.com/oltur/5001Words/releases/download/audio-v1/dutch_audio.pack",
    "german":  "https://github.com/oltur/5001Words/releases/download/audio-v1/german_audio.pack",
    "spanish": "https://github.com/oltur/5001Words/releases/download/audio-v1/spanish_audio.pack",
}

OUT_ROOT = Path(__file__).parent / "audio_source"

def unpack(data: bytes, out_dir: Path):
    out_dir.mkdir(parents=True, exist_ok=True)
    cur = 0

    def read(n):
        nonlocal cur
        chunk = data[cur:cur+n]
        cur += n
        return chunk

    def u16(b): return int.from_bytes(b, "big")
    def u32(b): return int.from_bytes(b, "big")

    assert read(4) == b"PACK", "Not a valid pack file"
    count = u32(read(4))
    mp3s = 0
    for _ in range(count):
        name_len = u16(read(2))
        name = read(name_len).decode("utf-8")
        data_len = u32(read(4))
        file_data = read(data_len)
        if name.endswith(".mp3"):
            (out_dir / name).write_bytes(file_data)
            mp3s += 1
    print(f"  Extracted {mp3s} MP3s → {out_dir}")

for lang, url in PACKS.items():
    out_dir = OUT_ROOT / lang
    existing = list(out_dir.glob("*.mp3")) if out_dir.exists() else []
    if len(existing) > 100:
        print(f"{lang}: {len(existing)} files already present, skipping.")
        continue
    print(f"Downloading {lang} pack...")
    import subprocess, tempfile, os
    with tempfile.NamedTemporaryFile(suffix=".pack", delete=False) as tmp:
        tmp_path = tmp.name
    subprocess.run(["gh", "release", "download", "audio-v1",
                    "--repo", "oltur/5001Words",
                    "--pattern", url.split("/")[-1],
                    "--output", tmp_path,
                    "--clobber"], check=True)
    unpack(open(tmp_path, "rb").read(), out_dir)
    os.unlink(tmp_path)

print("Done. Audio lives in audio_source/ — outside Xcode targets.")
