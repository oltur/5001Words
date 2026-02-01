//
//  ContentView.swift
//  YetAnotherLearningCards Watch App
//
//  Created by Alexander Turevskiy on 01.02.26.
//

import SwiftUI

struct ContentView: View {
    @State private var currentIndex = 0
    @State private var isFlipped = false

    var currentCard: FlashCard {
        sampleCards[currentIndex]
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("\(currentIndex + 1)/\(sampleCards.count)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Flash Card
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isFlipped ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))

                VStack(spacing: 4) {
                    Text(isFlipped ? "EN" : "ES")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(isFlipped ? currentCard.back : currentCard.front)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                }
                .padding(8)
            }
            .onTapGesture {
                withAnimation(.spring(duration: 0.2)) {
                    isFlipped.toggle()
                }
            }

            // Navigation buttons
            HStack(spacing: 20) {
                Button(action: previousCard) {
                    Image(systemName: "chevron.left")
                }
                .disabled(currentIndex == 0)

                Button(action: nextCard) {
                    Image(systemName: "chevron.right")
                }
                .disabled(currentIndex == sampleCards.count - 1)
            }
            .font(.title3)
        }
    }

    func previousCard() {
        if currentIndex > 0 {
            isFlipped = false
            currentIndex -= 1
        }
    }

    func nextCard() {
        if currentIndex < sampleCards.count - 1 {
            isFlipped = false
            currentIndex += 1
        }
    }
}

#Preview {
    ContentView()
}
