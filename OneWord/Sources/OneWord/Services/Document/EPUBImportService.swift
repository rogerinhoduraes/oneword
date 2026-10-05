//
//  EPUBImportService.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftData

/// Serviço de alto nível para importação de livros digitais (ePub, TXT, Markdown) para o SwiftData.
public final class EPUBImportService: Sendable {
    private let parser: EPUBParser
    
    public init(parser: EPUBParser = EPUBParser()) {
        self.parser = parser
    }
    
    /// Importa um arquivo a partir de uma URL de segurança (UIDocumentPicker ou FileImporter).
    /// Suporta formatos `.epub`, `.txt`, `.md`.
    /// - Parameters:
    ///   - url: URL do arquivo no sistema de arquivos do dispositivo.
    ///   - context: Contexto de persistência do SwiftData onde o Livro será inserido.
    /// - Returns: Instância de `Book` criada com todas as páginas geradas.
    @MainActor
    public func importFile(from url: URL, context: ModelContext) throws -> Book {
        let isAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if isAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileData = try Data(contentsOf: url)
        let fileExtension = url.pathExtension.lowercased()
        
        if fileExtension == "epub" {
            return try importEPUB(data: fileData, defaultTitle: url.deletingPathExtension().lastPathComponent, context: context)
        } else {
            // Arquivo de texto puro (.txt, .md, etc.)
            let text = String(data: fileData, encoding: .utf8) ?? String(decoding: fileData, as: UTF8.self)
            return try importPlainText(text: text, title: url.deletingPathExtension().lastPathComponent, context: context)
        }
    }
    
    /// Converte dados de ePub em uma entidade `Book` no SwiftData.
    @MainActor
    public func importEPUB(data: Data, defaultTitle: String = "Livro Digital", context: ModelContext) throws -> Book {
        let epubBook = try parser.parse(data: data)
        let effectiveTitle = epubBook.title.isEmpty ? defaultTitle : epubBook.title
        
        let book = Book(
            title: effectiveTitle,
            author: epubBook.author.isEmpty ? String(localized: "Autor Desconhecido") : epubBook.author,
            coverImageData: epubBook.coverImageData,
            coverThemeColor: randomThemeColor()
        )
        context.insert(book)
        
        // Adiciona capítulos divididos em páginas confortáveis (~350 a 500 palavras por página)
        for chapter in epubBook.chapters {
            let chunks = chunkWords(chapter.words, maxWordsPerPage: 400)
            if chunks.isEmpty {
                book.addPage(rawText: chapter.textContent, words: chapter.words)
            } else {
                for chunk in chunks {
                    let pageText = chunk.joined(separator: " ")
                    book.addPage(rawText: pageText, words: chunk)
                }
            }
        }
        
        try context.save()
        return book
    }
    
    /// Converte texto plano em um `Book` estruturado.
    @MainActor
    public func importPlainText(text: String, title: String, author: String = "Importado", context: ModelContext) throws -> Book {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else {
            throw EPUBError.noReadableChapters
        }
        
        let allWords = cleanText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard !allWords.isEmpty else {
            throw EPUBError.noReadableChapters
        }
        
        let book = Book(
            title: title.isEmpty ? "Texto Importado" : title,
            author: author,
            coverImageData: nil,
            coverThemeColor: randomThemeColor()
        )
        context.insert(book)
        
        let chunks = chunkWords(allWords, maxWordsPerPage: 400)
        for chunk in chunks {
            let pageText = chunk.joined(separator: " ")
            book.addPage(rawText: pageText, words: chunk)
        }
        
        try context.save()
        return book
    }
    
    // MARK: - Auxiliares
    
    private func chunkWords(_ words: [String], maxWordsPerPage: Int) -> [[String]] {
        guard !words.isEmpty else { return [] }
        var result: [[String]] = []
        var currentChunk: [String] = []
        
        for word in words {
            currentChunk.append(word)
            if currentChunk.count >= maxWordsPerPage {
                // Tenta fechar na pontuação de final de frase se estiver próximo
                if let lastChar = word.last, [".", "!", "?"].contains(lastChar) || currentChunk.count >= maxWordsPerPage + 50 {
                    result.append(currentChunk)
                    currentChunk = []
                }
            }
        }
        
        if !currentChunk.isEmpty {
            result.append(currentChunk)
        }
        return result
    }
    
    private func randomThemeColor() -> String {
        let colors = ["#1E40AF", "#047857", "#881337", "#6B21A8", "#B45309", "#0F766E", "#334155"]
        return colors.randomElement() ?? "#1E40AF"
    }
}
