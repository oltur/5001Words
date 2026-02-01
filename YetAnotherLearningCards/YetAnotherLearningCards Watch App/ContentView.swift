//
//  ContentView.swift
//  YetAnotherLearningCards Watch App
//
//  Created by Alexander Turevskiy on 01.02.26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var cardStore = CardStore()
    @State private var currentIndex = 0
    @State private var isFlipped = false

    var currentCard: FlashCard? {
        guard !cardStore.cards.isEmpty else { return nil }
        return cardStore.cards[currentIndex]
    }

    var body: some View {
        VStack(spacing: 6) {
            if cardStore.cards.isEmpty {
                ProgressView()
            } else {
                Text("\(currentIndex + 1)/\(cardStore.cards.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                // Flash Card
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isFlipped ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))

                    VStack(spacing: 2) {
                        Text(isFlipped ? "EN" : "ES")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if let card = currentCard {
                            Text(isFlipped ? card.back : card.front)
                                .font(.footnote)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.4)
                                .lineLimit(4)
                        }
                    }
                    .padding(6)
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
}

#Preview {
    ContentView()
}
