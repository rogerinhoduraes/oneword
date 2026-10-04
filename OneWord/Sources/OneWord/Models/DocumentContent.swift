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
    
    /// Código ISO do idioma original detectado (ex: "en", "es", "fr").
    public var originalLanguage: String?
    
    /// Texto completo traduzido para Português.
    public var translatedText: String?
    
    /// Palavras tokenizadas do texto traduzido para leitura RSVP bilíngue.
    public var translatedWords: [String]?
    
    /// Flag que indica se o conteúdo atualmente apresentado é a versão traduzida.
    public var isShowingTranslation: Bool = false
    
    /// Relacionamento inverso com o documento proprietário.
    public var document: Document?
    
    /// Inicializador padrão de conteúdo.
    /// - Parameters:
    ///   - id: Identificador único (default: novo UUID).
    ///   - rawText: Texto integral do documento.
    ///   - words: Array com as palavras tokenizadas.
    ///   - originalLanguage: Código de idioma opcional.
    ///   - document: Documento associado opcional.
    public init(
        id: UUID = UUID(),
        rawText: String = "",
        words: [String] = [],
        originalLanguage: String? = nil,
        document: Document? = nil
    ) {
        self.id = id
        self.rawText = rawText
        self.words = words
        self.originalLanguage = originalLanguage
        self.document = document
    }
    
    // MARK: - Propriedades Dinâmicas de Leitura
    
    /// Retorna as palavras ativas para leitura serial: se a tradução estiver ativada, retorna as traduzidas;
    /// caso contrário, retorna as palavras no idioma original.
    public var activeWords: [String] {
        if isShowingTranslation, let translatedWords, !translatedWords.isEmpty {
            return translatedWords
        }
        return words
    }
    
    /// Retorna o texto ativo (original ou traduzido).
    public var activeRawText: String {
        if isShowingTranslation, let translatedText, !translatedText.isEmpty {
            return translatedText
        }
        return rawText
    }
    
    /// Define a tradução para Português deste documento.
    public func setTranslation(text: String, words: [String]) {
        self.translatedText = text
        self.translatedWords = words
        self.isShowingTranslation = true
    }
    
    /// Remove a tradução armazenada e retorna ao idioma original.
    public func clearTranslation() {
        self.translatedText = nil
        self.translatedWords = nil
        self.isShowingTranslation = false
    }
}
