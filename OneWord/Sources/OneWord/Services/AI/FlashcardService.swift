//
//  FlashcardService.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import Observation

/// Gerenciador de cartões de estudo e repetição espaçada no OneWord.
@Observable
@MainActor
public final class FlashcardService {
    public static let shared = FlashcardService()
    
    private let kFlashcardsStorage = "oneword_stored_flashcards"
    public var flashcards: [Flashcard] = []
    
    public init() {
        loadFlashcards()
    }
    
    public var dueFlashcards: [Flashcard] {
        flashcards.filter { $0.isDue }
    }
    
    public var dueCount: Int {
        dueFlashcards.count
    }
    
    /// Gera cartões de memória automáticos a partir do conteúdo textual de um livro ou artigo.
    public func generateFlashcards(from text: String, sourceTitle: String) -> [Flashcard] {
        var created: [Flashcard] = []
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 25 }
        
        let definitionTriggers = [
            " é ", " são ", " significa ", " consiste em ", " refere-se a ",
            " define-se como ", " funciona como ", " tem como objetivo "
        ]
        
        for sentence in sentences {
            for trigger in definitionTriggers {
                if let range = sentence.range(of: trigger, options: .caseInsensitive) {
                    let term = String(sentence[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let definition = String(sentence[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if term.count >= 3 && term.count <= 45 && definition.count >= 15 {
                        let card = Flashcard(
                            front: "O que é: \(term)?",
                            back: "\(term.capitalized) \(trigger.trimmingCharacters(in: .whitespaces)) \(definition).",
                            sourceTitle: sourceTitle
                        )
                        created.append(card)
                        break
                    }
                }
            }
            if created.count >= 6 { break }
        }
        
        // Se encontrou termos definidos, adiciona aos salvos
        if !created.isEmpty {
            for card in created {
                if !flashcards.contains(where: { $0.front == card.front }) {
                    flashcards.append(card)
                }
            }
            saveFlashcards()
        }
        
        return created
    }
    
    /// Registra a resposta a um cartão atualizando seus intervalos de agendamento.
    public func reviewCard(id: UUID, rating: FlashcardRating) {
        guard let index = flashcards.firstIndex(where: { $0.id == id }) else { return }
        flashcards[index].review(rating: rating)
        saveFlashcards()
    }
    
    // MARK: - Persistência
    
    private func saveFlashcards() {
        if let data = try? JSONEncoder().encode(flashcards) {
            UserDefaults.standard.set(data, forKey: kFlashcardsStorage)
        }
    }
    
    private func loadFlashcards() {
        guard let data = UserDefaults.standard.data(forKey: kFlashcardsStorage),
              let list = try? JSONDecoder().decode([Flashcard].self, from: data) else {
            return
        }
        self.flashcards = list
    }
}
