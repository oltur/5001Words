import Foundation
import Combine
import AVFoundation

struct Deck: Identifiable, Hashable {
    let id: String
    let name: String
    let fileName: String
    let emoji: String
}

let availableDecks: [Deck] = [
    Deck(id: "spanish", name: "Spanish", fileName: "spanish_cards", emoji: "🇪🇸"),
    Deck(id: "dutch",   name: "Dutch",   fileName: "dutch_cards",   emoji: "🇳🇱"),
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

    func play(audioIndex: Int) {
        let filename = "\(audioIndex)"

        var url: URL? = nil
        url = Bundle.main.url(forResource: filename, withExtension: "mp3", subdirectory: "Audio")
        if url == nil {
            url = Bundle.main.url(forResource: filename, withExtension: "mp3")
        }
        if url == nil, let audioDir = Bundle.main.url(forResource: "Audio", withExtension: nil) {
            let fileURL = audioDir.appendingPathComponent("\(filename).mp3")
            if FileManager.default.fileExists(atPath: fileURL.path) {
                url = fileURL
            }
        }

        guard let audioURL = url else {
            print("Audio file not found: \(filename).mp3")
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

    func loadCards(from deck: Deck) {
        guard let url = Bundle.main.url(forResource: deck.fileName, withExtension: "json") else {
            print("Could not find \(deck.fileName).json")
            cards = fallbackCards
            return
        }
        do {
            let data = try Data(contentsOf: url)
            cards = try JSONDecoder().decode([FlashCard].self, from: data)
            print("Loaded \(cards.count) cards from \(deck.fileName)")
        } catch {
            print("Error loading cards: \(error)")
            cards = fallbackCards
        }
    }

    private let fallbackCards = [
        FlashCard(front: "Hola", back: "Hello"),
        FlashCard(front: "Gracias", back: "Thank you"),
        FlashCard(front: "Adiós", back: "Goodbye")
    ]
}
