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
    @StateObject private var packManager = PackManager.shared
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var spanishFirst = true
    @State private var dragOffset: CGFloat = 0
    @State private var showSettings = false
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("selectedDeckId") private var selectedDeckId: String = "spanish"

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

    var frontLabel: String { spanishFirst ? selectedDeck.name : "English" }
    var backLabel: String  { spanishFirst ? "English" : selectedDeck.name }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                // Hamburger → settings
                Button(action: { showSettings = true }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title3)
                }
                .padding(.trailing, 4)

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
            } else if cardStore.displayCards.isEmpty {
                completionView
            } else {
                let displayCount = cardStore.displayCards.count
                HStack(spacing: 6) {
                    Text("\(currentIndex + 1) / \(displayCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if cardStore.isFocusModeOn {
                        Text("· Focus")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if cardStore.learnedCount > 0 {
                        Text("· \(cardStore.learnedCount) learned")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

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

                // Action buttons row
                HStack(spacing: 12) {
                    // Audio button
                    if let card = currentCard, let audioIndex = card.audioIndex {
                        let audioReady = packManager.isInstalled(selectedDeck)
                        Button(action: {
                            if audioReady {
                                audioPlayer.play(audioIndex: audioIndex, subfolder: selectedDeck.audioFolder)
                            } else {
                                showSettings = true
                            }
                        }) {
                            HStack {
                                Image(systemName: audioReady ? "speaker.wave.2.fill" : "arrow.down.circle")
                                Text(audioReady ? "Audio" : "Download Audio")
                            }
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.orange.opacity(audioReady ? 0.2 : 0.08))
                            .cornerRadius(10)
                        }
                        .foregroundStyle(audioReady ? .primary : .secondary)
                    }

                    // Mark as learned
                    Button(action: markCurrentCardLearned) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Learned")
                        }
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.2))
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
                    .disabled(currentIndex >= cardStore.displayCards.count - 1)
                }
                .padding(.top)
            }
        }
        .padding()
        .preferredColorScheme(appearanceMode.colorScheme)
        .onAppear { cardStore.loadCards(from: selectedDeck) }
        .onChange(of: cardStore.displayCards.count) {
            if currentIndex >= cardStore.displayCards.count {
                currentIndex = max(0, cardStore.displayCards.count - 1)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(cardStore: cardStore, packManager: packManager)
        }
    }

    var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
            if cardStore.isFocusModeOn {
                Text("Focus set complete!")
                    .font(.title2).fontWeight(.bold)
                Text("You've learned all words in your focus set.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("Pick new set of 20") {
                    cardStore.pickNewFocusSet()
                    currentIndex = 0
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("All done!")
                    .font(.title2).fontWeight(.bold)
                Text("You've marked all \(cardStore.learnedCount) words as learned.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            Button("Open Settings") { showSettings = true }
                .buttonStyle(.bordered)
        }
        .padding()
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
        if currentIndex < cardStore.displayCards.count - 1 {
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

struct SettingsView: View {
    @ObservedObject var cardStore: CardStore
    @ObservedObject var packManager: PackManager
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false
    @State private var packToRemove: Deck? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Focus Mode") {
                    Toggle("Focus on 20 words", isOn: Binding(
                        get: { cardStore.isFocusModeOn },
                        set: { cardStore.setFocusMode($0) }
                    ))
                    if cardStore.isFocusModeOn {
                        Button("Pick new set of 20") {
                            cardStore.pickNewFocusSet()
                        }
                    }
                }

                Section("Progress") {
                    LabeledContent("Learned", value: "\(cardStore.learnedCount)")
                    LabeledContent("Remaining", value: "\(cardStore.remainingCount)")
                    LabeledContent("Total", value: "\(cardStore.totalCount)")
                }

                Section {
                    Button("Reset all progress", role: .destructive) {
                        showResetConfirm = true
                    }
                }

                Section(
                    header: Text("Language Packs"),
                    footer: Text("Downloaded packs are stored locally and never backed up to iCloud.")
                ) {
                    ForEach(availableDecks.filter { packDownloadURLs[$0.id] != nil }) { deck in
                        PackRowView(deck: deck, packManager: packManager) {
                            packToRemove = deck
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Reset all progress?",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) { cardStore.resetLearned() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears all learned words and focus sets for this deck.")
            }
            .confirmationDialog(
                "Remove \(packToRemove?.name ?? "") audio pack?",
                isPresented: Binding(get: { packToRemove != nil }, set: { if !$0 { packToRemove = nil } }),
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    if let deck = packToRemove { packManager.remove(deck) }
                    packToRemove = nil
                }
                Button("Cancel", role: .cancel) { packToRemove = nil }
            } message: {
                Text("Audio will need to be downloaded again to play pronunciations.")
            }
        }
    }
}

struct PackRowView: View {
    let deck: Deck
    @ObservedObject var packManager: PackManager
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Text(deck.emoji + " " + deck.name)
            Spacer()
            switch packManager.states[deck.id] ?? .notDownloaded {
            case .notDownloaded:
                Button("Download") { packManager.download(deck) }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.blue)
            case .downloading(let progress):
                ProgressView(value: progress)
                    .frame(width: 70)
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Button(action: { packManager.cancelDownload(deck) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
            case .installed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Button("Remove", role: .destructive, action: onRemove)
                    .buttonStyle(.borderless)
            case .failed(let msg):
                Text("Failed")
                    .font(.caption)
                    .foregroundStyle(.red)
                Button("Retry") { packManager.download(deck) }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.blue)
                    .help(msg)
            }
        }
    }
}

#Preview {
    ContentView()
}
