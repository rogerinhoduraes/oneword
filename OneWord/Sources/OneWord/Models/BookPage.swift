//
//  BookPage.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftData

/// Representa uma página física ou capítulo escaneado pertencente a um livro na biblioteca.
@Model
public final class BookPage {
    public var id: UUID
    public var pageNumber: Int
    public var rawText: String
    public var words: [String]
    
    @Attribute(.externalStorage)
    public var pageImageData: Data?
    
    public var createdAt: Date
    public var book: Book?
    
    /// Idioma original detectado do texto escaneado (ex: "en", "es", "fr").
    public var originalLanguage: String?
    
    /// Texto traduzido para o Português (se solicitado pelo usuário).
    public var translatedText: String?
    
    /// Palavras tokenizadas do texto traduzido para apresentação RSVP em português.
    public var translatedWords: [String]?
    
    /// Controla se a página está exibindo a versão traduzida ou o texto original.
    public var isShowingTranslation: Bool = false
    
    public init(
        id: UUID = UUID(),
        pageNumber: Int = 1,
        rawText: String = "",
        words: [String] = [],
        pageImageData: Data? = nil,
        createdAt: Date = Date(),
        book: Book? = nil,
        originalLanguage: String? = nil,
        translatedText: String? = nil,
        translatedWords: [String]? = nil,
        isShowingTranslation: Bool = false
    ) {
        self.id = id
        self.pageNumber = pageNumber
        self.rawText = rawText
        self.words = words
        self.pageImageData = pageImageData
        self.createdAt = createdAt
        self.book = book
        self.originalLanguage = originalLanguage
        self.translatedText = translatedText
        self.translatedWords = translatedWords
        self.isShowingTranslation = isShowingTranslation
    }
    
    /// Palavras ativas para apresentação RSVP (traduzidas ou originais conforme toggle).
    public var activeWords: [String] {
        if isShowingTranslation, let translatedWords, !translatedWords.isEmpty {
            return translatedWords
        }
        return words
    }
    
    /// Texto bruto ativo (traduzido ou original).
    public var activeRawText: String {
        if isShowingTranslation, let translatedText, !translatedText.isEmpty {
            return translatedText
        }
        return rawText
    }
    
    /// Define a tradução em português para a página e atualiza os arrays de palavras RSVP.
    public func setTranslation(text: String, words: [String]) {
        self.translatedText = text
        self.translatedWords = words
        self.isShowingTranslation = true
    }
    
    /// Remove a tradução em português desta página.
    public func clearTranslation() {
        self.translatedText = nil
        self.translatedWords = nil
        self.isShowingTranslation = false
    }
    
    /// Total de palavras na página.
    public var wordCount: Int {
        words.count
    }
    
    /// Trecho introdutório do texto da página para preview na lista.
    public var previewSnippet: String {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= 120 {
            return trimmed
        }
        let index = trimmed.index(trimmed.startIndex, offsetBy: 120)
        return String(trimmed[..<index]) + "..."
    }
}
