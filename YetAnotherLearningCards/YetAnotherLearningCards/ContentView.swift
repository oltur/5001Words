//
//  ContentView.swift
//  YetAnotherLearningCards
//
//  Created by Alexander Turevskiy on 01.02.26.
//

import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system, light, dark

    var next: AppearanceMode {
        switch self {
        case .system: return .light
        case .light:  return .dark
        case .dark:   return .system
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

struct ContentView: View {
    @StateObject private var cardStore = CardStore()
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var spanishFirst = true
    @State private var dragOffset: CGFloat = 0
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("selectedDeckId") private var selectedDeckId: String = "spanish"

    var selectedDeck: Deck {
        availableDecks.first { $0.id == selectedDeckId } ?? availableDecks[0]
    }

    var currentCard: FlashCard? {
        guard !cardStore.cards.isEmpty else { return nil }
        return cardStore.cards[currentIndex]
    }

    var frontText: String {
        guard let card = currentCard else { return "" }
        return spanishFirst ? card.front : card.back
    }

    var backText: String {
        guard let card = currentCard else { return "" }
        return spanishFirst ? card.back : card.front
    }

    var frontLabel: String { spanishFirst ? selectedDeck.name : "English" }
    var backLabel: String  { spanishFirst ? "English" : selectedDeck.name }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Flash Cards")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                // Appearance toggle
                Button(action: { appearanceMode = appearanceMode.next }) {
                    Image(systemName: appearanceMode.icon)
                        .font(.title3)
                }
                .padding(.trailing, 4)

                // Deck picker
                Menu {
                    ForEach(availableDecks) { deck in
                        Button(action: { switchDeck(deck) }) {
                            HStack {
                                Text(deck.emoji + " " + deck.name)
                                if selectedDeckId == deck.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(selectedDeck.emoji)
                        .font(.title3)
                }
                .padding(.trailing, 4)

                // Direction toggle
                Button(action: toggleDirection) {
                    HStack(spacing: 4) {
                        Text(spanishFirst ? selectedDeck.emoji : "🇬🇧")
                        Image(systemName: "arrow.right")
                        Text(spanishFirst ? "🇬🇧" : selectedDeck.emoji)
                    }
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)

            if cardStore.cards.isEmpty {
                ProgressView("Loading cards...")
            } else {
                Text("\(currentIndex + 1) / \(cardStore.cards.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Flash Card
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isFlipped ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                        .shadow(radius: 5)

                    VStack(spacing: 10) {
                        Text(isFlipped ? backLabel : frontLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(isFlipped ? backText : frontText)
                            .font(.title)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .padding()
                            .minimumScaleFactor(0.5)
                    }
                }
                .offset(x: dragOffset)
                .frame(height: 250)
                .padding(.horizontal)
                .gesture(
                    DragGesture(minimumDistance: 40)
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 40
                            if value.translation.width < -threshold {
                                withAnimation(.spring(duration: 0.25)) { dragOffset = -500 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    nextCard()
                                    dragOffset = 500
                                    withAnimation(.spring(duration: 0.25)) { dragOffset = 0 }
                                }
                            } else if value.translation.width > threshold {
                                withAnimation(.spring(duration: 0.25)) { dragOffset = 500 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    previousCard()
                                    dragOffset = -500
                                    withAnimation(.spring(duration: 0.25)) { dragOffset = 0 }
                                }
                            } else {
                                withAnimation(.spring(duration: 0.25)) { dragOffset = 0 }
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    if let audioIndex = currentCard?.audioIndex {
                        audioPlayer.play(audioIndex: audioIndex, subfolder: selectedDeck.audioFolder)
                    }
                }
                .onTapGesture {
                    withAnimation(.spring(duration: 0.3)) {
                        isFlipped.toggle()
                    }
                }

                // Audio button
                if let card = currentCard, let audioIndex = card.audioIndex {
                    Button(action: { audioPlayer.play(audioIndex: audioIndex, subfolder: selectedDeck.audioFolder) }) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                            Text("Play Audio")
                        }
                        .font(.headline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(10)
                    }
                }

                HStack(spacing: 12) {
                    Label("Flip", systemImage: "hand.tap")
                    Label("Audio", systemImage: "hand.tap.fill")
                    Label("Navigate", systemImage: "hand.draw")
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // Navigation buttons
                HStack(spacing: 40) {
                    Button(action: previousCard) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 50))
                    }
                    .disabled(currentIndex == 0)

                    Button(action: shuffleCards) {
                        Image(systemName: "shuffle.circle.fill")
                            .font(.system(size: 50))
                    }

                    Button(action: nextCard) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.system(size: 50))
                    }
                    .disabled(currentIndex == cardStore.cards.count - 1)
                }
                .padding(.top)
            }
        }
        .padding()
        .preferredColorScheme(appearanceMode.colorScheme)
        .onAppear { cardStore.loadCards(from: selectedDeck) }
    }

    func switchDeck(_ deck: Deck) {
        selectedDeckId = deck.id
        currentIndex = 0
        isFlipped = false
        spanishFirst = true
        cardStore.loadCards(from: deck)
    }

    func previousCard() {
        if currentIndex > 0 {
            isFlipped = false
            currentIndex -= 1
        }
    }

    func nextCard() {
        if currentIndex < cardStore.cards.count - 1 {
            isFlipped = false
            currentIndex += 1
        }
    }

    func shuffleCards() {
        cardStore.cards.shuffle()
        currentIndex = 0
        isFlipped = false
    }

    func toggleDirection() {
        spanishFirst.toggle()
        isFlipped = false
    }
}

#Preview {
    ContentView()
}
