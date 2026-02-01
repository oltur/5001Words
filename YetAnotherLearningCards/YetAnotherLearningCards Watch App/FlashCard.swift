import Foundation

struct FlashCard: Identifiable {
    let id = UUID()
    let front: String  // Spanish
    let back: String   // English
}

// Sample Spanish vocabulary
let sampleCards: [FlashCard] = [
    FlashCard(front: "Hola", back: "Hello"),
    FlashCard(front: "Gracias", back: "Thank you"),
    FlashCard(front: "Por favor", back: "Please"),
    FlashCard(front: "Buenos días", back: "Good morning"),
    FlashCard(front: "Buenas noches", back: "Good night"),
    FlashCard(front: "¿Cómo estás?", back: "How are you?"),
    FlashCard(front: "Muy bien", back: "Very well"),
    FlashCard(front: "Adiós", back: "Goodbye"),
    FlashCard(front: "Sí", back: "Yes"),
    FlashCard(front: "No", back: "No"),
    FlashCard(front: "Agua", back: "Water"),
    FlashCard(front: "Comida", back: "Food"),
    FlashCard(front: "Casa", back: "House"),
    FlashCard(front: "Familia", back: "Family"),
    FlashCard(front: "Amigo", back: "Friend")
]
