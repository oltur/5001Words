//
//  ContentView.swift
//  YetAnotherLearningCards Watch App
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
    @State private var showSettings = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("selectedDeckId") private var selectedDeckId: String = "spanish"
    @AppStorage("autoPlay") private var autoPlay: Bool = false

    var selectedDeck: Deck {
        availableDecks.first { $0.id == selectedDeckId } ?? availableDecks[0]
    }

    var currentCard: FlashCard? {
        let dc = cardStore.displayCards
        guard !dc.isEmpty else { return nil }
        return dc[min(currentIndex, dc.count - 1)]
    }

    var frontText: String {
        guard let card = currentCard else { return "" }
        return spanishFirst ? card.front : card.back
    }

    var backText: String {
        guard let card = currentCard else { return "" }
        return spanishFirst ? card.back : card.front
    }

    var frontLabel: String { spanishFirst ? selectedDeck.emoji : selectedDeck.targetEmoji }
    var backLabel: String  { spanishFirst ? selectedDeck.targetEmoji : selectedDeck.emoji }

    var body: some View {
        VStack(spacing: 4) {
            if cardStore.cards.isEmpty {
                ProgressView()
            } else if cardStore.displayCards.isEmpty {
                completionView
            } else {
                HStack {
                    // Direction toggle
                    Button(action: toggleDirection) {
                        HStack(spacing: 2) {
                            Text(spanishFirst ? selectedDeck.emoji : selectedDeck.targetEmoji)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                            Text(spanishFirst ? selectedDeck.targetEmoji : selectedDeck.emoji)
                        }
                        .font(.caption2)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Audio button
                    if let card = currentCard, let audioIndex = card.audioIndex {
                        Button(action: { audioPlayer.play(audioIndex: audioIndex, subfolder: selectedDeck.audioFolder) }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.orange)
                    }

                    // Appearance toggle
                    Button(action: { appearanceMode = appearanceMode.next }) {
                        Image(systemName: appearanceMode.icon)
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)

                    // Deck cycle button
                    Button(action: cycleNextDeck) {
                        Text(selectedDeck.emoji)
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)

                    // Settings button
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)

                    Text("\(currentIndex + 1)/\(cardStore.displayCards.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // Flash Card
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isFlipped ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))

                    VStack(spacing: 2) {
                        Text(isFlipped ? backLabel : frontLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(isFlipped ? backText : frontText)
                            .font(.footnote)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.4)
                            .lineLimit(4)
                    }
                    .padding(6)
                }
                .offset(x: dragOffset)
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onChanged { value in
                            dragOffset = value.translation.width
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 30
                            if value.translation.width < -threshold {
                                withAnimation(.spring(duration: 0.2)) { dragOffset = -200 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    nextCard()
                                    dragOffset = 200
                                    withAnimation(.spring(duration: 0.2)) { dragOffset = 0 }
                                }
                            } else if value.translation.width > threshold {
                                withAnimation(.spring(duration: 0.2)) { dragOffset = 200 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    previousCard()
                                    dragOffset = -200
                                    withAnimation(.spring(duration: 0.2)) { dragOffset = 0 }
                                }
                            } else {
                                withAnimation(.spring(duration: 0.2)) { dragOffset = 0 }
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    if let audioIndex = currentCard?.audioIndex {
                        audioPlayer.play(audioIndex: audioIndex, subfolder: selectedDeck.audioFolder)
                    }
                }
                .onTapGesture {
                    withAnimation(.spring(duration: 0.2)) {
                        isFlipped.toggle()
                    }
                }

                // Navigation buttons
                HStack(spacing: 12) {
                    Button(action: previousCard) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentIndex == 0)

                    Button(action: shuffleCards) {
                        Image(systemName: "shuffle")
                    }

                    // Mark as learned
                    Button(action: markCurrentCardLearned) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }

                    Button(action: nextCard) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentIndex >= cardStore.displayCards.count - 1)
                }
                .font(.body)
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
        .onAppear { cardStore.loadCards(from: selectedDeck) }
        .onChange(of: cardStore.displayCards.count) { _ in
            if currentIndex >= cardStore.displayCards.count {
                currentIndex = max(0, cardStore.displayCards.count - 1)
            }
        }
        .sheet(isPresented: $showSettings) {
            WatchSettingsView(cardStore: cardStore)
        }
    }

    var completionView: some View {
        ScrollView {
            VStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.title2)
                    .foregroundStyle(.yellow)
                if cardStore.isFocusModeOn {
                    Text("Focus complete!")
                        .font(.headline)
                    Button("New set") {
                        cardStore.pickNewFocusSet()
                        currentIndex = 0
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                } else {
                    Text("All done!")
                        .font(.headline)
                    Text("\(cardStore.learnedCount) learned")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Button("Settings") { showSettings = true }
                    .buttonStyle(.bordered)
            }
            .padding()
        }
    }

    func markCurrentCardLearned() {
        guard let card = currentCard else { return }
        cardStore.markLearned(card)
        isFlipped = false
        let newCount = cardStore.displayCards.count
        if currentIndex >= newCount {
            currentIndex = max(0, newCount - 1)
        }
    }

    func cycleNextDeck() {
        let ids = availableDecks.map(\.id)
        guard let current = ids.firstIndex(of: selectedDeckId) else { return }
        let next = availableDecks[(current + 1) % availableDecks.count]
        switchDeck(next)
    }

    func switchDeck(_ deck: Deck) {
        selectedDeckId = deck.id
        currentIndex = 0; isFlipped = false; spanishFirst = true
        cardStore.loadCards(from: deck)
        playCurrentCardAudio()
    }

    func previousCard() {
        if currentIndex > 0 { isFlipped = false; currentIndex -= 1; playCurrentCardAudio() }
    }

    func nextCard() {
        if currentIndex < cardStore.displayCards.count - 1 { isFlipped = false; currentIndex += 1; playCurrentCardAudio() }
    }

    func shuffleCards() {
        cardStore.cards.shuffle(); currentIndex = 0; isFlipped = false; playCurrentCardAudio()
    }

    func toggleDirection() {
        spanishFirst.toggle()
        isFlipped = false
    }

    func playCurrentCardAudio() {
        guard autoPlay, let audioIndex = currentCard?.audioIndex else { return }
        audioPlayer.play(audioIndex: audioIndex, subfolder: selectedDeck.audioFolder)
    }
}

struct WatchSettingsView: View {
    @ObservedObject var cardStore: CardStore
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false
    @AppStorage("autoPlay") private var autoPlay: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Settings")
                    .font(.headline)

                Toggle("Auto-play", isOn: $autoPlay)

                Toggle("Focus 20", isOn: Binding(
                    get: { cardStore.isFocusModeOn },
                    set: { cardStore.setFocusMode($0) }
                ))

                if cardStore.isFocusModeOn {
                    Button("New set of 20") { cardStore.pickNewFocusSet() }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                }

                Divider()

                VStack(spacing: 4) {
                    Text("Learned: \(cardStore.learnedCount)")
                        .font(.caption2)
                    Text("Left: \(cardStore.remainingCount)")
                        .font(.caption2)
                    Text("Total: \(cardStore.totalCount)")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)

                Divider()

                Button("Reset progress") {
                    showResetConfirm = true
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding()
        }
        .confirmationDialog("Reset?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) {
                cardStore.resetLearned()
                dismiss()
            }
        }
    }
}

#Preview {
    ContentView()
}
