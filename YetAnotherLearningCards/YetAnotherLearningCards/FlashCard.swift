import Foundation
import Combine

struct FlashCard: Identifiable, Codable {
    var id = UUID()
    let front: String  // Spanish
    let back: String   // English

    enum CodingKeys: String, CodingKey {
        case front, back
    }

    init(front: String, back: String) {
        self.front = front
        self.back = back
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.front = try container.decode(String.self, forKey: .front)
        self.back = try container.decode(String.self, forKey: .back)
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
            // Fallback to sample cards
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
