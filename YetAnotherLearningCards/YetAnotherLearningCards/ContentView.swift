//
//  ContentView.swift
//  YetAnotherLearningCards
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
        VStack(spacing: 30) {
            Text("Spanish Flash Cards")
                .font(.title2)
                .fontWeight(.bold)

            Text("\(currentIndex + 1) / \(sampleCards.count)")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Flash Card
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(isFlipped ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                    .shadow(radius: 5)

                VStack(spacing: 10) {
                    Text(isFlipped ? "English" : "Spanish")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(isFlipped ? currentCard.back : currentCard.front)
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding()
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

                Button(action: nextCard) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.system(size: 50))
                }
                .disabled(currentIndex == sampleCards.count - 1)
            }
            .padding(.top)
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
        if currentIndex < sampleCards.count - 1 {
            isFlipped = false
            currentIndex += 1
        }
    }
}

#Preview {
    ContentView()
}
