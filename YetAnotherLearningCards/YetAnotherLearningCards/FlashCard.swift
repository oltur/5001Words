import Foundation
import Combine
import AVFoundation

struct Deck: Identifiable, Hashable {
    let id: String
    let name: String
    let fileName: String
    let emoji: String
    let audioFolder: String
    let isBundled: Bool  // ships with the app, no download required
    let hasAudio: Bool
    let sourceLanguage: String
    let targetLanguage: String
    let targetEmoji: String
}

let availableDecks: [Deck] = [
    Deck(id: "spanish",    name: "Spanish - English",   fileName: "spanish_cards",    emoji: "🇪🇸", audioFolder: "spanish", isBundled: true,  hasAudio: true,  sourceLanguage: "Spanish", targetLanguage: "English",   targetEmoji: "🇬🇧"),
    Deck(id: "spanish_uk", name: "Spanish - Ukrainian", fileName: "spanish_uk_cards", emoji: "🇪🇸", audioFolder: "spanish", isBundled: false, hasAudio: true,  sourceLanguage: "Spanish", targetLanguage: "Ukrainian", targetEmoji: "🇺🇦"),
    Deck(id: "yiddish",    name: "Yiddish - English",   fileName: "yiddish_cards",    emoji: "✡️",  audioFolder: "yiddish", isBundled: true,  hasAudio: false, sourceLanguage: "Yiddish", targetLanguage: "English",   targetEmoji: "🇬🇧"),
    Deck(id: "hebrew",     name: "Hebrew - English",    fileName: "hebrew_cards",     emoji: "🇮🇱", audioFolder: "hebrew",  isBundled: false, hasAudio: true,  sourceLanguage: "Hebrew",  targetLanguage: "English",   targetEmoji: "🇬🇧"),
    Deck(id: "dutch",      name: "Dutch - English",     fileName: "dutch_cards",      emoji: "🇳🇱", audioFolder: "dutch",   isBundled: false, hasAudio: true,  sourceLanguage: "Dutch",   targetLanguage: "English",   targetEmoji: "🇬🇧"),
    Deck(id: "german",     name: "German - English",    fileName: "german_cards",     emoji: "🇩🇪", audioFolder: "german",  isBundled: false, hasAudio: true,  sourceLanguage: "German",  targetLanguage: "English",   targetEmoji: "🇬🇧"),
    Deck(id: "french",     name: "French - English",    fileName: "french_cards",     emoji: "🇫🇷", audioFolder: "french",  isBundled: false, hasAudio: true,  sourceLanguage: "French",  targetLanguage: "English",   targetEmoji: "🇬🇧"),
    Deck(id: "ukrainian",  name: "Ukrainian - English", fileName: "ukrainian_cards",  emoji: "🇺🇦", audioFolder: "ukrainian", isBundled: false, hasAudio: true,  sourceLanguage: "Ukrainian", targetLanguage: "English", targetEmoji: "🇬🇧"),
]

struct FlashCard: Identifiable, Codable {
    var id = UUID()
    let front: String
    let back: String
    let audioIndex: Int?

    enum CodingKeys: String, CodingKey {
        case front, back, audioIndex
    }

    init(front: String, back: String, audioIndex: Int? = nil) {
        self.front = front
        self.back = back
        self.audioIndex = audioIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.front = try container.decode(String.self, forKey: .front)
        self.back = try container.decode(String.self, forKey: .back)
        self.audioIndex = try container.decodeIfPresent(Int.self, forKey: .audioIndex)
    }
}

class AudioPlayer: ObservableObject {
    private var player: AVAudioPlayer?

    func play(audioIndex: Int, subfolder: String = "") {
        let resourceName = subfolder.isEmpty ? "\(audioIndex)" : "\(subfolder)_\(audioIndex)"
        let filename = "\(resourceName).mp3"

        // Check downloaded pack first (applicationSupport/packs/{subfolder}/)
        if !subfolder.isEmpty {
            let packFile = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("packs")
                .appendingPathComponent(subfolder)
                .appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: packFile.path) {
                playURL(packFile); return
            }
        }

        // Fall back to Audio.bundle
        let audioBundleURL = Bundle.main.url(forResource: "Audio", withExtension: "bundle")
        let bundledAudioURL = audioBundleURL?
            .appendingPathComponent(subfolder)
            .appendingPathComponent(filename)

        var url = bundledAudioURL.flatMap { FileManager.default.fileExists(atPath: $0.path) ? $0 : nil }
        if url == nil {
            url = Bundle.main.url(
                forResource: resourceName,
                withExtension: "mp3",
                subdirectory: subfolder.isEmpty ? nil : subfolder
            )
        }
        if url == nil {
            url = Bundle.main.url(forResource: resourceName, withExtension: "mp3")
        }

        guard let audioURL = url else {
            print("Audio file not found: \(subfolder.isEmpty ? "" : subfolder + "/")\(filename)")
            return
        }
        playURL(audioURL)
    }

    private func playURL(_ url: URL) {
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.play()
        } catch {
            print("Error playing audio: \(error)")
        }
    }

    func stop() {
        player?.stop()
    }
}

class CardStore: ObservableObject {
    @Published var cards: [FlashCard] = []
    @Published var isFocusModeOn: Bool = false
    @Published var focusFronts: [String] = []
    @Published var learnedFronts: Set<String> = []

    private var currentDeckId: String = "spanish"

    var displayCards: [FlashCard] {
        let unlearned = cards.filter { !learnedFronts.contains($0.front) }
        if isFocusModeOn && !focusFronts.isEmpty {
            let focusSet = Set(focusFronts)
            return unlearned.filter { focusSet.contains($0.front) }
        }
        return unlearned
    }

    var learnedCount: Int { learnedFronts.count }
    var totalCount: Int { cards.count }
    var remainingCount: Int { cards.filter { !learnedFronts.contains($0.front) }.count }

    func loadCards(from deck: Deck) {
        currentDeckId = deck.id
        learnedFronts = Set(UserDefaults.standard.stringArray(forKey: "learned_\(deck.id)") ?? [])
        focusFronts = UserDefaults.standard.stringArray(forKey: "focus_\(deck.id)") ?? []
        isFocusModeOn = UserDefaults.standard.bool(forKey: "focusMode_\(deck.id)")

        // Check downloaded pack first, fall back to bundle
        let packJSON = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("packs")
            .appendingPathComponent(deck.id)
            .appendingPathComponent("\(deck.fileName).json")

        let url: URL
        if FileManager.default.fileExists(atPath: packJSON.path) {
            url = packJSON
        } else if let bundled = Bundle.main.url(forResource: deck.fileName, withExtension: "json") {
            url = bundled
        } else {
            print("Could not find \(deck.fileName).json")
            cards = fallbackCards
            return
        }

        do {
            let data = try Data(contentsOf: url)
            cards = try JSONDecoder().decode([FlashCard].self, from: data).shuffled()
            print("Loaded \(cards.count) cards from \(deck.fileName)")
        } catch {
            print("Error loading cards: \(error)")
            cards = fallbackCards
        }
    }

    func markLearned(_ card: FlashCard) {
        learnedFronts.insert(card.front)
        UserDefaults.standard.set(Array(learnedFronts), forKey: "learned_\(currentDeckId)")
    }

    func pickNewFocusSet() {
        let available = cards.filter { !learnedFronts.contains($0.front) }
        focusFronts = Array(available.shuffled().prefix(20)).map(\.front)
        UserDefaults.standard.set(focusFronts, forKey: "focus_\(currentDeckId)")
    }

    func setFocusMode(_ on: Bool) {
        isFocusModeOn = on
        UserDefaults.standard.set(on, forKey: "focusMode_\(currentDeckId)")
        if on && focusFronts.isEmpty {
            pickNewFocusSet()
        }
    }

    func resetLearned() {
        learnedFronts = []
        focusFronts = []
        isFocusModeOn = false
        UserDefaults.standard.removeObject(forKey: "learned_\(currentDeckId)")
        UserDefaults.standard.removeObject(forKey: "focus_\(currentDeckId)")
        UserDefaults.standard.removeObject(forKey: "focusMode_\(currentDeckId)")
    }

    private let fallbackCards = [
        FlashCard(front: "Hola", back: "Hello"),
        FlashCard(front: "Gracias", back: "Thank you"),
        FlashCard(front: "Adiós", back: "Goodbye")
    ]
}
