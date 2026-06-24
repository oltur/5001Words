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
    @State private var spanishFirst = true  // Direction: true = ES→EN, false = EN→ES
    @State private var dragOffset: CGFloat = 0
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

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

    var frontLabel: String {
        spanishFirst ? "ES" : "EN"
    }

    var backLabel: String {
        spanishFirst ? "EN" : "ES"
    }

    var body: some View {
        VStack(spacing: 4) {
            if cardStore.cards.isEmpty {
                ProgressView()
            } else {
                // Direction toggle + count
                HStack {
                    Button(action: toggleDirection) {
                        HStack(spacing: 2) {
                            Text(spanishFirst ? "ES" : "EN")
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                            Text(spanishFirst ? "EN" : "ES")
                        }
                        .font(.caption2)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Audio button
                    if let card = currentCard, let audioIndex = card.audioIndex {
                        Button(action: { audioPlayer.play(audioIndex: audioIndex) }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.orange)
                    }

                    Button(action: { appearanceMode = appearanceMode.next }) {
                        Image(systemName: appearanceMode.icon)
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)

                    Text("\(currentIndex + 1)/\(cardStore.cards.count)")
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
                        audioPlayer.play(audioIndex: audioIndex)
                    }
                }
                .onTapGesture {
                    withAnimation(.spring(duration: 0.2)) {
                        isFlipped.toggle()
                    }
                }

                // Navigation buttons
                HStack(spacing: 15) {
                    Button(action: previousCard) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(currentIndex == 0)

                    Button(action: shuffleCards) {
                        Image(systemName: "shuffle")
                    }

                    Button(action: nextCard) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentIndex == cardStore.cards.count - 1)
                }
                .font(.body)
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
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
