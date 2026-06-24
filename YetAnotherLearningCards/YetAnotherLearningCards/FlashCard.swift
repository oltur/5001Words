import Foundation
import Combine
import AVFoundation

struct FlashCard: Identifiable, Codable {
    var id = UUID()
    let front: String  // Spanish
    let back: String   // English
    let audioIndex: Int?  // Index of audio file

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

        // Try multiple locations to find the audio file
        var url: URL? = nil

        // Try with subdirectory "Audio"
        url = Bundle.main.url(forResource: filename, withExtension: "mp3", subdirectory: "Audio")

        // Try without subdirectory (files might be at bundle root)
        if url == nil {
            url = Bundle.main.url(forResource: filename, withExtension: "mp3")
        }

        // Try looking in Audio folder reference
        if url == nil, let audioDir = Bundle.main.url(forResource: "Audio", withExtension: nil) {
            let fileURL = audioDir.appendingPathComponent("\(filename).mp3")
            if FileManager.default.fileExists(atPath: fileURL.path) {
                url = fileURL
            }
        }

        guard let audioURL = url else {
            print("Audio file not found: \(filename).mp3")
            // Debug: print what's in the bundle
            if let resourcePath = Bundle.main.resourcePath {
                let contents = try? FileManager.default.contentsOfDirectory(atPath: resourcePath)
                print("Bundle contents: \(contents?.prefix(20) ?? [])")
            }
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

    init() {
        loadCards()
    }

    func loadCards() {
        guard let url = Bundle.main.url(forResource: "spanish_cards", withExtension: "json") else {
            print("Could not find spanish_cards.json")
            cards = [
                FlashCard(front: "Hola", back: "Hello"),
                FlashCard(front: "Gracias", back: "Thank you"),
                FlashCard(front: "Adiós", back: "Goodbye")
            ]
            return
        }

        do {
            let data = try Data(contentsOf: url)
            cards = try JSONDecoder().decode([FlashCard].self, from: data)
            print("Loaded \(cards.count) cards")
        } catch {
            print("Error loading cards: \(error)")
            cards = [
                FlashCard(front: "Hola", back: "Hello"),
                FlashCard(front: "Gracias", back: "Thank you"),
                FlashCard(front: "Adiós", back: "Goodbye")
            ]
        }
    }
}
