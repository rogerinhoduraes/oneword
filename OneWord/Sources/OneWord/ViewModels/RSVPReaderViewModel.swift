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
/// Conecta a entidade `Document` persistida ao `RSVPEngine`,
/// sincroniza o progresso em tempo real e expõe comandos para a interface SwiftUI.
@Observable
@MainActor
public final class RSVPReaderViewModel {
    
    // MARK: - Entidades
    
    /// Documento ativo em leitura.
    public let document: Document
    
    /// Motor de apresentação serial rápida.
    public let engine: RSVPEngine
    
    /// Contexto SwiftData para persistência do progresso.
    private var modelContext: ModelContext?
    
    // MARK: - Estado de UI
    
    /// Controla a exibição das configurações adicionais de leitura.
    public var isShowingSettings: Bool = false
    
    /// Preferências visuais (tema, fonte, tamanho e guias ORP).
    public var settings: ReaderSettings = ReaderSettings()
    
    // MARK: - Inicializador
    
    /// Inicializa o ViewModel do Leitor com o documento e o contexto de persistência.
    /// - Parameters:
    ///   - document: Documento a ser lido.
    ///   - modelContext: Contexto SwiftData opcional para persistência contínua.
    ///   - initialWPM: Velocidade inicial (default: 300 WPM).
    public init(
        document: Document,
        modelContext: ModelContext? = nil,
        initialWPM: Int = 300
    ) {
        self.document = document
        self.modelContext = modelContext
        
        let config = RSVPConfiguration(wpm: initialWPM)
        self.engine = RSVPEngine(config: config)
        
        let words = document.content?.words ?? []
        let initialIndex = document.currentWordIndex
        
        engine.load(words: words, initialIndex: initialIndex)
        
        // Sincroniza progresso com o documento sempre que o cursor avança
        self.engine.onIndexChanged = { [weak self] newIndex in
            self?.persistProgress(to: newIndex)
        }
    }
    
    // MARK: - Propriedades Expostas para SwiftUI
    
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
    
    /// Total de palavras no documento.
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
    }
    
    /// Avança uma palavra manualmente.
    public func stepForward() {
        engine.stepForward()
    }
    
    /// Retrocede 10 palavras (Requisito de UX Crítico).
    public func rewind10Words() {
        engine.stepBackward(count: 10)
    }
    
    /// Avança para a próxima frase (Requisito de UX Crítico).
    public func advanceSentence() {
        engine.advanceSentence()
    }
    
    /// Retorna para a frase anterior (Requisito de UX Crítico).
    public func rewindSentence() {
        engine.rewindSentence()
    }
    
    /// Reinicia a leitura do início.
    public func reset() {
        engine.reset()
    }
    
    private var sessionStartTime: Date = Date()
    private var sessionInitialIndex: Int = 0
    
    /// Pausa a reprodução, força o salvamento do progresso e registra a sessão de leitura.
    public func onDisappear() {
        engine.pause()
        persistProgress(to: engine.currentIndex)
        recordSessionIfNeeded()
    }
    
    // MARK: - Persistência
    
    private func persistProgress(to index: Int) {
        document.updateProgress(to: index)
        if let modelContext {
            try? modelContext.save()
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
            documentTitle: document.title,
            document: document
        )
        
        modelContext?.insert(session)
        try? modelContext?.save()
        
        // Reinicia referências temporais para evitar duplicação
        sessionInitialIndex = engine.currentIndex
        sessionStartTime = Date()
    }
}
