# CLAUDE.md — Developer Notes for 5001 Words

## Project Overview

SwiftUI flashcard app for iOS + watchOS. Spanish ships bundled; all other decks are downloaded as `.pack` files. Audio is generated offline via Microsoft edge-tts (copyright-free).

## Key Files

### Swift (both targets — keep in sync)
- `FlashCard.swift` — `Deck` struct, `availableDecks`, `CardStore`, `AudioPlayer`
- `ContentView.swift` — all UI, gestures, settings, auto-play logic

### iOS only
- `PackManager.swift` — download URLs, pack extraction, download state machine

### Python scripts (repo root)
- `generate_{lang}_cards.py` — produces `{lang}_cards.json` via Google Translate (ES→target)
- `generate_{lang}_audio_edge.py` — produces MP3s via edge-tts, writes to `Audio.bundle/{lang}/` in both targets
- `generate_ukrainian_cards.py` — no API; derived from `spanish_uk_cards.json`
- `add_hebrew_niqqud.py` — post-processes `hebrew_cards.json` with nakdimon (run after card generation)
- `create_packs.py` — builds all `.pack` files; run after audio is complete
- `extract_audio.py` — recovers MP3s from released packs into `audio_source/` backup

## Adding a New Language

```bash
# 1. Generate cards (ES→target via Google Translate)
python3 generate_{lang}_cards.py

# 2. Generate audio in 4 parallel workers
python3 generate_{lang}_audio_edge.py 0    1250 > /tmp/{lang}_0.log 2>&1 &
python3 generate_{lang}_audio_edge.py 1250 2500 > /tmp/{lang}_1.log 2>&1 &
python3 generate_{lang}_audio_edge.py 2500 3750 > /tmp/{lang}_2.log 2>&1 &
python3 generate_{lang}_audio_edge.py 3750 5001 > /tmp/{lang}_3.log 2>&1 &

# 3. Build and upload pack (after audio completes)
python3 create_packs.py
gh release upload audio-v1 {lang}_audio.pack --clobber
```

Then update Swift files and Xcode project (see README).

## Deck Struct Fields

```swift
Deck(
    id:             "french",           // unique key, used for pack dir + AppStorage
    name:           "French - English", // displayed in deck picker
    fileName:       "french_cards",     // JSON filename without extension
    emoji:          "🇫🇷",             // source language flag
    audioFolder:    "french",           // subfolder in Audio.bundle / packs/{id}/
    isBundled:      false,              // true = JSON ships with app (no download needed for cards)
    hasAudio:       true,               // false = hide audio UI entirely (e.g. Yiddish)
    sourceLanguage: "French",           // shown in direction toggle label
    targetLanguage: "English",          // shown in direction toggle label
    targetEmoji:    "🇬🇧"             // target language flag
)
```

`availableDecks` is defined identically in both `FlashCard.swift` files — always update both.

## Pack Format

```
PACK              (4 bytes)
count             (uint32 big-endian)
[ uint16 name_len | UTF-8 name | uint32 data_len | bytes ] × count
```

Extracted to `Application Support/packs/{deckId}/`. Excluded from iCloud backup.

## Audio Lookup Order (iOS)

1. `Application Support/packs/{audioFolder}/{audioFolder}_{audioIndex}.mp3` (downloaded pack)
2. `Audio.bundle/{audioFolder}/{audioFolder}_{audioIndex}.mp3` (bundled)
3. `Bundle.main` subdirectory lookup
4. Bundle root

## Audio Lookup Order (watchOS)

Only `Audio.bundle` — no pack downloads on Watch. Watch plays bundled Spanish audio only; all other decks have no audio on Watch even if downloaded.

## Pack Download URLs

All in `PackManager.swift → packDownloadURLs`. Tag: `audio-v1` on `oltur/5001Words`.

Spanish-Ukrainian shares the Spanish audio pack — its `.pack` is JSON-only (`create_json_only_pack()`).

## create_packs.py Notes

- `create_pack()` checks `Audio.bundle/{folder}/` first; if empty, falls back to `audio_source/{folder}/`
- `audio_source/` is gitignored — it's an offline backup of all MP3s
- Run `extract_audio.py` to repopulate `audio_source/` from the released packs

## Xcode Project Notes

- App icon: single 1024×1024 universal image in `AppIcon.appiconset/Contents.json` — do not add additional sizes (causes "unassigned children" warnings)
- Non-bundled JSON files (`french_cards.json`, `hebrew_cards.json`, etc.) must be added to **both** iOS and Watch targets in Xcode, even though at runtime the Watch loads from bundle and iOS loads from the downloaded pack
- SourceKit shows "Cannot find type 'Deck' in scope" in `PackManager.swift` — this is a false positive; `Deck` is in `FlashCard.swift` in the same target

## Dependencies

```bash
pip3 install edge-tts deep-translator nakdimon
```

- `edge-tts` — Microsoft neural TTS (copyright-free output)
- `deep-translator` — Google Translate wrapper for card generation
- `nakdimon` — offline ONNX model for Hebrew niqqud (vowel diacritics)
