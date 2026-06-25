import Foundation
import Combine
import AVFoundation

struct Deck: Identifiable, Hashable {
    let id: String
    let name: String
    let fileName: String
    let emoji: String
    let audioFolder: String
    let isBundled: Bool
}

let availableDecks: [Deck] = [
    Deck(id: "spanish", name: "Spanish", fileName: "spanish_cards", emoji: "🇪🇸", audioFolder: "spanish", isBundled: true),
    Deck(id: "dutch",   name: "Dutch",   fileName: "dutch_cards",   emoji: "🇳🇱", audioFolder: "dutch",   isBundled: false),
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
            let path = subfolder.isEmpty ? filename : "\(subfolder)/\(filename)"
            print("Audio file not found: Audio.bundle/\(path)")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: audioURL)
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

        guard let url = Bundle.main.url(forResource: deck.fileName, withExtension: "json") else {
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
