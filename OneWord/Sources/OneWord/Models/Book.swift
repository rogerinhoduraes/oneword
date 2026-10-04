//
//  Book.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftData

/// Representa um Livro na Biblioteca do OneWord.
/// Organiza múltiplas páginas físicas escaneadas sequencialmente, capa personalizada
/// e rastreia o progresso contínuo de leitura RSVP com suporte a salto direto por página.
@Model
public final class Book {
    public var id: UUID
    public var title: String
    public var author: String
    
    @Attribute(.externalStorage)
    public var coverImageData: Data?
    
    /// Cor tema utilizada na capa minimalista gerada dinamicamente caso não haja foto.
    public var coverThemeColor: String
    
    public var createdAt: Date
    public var lastAccessedAt: Date
    
    /// Índice global da palavra atual no livro (acumulado entre todas as páginas).
    public var currentGlobalWordIndex: Int
    
    /// Páginas escaneadas do livro com exclusão em cascata.
    @Relationship(deleteRule: .cascade, inverse: \BookPage.book)
    public var pages: [BookPage] = []
    
    /// Histórico de sessões de leitura realizadas neste livro.
    @Relationship(deleteRule: .cascade)
    public var sessions: [ReadingSession] = []
    
    /// Código ISO do idioma original detectado do livro (ex: "en", "es", "fr", "pt").
    public var detectedLanguageCode: String?
    
    /// Indica se o leitor RSVP e as páginas estão atualmente projetando a tradução em Português.
    public var isTranslationActive: Bool = false
    
    public init(
        id: UUID = UUID(),
        title: String,
        author: String = "",
        coverImageData: Data? = nil,
        coverThemeColor: String = "#1E40AF",
        createdAt: Date = Date(),
        lastAccessedAt: Date = Date(),
        currentGlobalWordIndex: Int = 0,
        detectedLanguageCode: String? = nil,
        isTranslationActive: Bool = false
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.coverImageData = coverImageData
        self.coverThemeColor = coverThemeColor
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.currentGlobalWordIndex = currentGlobalWordIndex
        self.detectedLanguageCode = detectedLanguageCode
        self.isTranslationActive = isTranslationActive
    }
    
    // MARK: - Computed Properties
    
    /// Páginas do livro ordenadas estritamente pelo número da página.
    public var sortedPages: [BookPage] {
        pages.sorted { $0.pageNumber < $1.pageNumber }
    }
    
    /// Total de páginas escaneadas no livro.
    public var totalPages: Int {
        pages.count
    }
    
    /// Total acumulado de palavras de todas as páginas do livro (considera tradução se ativa).
    public var totalWords: Int {
        if isTranslationActive {
            return pages.reduce(0) { $0 + $1.activeWords.count }
        }
        return pages.reduce(0) { $0 + $1.words.count }
    }
    
    /// Array unificado com todas as palavras do livro em ordem sequencial de páginas (considera tradução se ativa).
    public var allWords: [String] {
        if isTranslationActive {
            return sortedPages.flatMap { $0.activeWords }
        }
        return sortedPages.flatMap { $0.words }
    }
    
    /// Deslocamentos globais de índice onde cada página se inicia (considera tradução se ativa).
    public var pageOffsets: [Int] {
        var offsets: [Int] = []
        var runningOffset = 0
        for page in sortedPages {
            offsets.append(runningOffset)
            runningOffset += (isTranslationActive ? page.activeWords.count : page.words.count)
        }
        return offsets
    }
    
    /// Indica se pelo menos uma página do livro foi traduzida para Português.
    public var hasTranslation: Bool {
        sortedPages.contains { $0.translatedWords != nil && !$0.translatedWords!.isEmpty }
    }
    
    /// Metadados do idioma original detectado no livro.
    public var detectedLanguageInfo: DetectedLanguageInfo {
        BookTranslationService.languageInfo(for: detectedLanguageCode)
    }
    
    /// Indica se o livro foi escaneado em língua estrangeira (diferente de português).
    public var isForeignLanguage: Bool {
        !detectedLanguageInfo.isPortuguese
    }
    
    /// Porcentagem de leitura concluída do livro (0.0 a 1.0).
    public var progressPercentage: Double {
        guard totalWords > 0 else { return 0.0 }
        return min(max(Double(currentGlobalWordIndex) / Double(totalWords), 0.0), 1.0)
    }
    
    /// Indica se o livro foi lido até a última palavra.
    public var isCompleted: Bool {
        totalWords > 0 && currentGlobalWordIndex >= totalWords
    }
    
    /// Número da página em que o usuário está atualmente lendo (1-indexed).
    public var currentPageNumber: Int {
        let offsets = pageOffsets
        guard !offsets.isEmpty else { return 1 }
        
        var currentPage = 1
        for (index, offset) in offsets.enumerated() {
            if currentGlobalWordIndex >= offset {
                currentPage = index + 1
            } else {
                break
            }
        }
        return currentPage
    }
    
    // MARK: - Page & Word Mapping
    
    /// Mapeia o número de uma página para seu índice de início no array global de palavras.
    public func globalWordIndex(forPageNumber pageNum: Int) -> Int {
        let sorted = sortedPages
        guard pageNum >= 1 && pageNum <= sorted.count else { return 0 }
        let offsets = pageOffsets
        return offsets[pageNum - 1]
    }
    
    /// Encontra a página correspondente e o índice local a partir de um índice global de palavra.
    public func pageInfo(forGlobalWordIndex index: Int) -> (page: BookPage, localIndex: Int)? {
        let sorted = sortedPages
        let offsets = pageOffsets
        guard !sorted.isEmpty, !offsets.isEmpty else { return nil }
        
        for (i, page) in sorted.enumerated() {
            let start = offsets[i]
            let end = start + page.words.count
            if index >= start && index < end {
                return (page, index - start)
            }
        }
        
        if let last = sorted.last {
            return (last, last.words.count)
        }
        return nil
    }
    
    // MARK: - Progress Management
    
    /// Atualiza o progresso global garantindo limites (clamping).
    public func updateProgress(to index: Int) {
        let clamped = min(max(0, index), totalWords)
        self.currentGlobalWordIndex = clamped
        self.lastAccessedAt = Date()
    }
    
    /// Desloca o progresso de leitura relativamente.
    public func seekWord(by offset: Int) {
        updateProgress(to: currentGlobalWordIndex + offset)
    }
    
    /// Reinicia a leitura do livro para a primeira palavra da página 1.
    public func resetProgress() {
        self.currentGlobalWordIndex = 0
        self.lastAccessedAt = Date()
    }
    
    /// Adiciona uma nova página escaneada ao livro, detectando o idioma automaticamente se necessário.
    @discardableResult
    public func addPage(rawText: String, words: [String], imageData: Data? = nil) -> BookPage {
        let nextNumber = (pages.map { $0.pageNumber }.max() ?? 0) + 1
        
        let detected = BookTranslationService().detectLanguage(for: rawText)
        if self.detectedLanguageCode == nil, let detected {
            self.detectedLanguageCode = detected
        }
        
        let newPage = BookPage(
            pageNumber: nextNumber,
            rawText: rawText,
            words: words,
            pageImageData: imageData,
            book: self,
            originalLanguage: detected ?? self.detectedLanguageCode
        )
        pages.append(newPage)
        lastAccessedAt = Date()
        return newPage
    }
    
    /// Alterna a visualização e leitura entre o idioma original e a tradução para o Português.
    public func toggleTranslation(active: Bool) {
        self.isTranslationActive = active
        for page in pages {
            page.isShowingTranslation = active
        }
        self.currentGlobalWordIndex = min(self.currentGlobalWordIndex, self.totalWords)
        self.lastAccessedAt = Date()
    }
    
    /// Aplica texto e palavras traduzidas a uma página específica.
    public func applyTranslation(forPageNumber pageNum: Int, translatedText: String, translatedWords: [String]) {
        guard let page = pages.first(where: { $0.pageNumber == pageNum }) else { return }
        page.setTranslation(text: translatedText, words: translatedWords)
        self.lastAccessedAt = Date()
    }
    
    /// Remove todas as traduções armazenadas do livro.
    public func clearAllTranslations() {
        self.isTranslationActive = false
        for page in pages {
            page.clearTranslation()
        }
        self.currentGlobalWordIndex = min(self.currentGlobalWordIndex, self.totalWords)
        self.lastAccessedAt = Date()
    }
    
    /// Tempo total estimado de leitura do livro na velocidade WPM especificada (em minutos).
    public func estimatedTotalReadingTimeMinutes(wpm: Int) -> Double {
        guard wpm > 0 else { return 0.0 }
        return Double(totalWords) / Double(wpm)
    }
    
    /// Tempo restante estimado de leitura a partir do progresso atual (em minutos).
    public func remainingReadingTimeMinutes(wpm: Int) -> Double {
        guard wpm > 0 else { return 0.0 }
        let remainingWords = max(0, totalWords - currentGlobalWordIndex)
        return Double(remainingWords) / Double(wpm)
    }
}
