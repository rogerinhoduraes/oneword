//
//  FlashcardReviewView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI

/// Interface de estudo e revisão ativa de cartões mnemônicos com rotação 3D e repetição espaçada.
public struct FlashcardReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var service = FlashcardService.shared
    
    @State private var currentIndex: Int = 0
    @State private var isFlipped: Bool = false
    @State private var isCompleted: Bool = false
    
    public let filterSourceTitle: String?
    
    public init(filterSourceTitle: String? = nil) {
        self.filterSourceTitle = filterSourceTitle
    }
    
    private var cardsToReview: [Flashcard] {
        let all: [Flashcard]
        if let filter = filterSourceTitle {
            all = service.flashcards.filter { $0.sourceTitle == filter }
        } else {
            all = service.flashcards
        }
        let due = all.filter { $0.isDue }
        return due.isEmpty ? all : due
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if isCompleted || cardsToReview.isEmpty {
                    completedView
                } else {
                    reviewHeader
                    Spacer()
                    flashcardCardView(card: cardsToReview[currentIndex])
                    Spacer()
                    if isFlipped {
                        ratingButtons
                    } else {
                        tapToRevealPrompt
                    }
                }
            }
            .padding()
            .navigationTitle("Revisão de Foco")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var reviewHeader: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Cartão \(currentIndex + 1) de \(cardsToReview.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(cardsToReview[currentIndex].sourceTitle)
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
            }
            ProgressView(value: Double(currentIndex), total: Double(cardsToReview.count))
        }
    }
    
    // MARK: - Cartão 3D
    
    private func flashcardCardView(card: Flashcard) -> some View {
        ZStack {
            // Face da Frente (Pergunta)
            cardFace(
                tag: String(localized: "PERGUNTA / TERMO"),
                systemImage: "questionmark.circle.fill",
                accentColor: .blue,
                text: card.front
            )
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0.0, y: 1.0, z: 0.0)
            )
            .accessibilityHidden(isFlipped)
            
            // Face do Verso (Resposta)
            cardFace(
                tag: String(localized: "RESPOSTA / CONCEITO"),
                systemImage: "brain.head.profile",
                accentColor: .green,
                text: card.back
            )
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : -180),
                axis: (x: 0.0, y: 1.0, z: 0.0)
            )
            .accessibilityHidden(!isFlipped)
        }
        .frame(height: 320)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isFlipped.toggle()
            }
        }
    }
    
    private func cardFace(tag: String, systemImage: String, accentColor: Color, text: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(uiColorOrFallback: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
            
            VStack(spacing: 16) {
                HStack {
                    Label(tag, systemImage: systemImage)
                        .font(.caption2.bold())
                        .foregroundStyle(accentColor)
                    Spacer()
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(text)
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal)
                
                Spacer()
                
                Text("Toque no cartão para virar")
                    .font(.caption2)
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .padding(24)
        }
    }
    
    // MARK: - Botões de Avaliação SM-2
    
    private var tapToRevealPrompt: some View {
        Button {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isFlipped = true
            }
        } label: {
            Text("Mostrar Resposta")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
    
    private var ratingButtons: some View {
        VStack(spacing: 10) {
            Text("Como foi lembrar deste conceito?")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 10) {
                ratingButton(title: String(localized: "Esqueci"), rating: .again, color: .red)
                ratingButton(title: String(localized: "Difícil"), rating: .hard, color: .orange)
                ratingButton(title: String(localized: "Bom"), rating: .good, color: .blue)
                ratingButton(title: String(localized: "Fácil"), rating: .easy, color: .green)
            }
        }
    }
    
    private func ratingButton(title: String, rating: FlashcardRating, color: Color) -> some View {
        Button {
            rateCurrentCard(rating: rating)
        } label: {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func rateCurrentCard(rating: FlashcardRating) {
        let card = cardsToReview[currentIndex]
        service.reviewCard(id: card.id, rating: rating)
        
        isFlipped = false
        if currentIndex + 1 < cardsToReview.count {
            currentIndex += 1
        } else {
            isCompleted = true
        }
    }
    
    // MARK: - Tela Concluída
    
    private var completedView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            
            Text("Revisão Concluída!")
                .font(.title2.bold())
            
            Text("Todos os conceitos programados para hoje foram consolidados na memória de longo prazo.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            Button("Finalizar") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.blue)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

private extension Color {
    init(uiColorOrFallback: UIColorType) {
        #if canImport(UIKit)
        switch uiColorOrFallback {
        case .secondarySystemGroupedBackground:
            self.init(uiColor: .secondarySystemGroupedBackground)
        }
        #else
        self.init(.controlBackgroundColor)
        #endif
    }
    
    enum UIColorType {
        case secondarySystemGroupedBackground
    }
}
