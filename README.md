# 5001 Words

A multilingual vocabulary flashcard app for iPhone/iPad and Apple Watch, built with SwiftUI. Currently supports Spanish–English and Dutch–English decks.

## Features

- **5,001 cards per deck** loaded from bundled JSON files
- **Two language decks** — Spanish 🇪🇸 and Dutch 🇳🇱, switchable at any time
- **Audio pronunciation:**
  - Spanish — 5,000 native-speaker MP3s
  - Dutch — 5,001 macOS TTS MP3s (Xander, nl_NL voice)
- **Bidirectional learning** — toggle between L1→EN and EN→L1 modes
- **Card gestures:**
  - Tap to flip
  - Double-tap to play audio
  - Swipe left/right to navigate (with slide animation)
- **Shuffle** — randomises card order and resets to first card
- **Appearance modes** — Light, Dark, or System (persisted across launches)
- **Native Apple Watch app** with the same full feature set
- **Letter-themed app icon** featuring scripts from 8 writing systems: Hebrew ש, Ukrainian ї, Tibetan ཀ, Hindi अ, Japanese あ, Korean 한, Maya numerals, and the Andean Chakana cross

## Project Structure

```
YetAnotherLearningCards/
├── YetAnotherLearningCards/              # iOS target
│   ├── YetAnotherLearningCardsApp.swift
│   ├── ContentView.swift                 # Main UI
│   ├── FlashCard.swift                   # Data model, CardStore, AudioPlayer, Deck
│   ├── spanish_cards.json                # Spanish deck (5,001 cards)
│   ├── dutch_cards.json                  # Dutch deck (5,001 cards)
│   └── Audio.bundle/                     # All audio files
│       ├── 0.mp3, 1.mp3, …              # Spanish pronunciation (non-sequential indices)
│       └── dutch/                        # Dutch pronunciation
│           ├── dutch_0.mp3
│           ├── dutch_1.mp3
│           └── …
└── YetAnotherLearningCards Watch App/    # watchOS target
    ├── ContentView.swift                  # Watch-optimised UI
    ├── FlashCard.swift                    # Same model (duplicated)
    ├── spanish_cards.json                 # Same datasets (duplicated)
    ├── dutch_cards.json
    └── Audio.bundle/                      # Same audio (duplicated)
```

## Data Format

Cards are stored in `{language}_cards.json` as a JSON array:

```json
[
  { "front": "absoluto (adj)", "back": "absolute",  "audioIndex": 8169 },
  { "front": "hablar (v)",     "back": "to speak",  "audioIndex": 312  },
  { "front": "absoluut (adj)", "back": "absolute",  "audioIndex": 0    }
]
```

| Field        | Type   | Description                                                    |
|-------------|--------|----------------------------------------------------------------|
| `front`     | String | Word or phrase in the target language (shown first by default) |
| `back`      | String | English translation                                            |
| `audioIndex`| Int?   | Index used to locate the MP3; omit if no audio available       |

**Spanish audio** — files named `{audioIndex}.mp3` in `Audio.bundle/` root. Indices are non-sequential (reference a larger source library).

**Dutch audio** — files named `dutch_{audioIndex}.mp3` in `Audio.bundle/dutch/`. Indices are sequential (0–5000).

## Architecture

| Component        | Type                  | Role                                                  |
|-----------------|-----------------------|-------------------------------------------------------|
| `Deck`          | `struct` (Identifiable) | Deck metadata: id, name, fileName, emoji, audioFolder |
| `availableDecks`| `[Deck]` constant     | Registry of all available decks                       |
| `FlashCard`     | `struct` (Codable)    | Card data model                                       |
| `CardStore`     | `ObservableObject`    | Loads and holds the card array from the bundle        |
| `AudioPlayer`   | `ObservableObject`    | Wraps `AVAudioPlayer` for MP3 playback                |
| `ContentView`   | SwiftUI `View`        | All UI and navigation logic                           |
| `AppearanceMode`| `enum` (AppStorage)   | Persisted light/dark/system preference                |

`CardStore` falls back to 3 hardcoded Spanish cards if the JSON cannot be loaded.

`AudioPlayer.play(audioIndex:subfolder:)` resolves files via `Audio.bundle`, then `Bundle.main` subdirectory lookup, then bundle root as a last resort.

## Deck Switching

Decks are defined in `FlashCard.swift`:

```swift
let availableDecks: [Deck] = [
    Deck(id: "spanish", name: "Spanish", fileName: "spanish_cards", emoji: "🇪🇸", audioFolder: ""),
    Deck(id: "dutch",   name: "Dutch",   fileName: "dutch_cards",   emoji: "🇳🇱", audioFolder: "dutch"),
]
```

On iOS the active deck is selected from a `Menu` in the header. On watchOS a cycle button steps through decks. The selected deck ID is persisted via `@AppStorage`.

## Appearance

The appearance button cycles through three modes:

| Icon | Mode   | Behaviour                  |
|------|--------|----------------------------|
| ◑    | System | Follows the device setting |
| ☀︎   | Light  | Always light               |
| ☾    | Dark   | Always dark                |

## Adding a New Deck

1. Create `{name}_cards.json` following the data format above
2. Generate audio if needed (see `generate_dutch_audio_parallel.py` / `generate_dutch_worker.py` for a TTS pipeline)
3. Add an entry to `availableDecks` in both `FlashCard.swift` files
4. Add the JSON and audio folder to both targets' bundle resources in Xcode

## Known Limitations

- All content is **bundled at build time** — there is no runtime import of additional decks.
- The iOS and watchOS targets duplicate all source files and assets.
- Card position is not persisted — the app always starts from card 1.
- No search, filtering, or spaced-repetition scheduling.
- Dutch audio is TTS (macOS `say` command, Xander voice) rather than native-speaker recordings.
