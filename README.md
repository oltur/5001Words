# 5001 Words

A multilingual vocabulary flashcard app for iPhone/iPad and Apple Watch, built with SwiftUI. Vocabulary decks are downloadable language packs; Spanish ships bundled.

## Features

- **5,001 cards per deck** loaded from JSON (bundled or downloaded)
- **8 language decks** — see table below
- **Audio pronunciation** via Microsoft edge-tts neural voices (copyright-free MP3s)
- **Auto-play** — optionally speaks the front card automatically on flip
- **Downloadable packs** — word list + audio in a single `.pack` file (~48–54 MB per language)
- **Bidirectional learning** — toggle between source→target and target→source
- **Card gestures:** tap to flip, double-tap to play audio, swipe left/right to navigate
- **Focus mode** — drill a random subset of 20 unlearned cards
- **Mark as learned** — hides cards and persists progress
- **Shuffle** — randomises card order
- **Appearance modes** — Light, Dark, or System
- **Native Apple Watch app** with the same full feature set
- **Letter-themed app icon** featuring scripts from 8 writing systems

## Language Decks

| Deck | Flag | Audio | Bundled | Notes |
|------|------|-------|---------|-------|
| Spanish – English | 🇪🇸 🇬🇧 | ✅ edge-tts `es-ES-ElviraNeural` | ✅ yes | Cards + audio ship with app |
| Spanish – Ukrainian | 🇪🇸 🇺🇦 | ✅ (reuses Spanish audio) | ❌ download | JSON-only pack; shares Spanish audio |
| Ukrainian – English | 🇺🇦 🇬🇧 | ✅ edge-tts `uk-UA-PolinaNeural` | ❌ download | |
| French – English | 🇫🇷 🇬🇧 | ✅ edge-tts `fr-FR-DeniseNeural` | ❌ download | |
| German – English | 🇩🇪 🇬🇧 | ✅ edge-tts `de-DE-KatjaNeural` | ❌ download | |
| Dutch – English | 🇳🇱 🇬🇧 | ✅ edge-tts `nl-NL-FennaNeural` | ❌ download | |
| Hebrew – English | 🇮🇱 🇬🇧 | ✅ edge-tts `he-IL-HilaNeural` | ❌ download | Fronts include niqqud (vowel diacritics) |
| Yiddish – English | ✡️ 🇬🇧 | ❌ no audio | ✅ bundled | No TTS voice available |

## Project Structure

```
YetAnotherLearningCards/
├── YetAnotherLearningCards/              # iOS target
│   ├── ContentView.swift                 # All UI and navigation
│   ├── FlashCard.swift                   # Deck struct, CardStore, AudioPlayer
│   ├── PackManager.swift                 # Pack download, extraction, state
│   ├── spanish_cards.json                # Bundled (ships with app)
│   ├── yiddish_cards.json                # Bundled
│   └── Audio.bundle/
│       └── spanish/                      # Bundled Spanish audio
└── YetAnotherLearningCards Watch App/    # watchOS target (mirrors iOS)
    ├── ContentView.swift
    ├── FlashCard.swift
    └── Audio.bundle/
        └── spanish/
```

Non-bundled decks (JSON + audio) are downloaded as `.pack` files and extracted to `Application Support/packs/{deckId}/`.

## Data Format

Cards are stored in `{language}_cards.json`:

```json
[
  { "front": "absoluto (adj)", "back": "absolute", "audioIndex": 0 },
  { "front": "hablar (v)",     "back": "to speak",  "audioIndex": 1 }
]
```

| Field | Type | Description |
|-------|------|-------------|
| `front` | String | Word in the source language |
| `back` | String | Translation |
| `audioIndex` | Int? | Index for the MP3 filename; omit if no audio |

Audio files are named `{subfolder}_{audioIndex}.mp3` inside `Audio.bundle/{subfolder}/` or the downloaded pack directory.

## Pack Format

`.pack` files are a simple binary container:

```
PACK              (4 bytes magic)
count             (uint32 big-endian, number of files)
[name_len (uint16) + name (UTF-8) + data_len (uint32) + data] × count
```

Each pack contains one JSON file and N MP3s. Extracted to `Application Support/packs/{deckId}/`.

## Pack Download URLs

Packs are hosted on GitHub Releases (`oltur/5001Words`, tag `audio-v1`). URLs are defined in `PackManager.swift`.

## Architecture

| Component | Role |
|-----------|------|
| `Deck` struct | Metadata: id, name, fileName, emoji, audioFolder, isBundled, hasAudio, sourceLanguage, targetLanguage, targetEmoji |
| `availableDecks` | Registry in `FlashCard.swift` (duplicated in both targets) |
| `CardStore` | Loads cards from bundle or downloaded pack; persists learned/focus state |
| `AudioPlayer` | Checks downloaded pack dir first, falls back to `Audio.bundle` |
| `PackManager` | Downloads and extracts `.pack` files; singleton `PackManager.shared` |
| `ContentView` | All UI, gestures, settings sheet |

## Adding a New Deck

1. **Generate cards:** create `{name}_cards.json` with `front`, `back`, `audioIndex` fields
2. **Generate audio:** use `generate_{name}_audio_edge.py` (edge-tts, 4 parallel workers)
3. **Add to `availableDecks`** in both `FlashCard.swift` files
4. **Add download URL** to `packDownloadURLs` in `PackManager.swift`
5. **Add to `create_packs.py`** and run it to build the `.pack` file
6. **Upload** `.pack` to the `audio-v1` GitHub Release: `gh release upload audio-v1 {name}_audio.pack --clobber`
7. **Add JSON to Xcode** — add `{name}_cards.json` to both iOS and Watch targets in Xcode

## Python Scripts

| Script | Purpose |
|--------|---------|
| `generate_{lang}_cards.py` | Translate Spanish→target via Google Translate, produce `*_cards.json` |
| `generate_ukrainian_cards.py` | Builds from existing `spanish_uk_cards.json` — no API calls |
| `generate_{lang}_audio_edge.py` | Generate MP3s via edge-tts; run 4 workers in parallel |
| `add_hebrew_niqqud.py` | Add vowel diacritics to Hebrew fronts using nakdimon (offline) |
| `create_packs.py` | Build all `.pack` files from JSON + audio |
| `extract_audio.py` | Download released packs and extract MP3s to `audio_source/` (backup) |
