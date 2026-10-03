//
//  DocumentContent.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftData

/// Representa o conteúdo textual processado de um documento na biblioteca do OneWord.
/// Armazena tanto o texto bruto unificado quanto a sequência ordenada de palavras para o motor RSVP.
@Model
public final class DocumentContent {
    /// Identificador único universal do registro de conteúdo.
    public var id: UUID
    
    /// Texto integral processado e limpo, sem quebras de linha espúrias.
    public var rawText: String
    
    /// Sequência ordenada de tokens/palavras prontas para apresentação serial no leitor RSVP.
    /// Preserva pontuações de sufixo (ex: "olá,", "mundo!") para cálculo de pausas cognitivas.
    public var words: [String]
    
    /// Relacionamento inverso com o documento proprietário.
    public var document: Document?
    
    /// Inicializador padrão de conteúdo.
    /// - Parameters:
    ///   - id: Identificador único (default: novo UUID).
    ///   - rawText: Texto integral do documento.
    ///   - words: Array com as palavras tokenizadas.
    ///   - document: Documento associado opcional.
    public init(
        id: UUID = UUID(),
        rawText: String = "",
        words: [String] = [],
        document: Document? = nil
    ) {
        self.id = id
        self.rawText = rawText
        self.words = words
        self.document = document
    }
}
