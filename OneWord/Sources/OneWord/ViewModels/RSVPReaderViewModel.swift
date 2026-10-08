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
    public var settings: ReaderSettings = ReaderSettings.load() {
        didSet {
            settings.save()
            applySettings()
        }
    }
    
    /// Modos de visualização de leitura disponíveis.
    public enum ReaderMode: String, CaseIterable, Identifiable {
        case rsvp = "RSVP Foveal"
        case bionic = "Biônico Pacer"
        
        public var id: String { rawValue }
    }
    
    /// Modo de exibição atual (RSVP de palavra central vs Leitor Biônico contínuo).
    public var readerMode: ReaderMode = .rsvp
    
    /// Habilita rastreamento de atenção e pausa automática por câmera frontal.
    public var isEyeTrackingEnabled: Bool = false {
        didSet {
            setupEyeTracking()
        }
    }
    
    /// Exibição do modal de compartilhamento em redes sociais.
    public var isShowingShareCard: Bool = false
    
    /// Controle de exibição do dicionário de termos da Apple.
    public var isShowingWordDefinition: Bool = false
    public var wordToDefine: String = ""
    
    /// Controle de exibição do modal de Priming Neurocognitivo (Pré-leitura).
    public var isShowingPrimingSheet: Bool = false
    public var primingContext: CognitivePrimingContext?
    
    /// Aplica as preferências de ergonomia cognitiva diretamente ao motor RSVP.
    public func applySettings() {
        engine.config.smartWPMEnabled = settings.smartWPMEnabled
        engine.config.chunkSize = settings.chunkSize
        engine.config.bimodalAudioEnabled = settings.bimodalAudioEnabled
        if settings.bimodalAudioEnabled && engine.bimodalSynthesizer == nil {
            engine.bimodalSynthesizer = BimodalSpeechSynthesizer()
        }
    }
    
    private func setupEyeTracking() {
        if isEyeTrackingEnabled {
            EyeTrackingManager.shared.onUserLookedAway = { [weak self] in
                Task { @MainActor in
                    self?.handleUserLookedAway()
                }
            }
            EyeTrackingManager.shared.startTracking()
        } else {
            EyeTrackingManager.shared.stopTracking()
        }
    }
    
    private func handleUserLookedAway() {
        guard engine.isPlaying else { return }
        engine.pause()
        engine.stepBackward(count: 4) // Retrocede 4 palavras para não perder a linha de raciocínio
    }
    
    // MARK: - Inicializadores
    
    /// Inicializa o ViewModel do Leitor com um Documento avulso.
    public init(
        document: Document,
        modelContext: ModelContext? = nil,
        initialWPM: Int = AppSettings.defaultWPM
    ) {
        self.document = document
        self.book = nil
        self.modelContext = modelContext
        
        let config = RSVPConfiguration(wpm: initialWPM)
        self.engine = RSVPEngine(config: config)
        
        let words = document.activeWords
        let initialIndex = document.currentWordIndex
        
        self.sessionInitialIndex = initialIndex
        engine.load(words: words, initialIndex: initialIndex)
        
        self.engine.onIndexChanged = { [weak self] newIndex in
            self?.persistProgress(to: newIndex)
        }
        
        applySettings()
    }
    
    /// Inicializa o ViewModel do Leitor com um Livro multi-páginas.
    /// Permite leitura contínua partindo do progresso salvo ou de uma página específica (Modo Híbrido).
    public init(
        book: Book,
        startPageNumber: Int? = nil,
        modelContext: ModelContext? = nil,
        initialWPM: Int = AppSettings.defaultWPM
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
        
        applySettings()
    }
    
    // MARK: - Propriedades Expostas para SwiftUI
    
    /// Título do item em leitura.
    public var title: String {
        book?.title ?? document?.title ?? String(localized: "Leitura")
    }
    
    /// Subtítulo descritivo de posição (ex: página do livro).
    public var subtitle: String {
        if let book {
            let livePage = book.pageInfo(forGlobalWordIndex: engine.currentIndex)?.page.pageNumber ?? book.currentPageNumber
            return String(localized: "Página \(livePage) de \(max(1, book.totalPages))")
        } else if let document {
            if document.isTranslationActive {
                return String(localized: "\(AppLanguage.flag) \(AppLanguage.name) (Traduzido)")
            } else if document.isForeignLanguage {
                return String(localized: "\(document.detectedLanguageInfo.flag) \(document.detectedLanguageInfo.name) (Original)")
            }
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
    
    /// Indica se o item em leitura possui tradução para Português disponível.
    public var hasTranslation: Bool {
        book?.hasTranslation ?? document?.hasTranslation ?? false
    }
    
    /// Indica se a leitura atual está exibindo a versão traduzida para Português.
    public var isTranslationActive: Bool {
        book?.isTranslationActive ?? document?.isTranslationActive ?? false
    }
    
    /// Indica se o item sendo lido é originário de um idioma estrangeiro.
    public var isForeignLanguage: Bool {
        if let book { return book.isForeignLanguage }
        if let document { return document.isForeignLanguage }
        return false
    }
    
    /// Bandeira emoji do idioma original.
    public var originalLanguageFlag: String {
        if let book { return book.detectedLanguageInfo.flag }
        if let document { return document.detectedLanguageInfo.flag }
        return "🌐"
    }
    
    /// Nome do idioma original em português.
    public var originalLanguageName: String {
        if let book { return book.detectedLanguageInfo.name }
        if let document { return document.detectedLanguageInfo.name }
        return String(localized: "Original")
    }
    
    /// Traduz instantaneamente o item atual para Português e ativa o modo traduzido mantendo a posição.
    public func translateNow() {
        let wasPlaying = engine.isPlaying
        if wasPlaying {
            engine.pause()
        }
        
        let currentProgress = engine.progress
        let parser = TextParser()
        
        if let book {
            let lang = book.detectedLanguageCode ?? "en"
            for page in book.sortedPages {
                let translated = BookTranslationFallback.translate(text: page.rawText, from: lang)
                let parsed = parser.parse(rawText: translated)
                page.setTranslation(text: translated, words: parsed.words)
            }
            book.toggleTranslation(active: true)
            let words = book.allWords
            let newIndex = min(Int(currentProgress * Double(words.count)), max(0, words.count - 1))
            engine.load(words: words, initialIndex: max(0, newIndex))
            persistProgress(to: newIndex, forceDiskSave: true)
        } else if let document, let content = document.content {
            let lang = document.detectedLanguageCode ?? "en"
            let translated = BookTranslationFallback.translate(text: content.rawText, from: lang)
            let parsed = parser.parse(rawText: translated)
            document.applyTranslation(text: translated, words: parsed.words)
            document.toggleTranslation(active: true)
            let words = document.activeWords
            let newIndex = min(Int(currentProgress * Double(words.count)), max(0, words.count - 1))
            engine.load(words: words, initialIndex: max(0, newIndex))
            persistProgress(to: newIndex, forceDiskSave: true)
        }
        
        if wasPlaying {
            engine.play()
        }
    }
    
    /// Alterna a leitura entre o idioma original e o português traduzido em tempo real.
    /// Se a tradução ainda não estiver gerada, aciona a tradução instantânea.
    public func toggleTranslation() {
        if !hasTranslation && isForeignLanguage {
            translateNow()
            return
        }
        
        let wasPlaying = engine.isPlaying
        if wasPlaying {
            engine.pause()
        }
        
        let currentProgress = engine.progress
        
        if let book, book.hasTranslation {
            book.toggleTranslation(active: !book.isTranslationActive)
            let words = book.allWords
            guard !words.isEmpty else { return }
            let newIndex = min(Int(currentProgress * Double(words.count)), words.count - 1)
            engine.load(words: words, initialIndex: max(0, newIndex))
            persistProgress(to: newIndex, forceDiskSave: true)
        } else if let document, document.hasTranslation {
            document.toggleTranslation(active: !document.isTranslationActive)
            let words = document.activeWords
            guard !words.isEmpty else { return }
            let newIndex = min(Int(currentProgress * Double(words.count)), words.count - 1)
            engine.load(words: words, initialIndex: max(0, newIndex))
            persistProgress(to: newIndex, forceDiskSave: true)
        }
        
        if wasPlaying {
            engine.play()
        }
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
            return String(localized: "\(max(1, seconds)) seg rest.")
        } else {
            return String(format: String(localized: "%.1f min rest."), minutes)
        }
    }
    
    // MARK: - Comandos de Controle
    
    /// Abre a visualização do dicionário para a palavra atualmente pausada.
    public func showDefinitionForCurrentWord() {
        let word = currentWord
        guard !word.isEmpty else { return }
        wordToDefine = word
        isShowingWordDefinition = true
    }
    
    /// Carrega e gera o contexto de pré-ativação cognitiva sob demanda a partir do texto ativo.
    public func loadPrimingContext() {
        let text: String
        if let book {
            text = book.sortedPages.prefix(3).map(\.rawText).joined(separator: "\n\n")
        } else if let document, let content = document.content {
            text = content.rawText
        } else {
            text = engine.words.joined(separator: " ")
        }
        self.primingContext = TextSummarizerService.shared.generatePrimingContext(from: text, title: title)
    }
    
    /// Abre a tela de pré-ativação mental (Priming).
    public func presentPriming() {
        if engine.isPlaying {
            engine.pause()
        }
        loadPrimingContext()
        isShowingPrimingSheet = true
    }
    
    /// Inicia a reprodução com esquemas pré-frontais já ativados pelo Priming.
    public func startReadingFromPriming() {
        isShowingPrimingSheet = false
        if !engine.isPlaying {
            togglePlayPause()
        }
    }
    
    /// Alterna reprodução entre Play e Pause.
    public func togglePlayPause() {
        if engine.isPlaying {
            engine.pause()
            LiveActivityManager.shared.updateSession(
                currentWord: currentWord,
                wordsRead: currentIndex,
                totalWords: totalWords,
                remainingMinutes: engine.remainingMinutes,
                wpm: engine.config.wpm,
                isPlaying: false
            )
            persistProgress(to: engine.currentIndex, forceDiskSave: true)
        } else {
            applySettings()
            engine.play()
            LiveActivityManager.shared.startSession(
                title: title,
                author: book?.author,
                currentWord: currentWord,
                wordsRead: currentIndex,
                totalWords: totalWords,
                remainingMinutes: engine.remainingMinutes,
                wpm: engine.config.wpm,
                isPlaying: true
            )
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
        EyeTrackingManager.shared.stopTracking()
        LiveActivityManager.shared.endSession()
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
