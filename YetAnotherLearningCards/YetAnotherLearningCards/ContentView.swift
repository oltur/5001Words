//
//  ContentView.swift
//  YetAnotherLearningCards
//
//  Created by Alexander Turevskiy on 01.02.26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var cardStore = CardStore()
    @State private var currentIndex = 0
    @State private var isFlipped = false
    @State private var spanishFirst = true  // Direction: true = ES→EN, false = EN→ES

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
        spanishFirst ? "Spanish" : "English"
    }

    var backLabel: String {
        spanishFirst ? "English" : "Spanish"
    }

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Flash Cards")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                // Direction toggle
                Button(action: toggleDirection) {
                    HStack(spacing: 4) {
                        Text(spanishFirst ? "ES" : "EN")
                            .fontWeight(.bold)
                        Image(systemName: "arrow.right")
                        Text(spanishFirst ? "EN" : "ES")
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
                .frame(height: 250)
                .padding(.horizontal)
                .onTapGesture {
                    withAnimation(.spring(duration: 0.3)) {
                        isFlipped.toggle()
                    }
                }

                Text("Tap card to flip")
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
