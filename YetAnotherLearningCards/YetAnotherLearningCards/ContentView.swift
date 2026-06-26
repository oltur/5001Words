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
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var cardStore = CardStore()
    @StateObject private var audioPlayer = AudioPlayer()
    @ObservedObject private var packManager = PackManager.shared
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

    var frontLabel: String { spanishFirst ? selectedDeck.sourceLanguage : selectedDeck.targetLanguage }
    var backLabel: String  { spanishFirst ? selectedDeck.targetLanguage : selectedDeck.sourceLanguage }

    var audioReady: Bool { packManager.isPackDownloaded(selectedDeck) }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.42, blue: 0.24).opacity(0.08),
                         Color(red: 0.18, green: 0.29, blue: 0.54).opacity(0.06)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

        VStack(spacing: 12) {
            // ── Branded header bar ──
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.10, green: 0.42, blue: 0.24),
                             Color(red: 0.18, green: 0.29, blue: 0.54)],
                    startPoint: .leading, endPoint: .trailing
                )

                HStack {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Image("AppIcon")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Text("5001 Words")
                            .font(.headline).fontWeight(.bold)
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    Button(action: { appearanceMode = appearanceMode.next }) {
                        Image(systemName: appearanceMode.icon)
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 52)

            // ── Deck picker ──
            Menu {
                ForEach(availableDecks.filter { packManager.isInstalled($0) }) { deck in
                    Button(action: { switchDeck(deck) }) {
                        HStack {
                            Text("\(deck.emoji) \(deck.name)")
                            if selectedDeckId == deck.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                if availableDecks.contains(where: { !packManager.isInstalled($0) }) {
                    Divider()
                    Button(action: { showSettings = true }) {
                        Label("Get more languages…", systemImage: "plus.circle")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedDeck.emoji)
                    Text(selectedDeck.name)
                        .font(.subheadline).fontWeight(.semibold)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.top, 10)

            if cardStore.cards.isEmpty {
                Spacer()
                ProgressView("Loading cards...")
                Spacer()
            } else if cardStore.displayCards.isEmpty {
                Spacer()
                completionView
                Spacer()
            } else {
                // Counter + status
                HStack(spacing: 6) {
                    Text("\(currentIndex + 1) / \(cardStore.displayCards.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if cardStore.isFocusModeOn {
                        Text("· Focus")
                            .font(.caption).foregroundStyle(.orange)
                    }
                    if cardStore.learnedCount > 0 {
                        Text("· \(cardStore.learnedCount) learned")
                            .font(.caption).foregroundStyle(.green)
                    }
                }

                // Direction picker
                Picker("Direction", selection: Binding(
                    get: { spanishFirst },
                    set: { spanishFirst = $0; isFlipped = false }
                )) {
                    Text("\(selectedDeck.emoji) → \(selectedDeck.targetEmoji)").tag(true)
                    Text("\(selectedDeck.targetEmoji) → \(selectedDeck.emoji)").tag(false)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // Flash card
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
                .frame(height: 220)
                .padding(.horizontal)
                .gesture(
                    DragGesture(minimumDistance: 40)
                        .onChanged { value in dragOffset = value.translation.width }
                        .onEnded { value in
                            let t: CGFloat = 40
                            if value.translation.width < -t {
                                withAnimation(.spring(duration: 0.25)) { dragOffset = -500 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    nextCard(); dragOffset = 500
                                    withAnimation(.spring(duration: 0.25)) { dragOffset = 0 }
                                }
                            } else if value.translation.width > t {
                                withAnimation(.spring(duration: 0.25)) { dragOffset = 500 }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    previousCard(); dragOffset = -500
                                    withAnimation(.spring(duration: 0.25)) { dragOffset = 0 }
                                }
                            } else {
                                withAnimation(.spring(duration: 0.25)) { dragOffset = 0 }
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    guard audioReady, let audioIndex = currentCard?.audioIndex else { return }
                    audioPlayer.play(audioIndex: audioIndex, subfolder: selectedDeck.audioFolder)
                }
                .onTapGesture {
                    withAnimation(.spring(duration: 0.3)) { isFlipped.toggle() }
                }

                // Action buttons
                HStack(spacing: 12) {
                    if let card = currentCard, let audioIndex = card.audioIndex {
                        Button(action: {
                            if audioReady {
                                audioPlayer.play(audioIndex: audioIndex, subfolder: selectedDeck.audioFolder)
                            } else {
                                showSettings = true
                            }
                        }) {
                            HStack {
                                Image(systemName: audioReady ? "speaker.wave.2.fill" : "arrow.down.circle")
                                Text(audioReady ? "Audio" : "Download")
                            }
                            .font(.headline)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(Color.orange.opacity(audioReady ? 0.2 : 0.08), in: RoundedRectangle(cornerRadius: 10))
                        }
                        .foregroundStyle(audioReady ? .primary : .secondary)
                    }

                    Button(action: markCurrentCardLearned) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Learned")
                        }
                        .font(.headline)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Color.green.opacity(0.2), in: RoundedRectangle(cornerRadius: 10))
                    }
                }

                // Navigation
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
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.bottom)
        .id(localizationManager.currentLanguage)
        .preferredColorScheme(appearanceMode.colorScheme)
        .onAppear { cardStore.loadCards(from: selectedDeck) }
        .onChange(of: cardStore.displayCards.count) {
            if currentIndex >= cardStore.displayCards.count {
                currentIndex = max(0, cardStore.displayCards.count - 1)
            }
        }
        .onChange(of: packManager.states[selectedDeckId]) { _, newState in
            if case .installed = newState {
                cardStore.loadCards(from: selectedDeck)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(cardStore: cardStore, packManager: packManager)
        }
        }
    }

    var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.fill")
                .font(.system(size: 60)).foregroundStyle(.yellow)
            if cardStore.isFocusModeOn {
                Text("Focus set complete!").font(.title2).fontWeight(.bold)
                Text("You've learned all words in your focus set.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
                Button("Pick new set of 20") { cardStore.pickNewFocusSet(); currentIndex = 0 }
                    .buttonStyle(.borderedProminent)
            } else {
                Text("All done!").font(.title2).fontWeight(.bold)
                Text("You've marked all \(cardStore.learnedCount) words as learned.")
                    .multilineTextAlignment(.center).foregroundStyle(.secondary)
            }
            Button("Open Settings") { showSettings = true }.buttonStyle(.bordered)
        }
        .padding()
    }

    func markCurrentCardLearned() {
        guard let card = currentCard else { return }
        cardStore.markLearned(card)
        isFlipped = false
        let newCount = cardStore.displayCards.count
        if currentIndex >= newCount { currentIndex = max(0, newCount - 1) }
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

    func playCurrentCardAudio() {
        guard autoPlay, audioReady, let audioIndex = currentCard?.audioIndex else { return }
        audioPlayer.play(audioIndex: audioIndex, subfolder: selectedDeck.audioFolder)
    }
}

// MARK: - Settings

struct SettingsView: View {
    @ObservedObject var cardStore: CardStore
    @ObservedObject var packManager: PackManager
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var showResetConfirm = false
    @State private var packToRemove: Deck? = nil
    @AppStorage("autoPlay") private var autoPlay: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Audio") {
                    Toggle("Auto-play word aloud", isOn: $autoPlay)
                }

                Section("Focus Mode") {
                    Toggle("Focus on 20 words", isOn: Binding(
                        get: { cardStore.isFocusModeOn },
                        set: { cardStore.setFocusMode($0) }
                    ))
                    if cardStore.isFocusModeOn {
                        Button("Pick new set of 20") { cardStore.pickNewFocusSet() }
                    }
                }

                Section("Progress") {
                    LabeledContent("Learned",   value: "\(cardStore.learnedCount)")
                    LabeledContent("Remaining", value: "\(cardStore.remainingCount)")
                    LabeledContent("Total",     value: "\(cardStore.totalCount)")
                }

                Section {
                    Button("Reset all progress", role: .destructive) { showResetConfirm = true }
                }

                Section(
                    header: Text("Language Packs"),
                    footer: Text("Each pack includes the word list and audio. Stored locally, not backed up to iCloud.")
                ) {
                    ForEach(availableDecks) { deck in
                        PackRowView(deck: deck, packManager: packManager) {
                            packToRemove = deck
                        }
                    }
                }

                Section("Language") {
                    Picker("Language", selection: $localizationManager.currentLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("About") {
                    NavigationLink("About", destination: ImpressumView())
                    NavigationLink("Privacy Policy", destination: PrivacyPolicyView())
                    Link(destination: URL(string: "mailto:5001words@turevskiy.com")!) {
                        Label("Contact / Feedback", systemImage: "envelope")
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
            .confirmationDialog("Reset all progress?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset", role: .destructive) { cardStore.resetLearned() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This clears all learned words and focus sets for this deck.")
            }
            .confirmationDialog(
                "Remove \(packToRemove?.name ?? "") pack?",
                isPresented: Binding(get: { packToRemove != nil }, set: { if !$0 { packToRemove = nil } }),
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    if let deck = packToRemove { packManager.remove(deck) }
                    packToRemove = nil
                }
                Button("Cancel", role: .cancel) { packToRemove = nil }
            } message: {
                Text("The word list and audio will be deleted. You can re-download anytime.")
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
            VStack(alignment: .leading, spacing: 2) {
                Text("\(deck.emoji) \(deck.name)")
                    .font(.body)
                Group {
                    if !deck.hasAudio {
                        Text("5,001 cards included · No audio")
                    } else if case .installed = packManager.states[deck.id] ?? .notDownloaded {
                        Text("5,001 cards + audio installed")
                    } else if deck.isBundled {
                        Text("5,001 cards included · Download for audio")
                    } else {
                        Text("5,001 cards + audio  ·  ~30 MB")
                    }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if deck.hasAudio {
                switch packManager.states[deck.id] ?? .notDownloaded {
                case .notDownloaded:
                    Button("Download") { packManager.download(deck) }
                        .buttonStyle(.borderless).foregroundStyle(.blue)
                case .downloading(let progress):
                    ProgressView(value: progress).frame(width: 60)
                    Text("\(Int(progress * 100))%")
                        .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                    Button(action: { packManager.cancelDownload(deck) }) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                case .installed:
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Button("Remove", role: .destructive, action: onRemove).buttonStyle(.borderless)
                case .failed(let msg):
                    Text("Failed").font(.caption).foregroundStyle(.red)
                    Button("Retry") { packManager.download(deck) }
                        .buttonStyle(.borderless).foregroundStyle(.blue).help(msg)
                }
            } else {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalizationManager.shared)
}
