//
//  Document.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftData

/// Representa um documento escaneado ou importado na biblioteca do OneWord.
/// Centraliza metadados, conteúdo textual tokenizado e estado de progresso de leitura RSVP.
@Model
public final class Document {
    /// Identificador único universal do documento.
    public var id: UUID
    
    /// Título descritivo do documento (ex: extraído da primeira linha ou customizado).
    public var title: String
    
    /// Data e hora de criação/escaneamento do documento.
    public var createdAt: Date
    
    /// Data e hora do último acesso ou sessão de leitura.
    public var lastAccessedAt: Date
    
    /// Conteúdo textual do documento (relacionamento 1:1 com exclusão em cascata).
    @Relationship(deleteRule: .cascade, inverse: \DocumentContent.document)
    public var content: DocumentContent?
    
    /// Progresso de leitura atual (relacionamento 1:1 com exclusão em cascata).
    @Relationship(deleteRule: .cascade, inverse: \ReadingProgress.document)
    public var progress: ReadingProgress?
    
    /// Histórico de sessões de leitura associadas a este documento.
    @Relationship(deleteRule: .cascade, inverse: \ReadingSession.document)
    public var sessions: [ReadingSession] = []
    
    // MARK: - Inicializadores
    
    /// Inicializador completo de Document.
    public init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        lastAccessedAt: Date = Date(),
        content: DocumentContent? = nil,
        progress: ReadingProgress? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.content = content
        self.progress = progress
    }
    
    /// Inicializador de conveniência a partir de texto bruto e array de palavras.
    /// Cria automaticamente instâncias associadas de `DocumentContent` e `ReadingProgress`.
    public convenience init(
        title: String,
        rawText: String,
        words: [String],
        initialWordIndex: Int = 0
    ) {
        let docId = UUID()
        let newContent = DocumentContent(rawText: rawText, words: words)
        let newProgress = ReadingProgress(currentWordIndex: initialWordIndex)
        
        self.init(
            id: docId,
            title: title,
            createdAt: Date(),
            lastAccessedAt: Date(),
            content: newContent,
            progress: newProgress
        )
        
        newContent.document = self
        newProgress.document = self
    }
    
    // MARK: - Propriedades Computadas
    
    /// Total de palavras no documento.
    public var totalWords: Int {
        content?.words.count ?? 0
    }
    
    /// Índice da palavra atual sendo lida (zero-based).
    public var currentWordIndex: Int {
        progress?.currentWordIndex ?? 0
    }
    
    /// Palavra atual a ser exibida no leitor RSVP.
    public var currentWord: String? {
        guard let words = content?.words,
              currentWordIndex >= 0 && currentWordIndex < words.count else {
            return nil
        }
        return words[currentWordIndex]
    }
    
    /// Percentual de progresso de leitura (de 0.0 a 1.0).
    public var progressPercentage: Double {
        guard totalWords > 0 else { return 0.0 }
        let current = Double(currentWordIndex)
        let total = Double(totalWords)
        return min(max(0.0, current / total), 1.0)
    }
    
    /// Indica se o leitor já concluiu todas as palavras do documento.
    public var isCompleted: Bool {
        totalWords > 0 && currentWordIndex >= totalWords
    }
    
    /// Estimativa do tempo total de leitura em minutos com base na velocidade informada em WPM.
    /// - Parameter wpm: Palavras por minuto (ex: 300).
    /// - Returns: Tempo estimado em minutos (Double).
    public func estimatedTotalReadingTimeMinutes(wpm: Int) -> Double {
        guard wpm > 0, totalWords > 0 else { return 0.0 }
        return Double(totalWords) / Double(wpm)
    }
    
    /// Estimativa do tempo restante de leitura em minutos com base na velocidade informada em WPM.
    /// - Parameter wpm: Palavras por minuto (ex: 300).
    /// - Returns: Tempo restante em minutos (Double).
    public func remainingReadingTimeMinutes(wpm: Int) -> Double {
        guard wpm > 0 else { return 0.0 }
        let remainingWords = max(0, totalWords - currentWordIndex)
        return Double(remainingWords) / Double(wpm)
    }
    
    /// Retorna um trecho resumido do texto para visualização em listas e cards.
    /// - Parameter maxLength: Quantidade máxima de caracteres (default: 120).
    /// - Returns: Texto com reticências se exceder o limite.
    public func previewSnippet(maxLength: Int = 120) -> String {
        guard let raw = content?.rawText, !raw.isEmpty else { return "Documento sem texto disponível." }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count <= maxLength {
            return trimmed
        }
        let index = trimmed.index(trimmed.startIndex, offsetBy: maxLength)
        return String(trimmed[..<index]) + "..."
    }
    
    // MARK: - Mutação e Navegação de Progresso
    
    /// Atualiza a data do último acesso para o momento presente.
    public func markAsAccessed() {
        self.lastAccessedAt = Date()
    }
    
    /// Atualiza com segurança o índice da palavra atual.
    /// - Parameter index: Novo índice pretendido.
    public func updateProgress(to index: Int) {
        guard let progress else { return }
        progress.setIndex(index, maxWords: totalWords)
        markAsAccessed()
    }
    
    /// Avança ou retrocede uma quantidade fixa de palavras.
    /// - Parameter delta: Quantidade relativa de palavras (+10, -10, etc.).
    public func seekWord(by delta: Int) {
        let newIndex = currentWordIndex + delta
        updateProgress(to: newIndex)
    }
    
    /// Salta para o início da próxima frase (localiza pontuação terminativa ".", "!", "?").
    public func advanceSentence() {
        guard let words = content?.words, !words.isEmpty else { return }
        let terminators: Set<Character> = [".", "!", "?"]
        
        // Procura a partir da palavra seguinte até encontrar a pontuação terminativa
        for i in currentWordIndex..<words.count {
            let word = words[i]
            if let lastChar = word.last, terminators.contains(lastChar) {
                // Posiciona na palavra após o ponto final
                let nextSentenceIndex = min(i + 1, words.count)
                updateProgress(to: nextSentenceIndex)
                return
            }
        }
        // Se não encontrar nenhuma frase seguinte, salta para o fim
        updateProgress(to: words.count)
    }
    
    /// Retorna para o início da frase atual ou da frase anterior.
    public func rewindSentence() {
        guard let words = content?.words, !words.isEmpty else { return }
        let terminators: Set<Character> = [".", "!", "?"]
        
        // Se estiver no meio de uma frase, volta até a pontuação anterior à atual
        var searchStart = max(0, currentWordIndex - 2)
        while searchStart > 0 {
            let word = words[searchStart]
            if let lastChar = word.last, terminators.contains(lastChar) {
                updateProgress(to: searchStart + 1)
                return
            }
            searchStart -= 1
        }
        // Se não houver frase anterior, volta ao início do documento
        updateProgress(to: 0)
    }
    
    /// Reinicia o progresso do documento.
    public func resetProgress() {
        progress?.reset()
        markAsAccessed()
    }
}
