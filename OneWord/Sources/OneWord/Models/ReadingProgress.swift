//
//  ReadingProgress.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftData

/// Gerencia o estado de progresso de leitura de um documento no OneWord.
/// Garante que o usuário retome a leitura exatamente da palavra onde parou.
@Model
public final class ReadingProgress {
    /// Identificador único universal do registro de progresso.
    public var id: UUID
    
    /// Índice baseado em zero da palavra atual no array de palavras do documento.
    public var currentWordIndex: Int
    
    /// Carimbo de data/hora da última atualização de leitura.
    public var lastUpdated: Date
    
    /// Relacionamento inverso com o documento proprietário.
    public var document: Document?
    
    /// Inicializador do progresso de leitura.
    /// - Parameters:
    ///   - id: Identificador único (default: novo UUID).
    ///   - currentWordIndex: Índice inicial da palavra (default: 0).
    ///   - lastUpdated: Data do registro (default: agora).
    ///   - document: Documento associado opcional.
    public init(
        id: UUID = UUID(),
        currentWordIndex: Int = 0,
        lastUpdated: Date = Date(),
        document: Document? = nil
    ) {
        self.id = id
        self.currentWordIndex = max(0, currentWordIndex)
        self.lastUpdated = lastUpdated
        self.document = document
    }
    
    /// Atualiza com segurança o índice atual, garantindo que não ultrapasse os limites.
    /// - Parameters:
    ///   - newIndex: Novo índice desejado.
    ///   - maxWords: Total de palavras disponíveis no documento.
    public func setIndex(_ newIndex: Int, maxWords: Int) {
        let upperBound = max(0, maxWords)
        self.currentWordIndex = min(max(0, newIndex), upperBound)
        self.lastUpdated = Date()
    }
    
    /// Reinicia o progresso para a primeira palavra.
    public func reset() {
        self.currentWordIndex = 0
        self.lastUpdated = Date()
    }
}
