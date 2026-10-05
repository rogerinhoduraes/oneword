//
//  Flashcard.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation

/// Avaliação de recall na repetição espaçada.
public enum FlashcardRating: Int, Sendable, Codable {
    case again = 0  // Esqueci (reinicia ciclo)
    case hard = 1   // Difícil (intervalo curto)
    case good = 2   // Bom (avança intervalo normal)
    case easy = 3   // Fácil (avança intervalo acelerado)
}

/// Cartão de estudo mnemônico com repetição espaçada (Algoritmo SuperMemo SM-2).
public struct Flashcard: Identifiable, Sendable, Codable, Equatable {
    public var id: UUID
    public var front: String
    public var back: String
    public var sourceTitle: String
    public var intervalDays: Int
    public var easeFactor: Double
    public var repetitionCount: Int
    public var nextReviewDate: Date
    public var lastReviewedAt: Date?
    
    public init(
        id: UUID = UUID(),
        front: String,
        back: String,
        sourceTitle: String,
        intervalDays: Int = 1,
        easeFactor: Double = 2.5,
        repetitionCount: Int = 0,
        nextReviewDate: Date = Date(),
        lastReviewedAt: Date? = nil
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.sourceTitle = sourceTitle
        self.intervalDays = intervalDays
        self.easeFactor = easeFactor
        self.repetitionCount = repetitionCount
        self.nextReviewDate = nextReviewDate
        self.lastReviewedAt = lastReviewedAt
    }
    
    /// Aplica a avaliação do usuário atualizando os parâmetros do SM-2.
    public mutating func review(rating: FlashcardRating) {
        self.lastReviewedAt = Date()
        
        switch rating {
        case .again:
            self.repetitionCount = 0
            self.intervalDays = 1
            self.easeFactor = max(1.3, easeFactor - 0.2)
        case .hard:
            self.repetitionCount += 1
            self.intervalDays = max(1, Int(Double(intervalDays) * 1.2))
            self.easeFactor = max(1.3, easeFactor - 0.15)
        case .good:
            self.repetitionCount += 1
            if repetitionCount == 1 {
                self.intervalDays = 1
            } else if repetitionCount == 2 {
                self.intervalDays = 4
            } else {
                self.intervalDays = Int(Double(intervalDays) * easeFactor)
            }
        case .easy:
            self.repetitionCount += 1
            if repetitionCount == 1 {
                self.intervalDays = 3
            } else if repetitionCount == 2 {
                self.intervalDays = 7
            } else {
                self.intervalDays = Int(Double(intervalDays) * easeFactor * 1.3)
            }
            self.easeFactor += 0.15
        }
        
        let calendar = Calendar.current
        self.nextReviewDate = calendar.date(byAdding: .day, value: intervalDays, to: Date()) ?? Date()
    }
    
    /// Indica se o cartão está pronto para revisão hoje.
    public var isDue: Bool {
        let calendar = Calendar.current
        return calendar.startOfDay(for: nextReviewDate) <= calendar.startOfDay(for: Date())
    }
}
