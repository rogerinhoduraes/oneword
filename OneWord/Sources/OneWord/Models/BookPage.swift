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
    
    public init(
        id: UUID = UUID(),
        pageNumber: Int = 1,
        rawText: String = "",
        words: [String] = [],
        pageImageData: Data? = nil,
        createdAt: Date = Date(),
        book: Book? = nil
    ) {
        self.id = id
        self.pageNumber = pageNumber
        self.rawText = rawText
        self.words = words
        self.pageImageData = pageImageData
        self.createdAt = createdAt
        self.book = book
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
