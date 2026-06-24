# YetAnotherLearningCards

A Spanish–English vocabulary flashcard app for iPhone/iPad and Apple Watch, built with SwiftUI.

## Features

- **5,001 cards** loaded from a bundled JSON file
- **Audio pronunciation** for 5,000 words (native speaker MP3s)
- **Bidirectional learning** — toggle between ES→EN and EN→ES modes
- **Card gestures:**
  - Tap to flip
  - Double-tap to play audio
  - Swipe left/right to navigate (with slide animation)
- **Shuffle** — randomizes card order and resets to first card
- **Appearance modes** — Light, Dark, or System (persisted across launches)
- **Native Apple Watch app** with the same full feature set

## Project Structure

```
YetAnotherLearningCards/
├── YetAnotherLearningCards/          # iOS target
│   ├── YetAnotherLearningCardsApp.swift
│   ├── ContentView.swift             # Main UI
│   ├── FlashCard.swift               # Data model, CardStore, AudioPlayer
│   ├── spanish_cards.json            # Card dataset (5,001 cards, 460 KB)
│   └── Audio/                        # MP3 pronunciation files (9,740 files, 34 MB)
│       ├── 0.mp3
│       ├── 1.mp3
│       └── ...
└── YetAnotherLearningCards Watch App/  # watchOS target
    ├── ContentView.swift               # Watch-optimised UI
    ├── FlashCard.swift                 # Same model (duplicated)
    ├── spanish_cards.json              # Same dataset (duplicated)
    └── Audio/                          # Same audio files (duplicated)
```

## Data Format

Cards are stored in `spanish_cards.json` as a JSON array:

```json
[
  { "front": "absoluto (adj)", "back": "absolute", "audioIndex": 8169 },
  { "front": "hablar (v)",     "back": "to speak",  "audioIndex": 312  },
  { "front": "Key to Abbreviations", "back": "art - article" }
]
```

| Field        | Type    | Description                                      |
|-------------|---------|--------------------------------------------------|
| `front`     | String  | Spanish word or phrase (shown first by default)  |
| `back`      | String  | English translation                              |
| `audioIndex`| Int?    | Index of the corresponding MP3 in `Audio/`; omit if no audio |

Audio files are named `{audioIndex}.mp3` and stored flat in the `Audio/` folder. Indices are non-sequential (they reference a larger source library).

## Architecture

| Component      | Type                | Role                                              |
|---------------|---------------------|---------------------------------------------------|
| `FlashCard`   | `struct` (Codable)  | Card data model                                   |
| `CardStore`   | `ObservableObject`  | Loads and holds the card array from the bundle    |
| `AudioPlayer` | `ObservableObject`  | Wraps `AVAudioPlayer` for MP3 playback            |
| `ContentView` | SwiftUI `View`      | All UI and navigation logic                       |
| `AppearanceMode` | `enum` (AppStorage) | Persisted light/dark/system preference          |

`CardStore` falls back to 3 hardcoded cards if the JSON cannot be loaded.  
`AudioPlayer` tries three lookup paths before giving up: `Audio/` subdirectory, bundle root, and a manual folder reference check.

## Appearance

The appearance button in the top-right cycles through three modes:

| Icon | Mode   | Behaviour                  |
|------|--------|----------------------------|
| ◑    | System | Follows the device setting |
| ☀︎   | Light  | Always light               |
| ☾    | Dark   | Always dark                |

The selected mode is saved with `AppStorage` and restored on next launch.

## Known Limitations

- All content is **bundled at build time** — there is no runtime import of additional decks.
- The iOS and watchOS targets duplicate all source files and assets (~68 MB total).
- Card position is not persisted — the app always starts from card 1.
- No search, filtering, or spaced-repetition scheduling.
