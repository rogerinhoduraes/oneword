//
//  RSVPReaderViewModel.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftData
import Observation

/// ViewModel responsável pela tela de leitura RSVP.
/// Conecta a entidade `Document` ou `Book` persistida ao `RSVPEngine`,
/// sincroniza o progresso em tempo real e expõe comandos para a interface SwiftUI.
@Observable
@MainActor
public final class RSVPReaderViewModel {
    
    // MARK: - Entidades
    
    /// Documento ativo em leitura (se for leitura de documento avulso).
    public let document: Document?
    
    /// Livro ativo em leitura (se for leitura de livro multi-páginas).
    public let book: Book?
    
    /// Motor de apresentação serial rápida.
    public let engine: RSVPEngine
    
    /// Contexto SwiftData para persistência do progresso.
    private var modelContext: ModelContext?
    
    // MARK: - Estado de UI
    
    /// Controla a exibição das configurações adicionais de leitura.
    public var isShowingSettings: Bool = false
    
    /// Preferências visuais (tema, fonte, tamanho e guias ORP).
    public var settings: ReaderSettings = ReaderSettings()
    
    // MARK: - Inicializadores
    
    /// Inicializa o ViewModel do Leitor com um Documento avulso.
    public init(
        document: Document,
        modelContext: ModelContext? = nil,
        initialWPM: Int = 300
    ) {
        self.document = document
        self.book = nil
        self.modelContext = modelContext
        
        let config = RSVPConfiguration(wpm: initialWPM)
        self.engine = RSVPEngine(config: config)
        
        let words = document.content?.words ?? []
        let initialIndex = document.currentWordIndex
        
        self.sessionInitialIndex = initialIndex
        engine.load(words: words, initialIndex: initialIndex)
        
        self.engine.onIndexChanged = { [weak self] newIndex in
            self?.persistProgress(to: newIndex)
        }
    }
    
    /// Inicializa o ViewModel do Leitor com um Livro multi-páginas.
    /// Permite leitura contínua partindo do progresso salvo ou de uma página específica (Modo Híbrido).
    public init(
        book: Book,
        startPageNumber: Int? = nil,
        modelContext: ModelContext? = nil,
        initialWPM: Int = 300
    ) {
        self.book = book
        self.document = nil
        self.modelContext = modelContext
        
        let config = RSVPConfiguration(wpm: initialWPM)
        self.engine = RSVPEngine(config: config)
        
        let words = book.allWords
        let initialIndex: Int
        if let startPageNumber {
            initialIndex = book.globalWordIndex(forPageNumber: startPageNumber)
            book.updateProgress(to: initialIndex)
        } else {
            initialIndex = book.currentGlobalWordIndex
        }
        
        self.sessionInitialIndex = initialIndex
        engine.load(words: words, initialIndex: initialIndex)
        
        self.engine.onIndexChanged = { [weak self] newIndex in
            self?.persistProgress(to: newIndex)
        }
    }
    
    // MARK: - Propriedades Expostas para SwiftUI
    
    /// Título do item em leitura.
    public var title: String {
        book?.title ?? document?.title ?? "Leitura"
    }
    
    /// Subtítulo descritivo de posição (ex: página do livro).
    public var subtitle: String {
        if let book {
            let livePage = book.pageInfo(forGlobalWordIndex: engine.currentIndex)?.page.pageNumber ?? book.currentPageNumber
            return "Página \(livePage) de \(max(1, book.totalPages))"
        }
        return ""
    }
    
    /// Velocidade de leitura em WPM vinculável a Sliders (Double).
    public var wpmBinding: Double {
        get { Double(engine.config.wpm) }
        set { engine.setWPM(Int(newValue)) }
    }
    
    /// Posição do cursor vinculável a Sliders de scrubbing.
    public var scrubberBinding: Double {
        get { Double(engine.currentIndex) }
        set { engine.seek(to: Int(newValue)) }
    }
    
    /// Palavra atual a ser exibida.
    public var currentWord: String {
        engine.currentWord
    }
    
    /// Palavra dividida no ponto ótimo de reconhecimento (ORP).
    public var currentSplitWord: ORPSplitWord {
        engine.currentSplitWord
    }
    
    /// Indica se o leitor está em reprodução contínua.
    public var isPlaying: Bool {
        engine.isPlaying
    }
    
    /// Indica se o leitor concluiu a última palavra.
    public var isCompleted: Bool {
        engine.isCompleted
    }
    
    /// Total de palavras no documento ou livro.
    public var totalWords: Int {
        engine.totalWords
    }
    
    /// Índice da palavra atual.
    public var currentIndex: Int {
        engine.currentIndex
    }
    
    /// Progresso de 0.0 a 1.0.
    public var progress: Double {
        engine.progress
    }
    
    /// Percentual formatado para a UI (ex: "45%").
    public var progressPercentageFormatted: String {
        let percent = Int(progress * 100)
        return "\(percent)%"
    }
    
    /// Tempo restante formatado (ex: "2 min rest.").
    public var remainingTimeFormatted: String {
        let minutes = engine.remainingMinutes
        if minutes < 1.0 {
            let seconds = Int(minutes * 60)
            return "\(max(1, seconds)) seg rest."
        } else {
            return String(format: "%.1f min rest.", minutes)
        }
    }
    
    // MARK: - Comandos de Controle
    
    /// Alterna reprodução entre Play e Pause.
    public func togglePlayPause() {
        engine.togglePlayPause()
        if !engine.isPlaying {
            persistProgress(to: engine.currentIndex, forceDiskSave: true)
        }
    }
    
    /// Avança uma palavra manualmente.
    public func stepForward() {
        engine.stepForward()
        persistProgress(to: engine.currentIndex, forceDiskSave: true)
    }
    
    /// Retrocede 10 palavras (Requisito de UX Crítico).
    public func rewind10Words() {
        engine.stepBackward(count: 10)
        persistProgress(to: engine.currentIndex, forceDiskSave: true)
    }
    
    /// Avança para a próxima frase (Requisito de UX Crítico).
    public func advanceSentence() {
        engine.advanceSentence()
        persistProgress(to: engine.currentIndex, forceDiskSave: true)
    }
    
    /// Retorna para a frase anterior (Requisito de UX Crítico).
    public func rewindSentence() {
        engine.rewindSentence()
        persistProgress(to: engine.currentIndex, forceDiskSave: true)
    }
    
    /// Reinicia a leitura do início.
    public func reset() {
        engine.reset()
        persistProgress(to: 0, forceDiskSave: true)
    }
    
    private var sessionStartTime: Date = Date()
    private var sessionInitialIndex: Int = 0
    
    /// Pausa a reprodução, força o salvamento do progresso e registra a sessão de leitura.
    public func onDisappear() {
        engine.pause()
        persistProgress(to: engine.currentIndex, forceDiskSave: true)
        recordSessionIfNeeded()
    }
    
    // MARK: - Persistência
    
    private var wordsSinceLastDiskSave: Int = 0
    private let diskSaveInterval: Int = 30 // Salva no disco a cada 30 palavras para evitar I/O excessivo
    
    private func persistProgress(to index: Int, forceDiskSave: Bool = false) {
        wordsSinceLastDiskSave += 1
        
        // Atualiza e persiste nos modelos SwiftData apenas em checkpoints
        // (a cada 30 palavras, ao pausar, retroceder, avançar, sair ou concluir).
        // Isso previne que a estante da biblioteca e a tela de detalhes do livro
        // fiquem disparando reavaliações do SwiftUI 10 vezes por segundo durante a leitura.
        if forceDiskSave || wordsSinceLastDiskSave >= diskSaveInterval || engine.isCompleted {
            wordsSinceLastDiskSave = 0
            
            if let book {
                book.updateProgress(to: index)
            } else if let document {
                document.updateProgress(to: index)
            }
            
            if let modelContext {
                try? modelContext.save()
            }
        }
        
        if engine.isCompleted {
            recordSessionIfNeeded()
        }
    }
    
    /// Salva o registro da sessão de leitura para alimentar o dashboard de estatísticas.
    public func recordSessionIfNeeded() {
        let wordsRead = max(0, engine.currentIndex - sessionInitialIndex)
        guard wordsRead >= 5 else { return }
        
        let duration = max(1.0, Date().timeIntervalSince(sessionStartTime))
        let session = ReadingSession(
            date: Date(),
            durationSeconds: duration,
            wordsRead: wordsRead,
            averageWPM: engine.config.wpm,
            documentTitle: title,
            document: document,
            book: book
        )
        
        modelContext?.insert(session)
        try? modelContext?.save()
        
        // Reinicia referências temporais para evitar duplicação
        sessionInitialIndex = engine.currentIndex
        sessionStartTime = Date()
    }
}
