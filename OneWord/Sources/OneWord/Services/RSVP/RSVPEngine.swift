//
//  RSVPEngine.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import Observation

/// Motor de alta precisão para apresentação serial visual rápida (RSVP).
/// Gerencia a máquina de estados de leitura, temporização adaptativa com pausas dinâmicas
/// por pontuação e cálculo do Ponto Óptico de Reconhecimento (ORP).
@Observable
@MainActor
public final class RSVPEngine: RSVPEngineProtocol {
    
    // MARK: - Propriedades Publicadas
    
    /// Estado atual da reprodução (idle, playing, paused, completed).
    public private(set) var state: RSVPPlaybackState = .idle
    
    /// Lista de palavras tokenizadas para leitura.
    public private(set) var words: [String] = []
    
    /// Índice da palavra sendo visualizada no momento.
    public private(set) var currentIndex: Int = 0
    
    /// Configurações de velocidade (WPM) e pausas cognitivas.
    public var config: RSVPConfiguration
    
    /// Contador de palavras lidas durante a sessão atual (usado para telemetria e Speed Ramp).
    public private(set) var sessionWordsReadCount: Int = 0
    
    /// Callback opcional invocado sempre que o índice da palavra avança (útil para auto-save de progresso).
    public var onIndexChanged: ((Int) -> Void)?
    
    /// Auxiliar para conter a referência da Task com acesso seguro em deinit.
    private final class TaskHolder: @unchecked Sendable {
        var task: Task<Void, Never>?
    }
    
    private let taskHolder = TaskHolder()
    
    // MARK: - Inicializador
    
    /// Cria uma nova instância do RSVPEngine.
    /// - Parameter config: Configurações de leitura (default: 300 WPM, pausas dinâmicas ativadas).
    public init(config: RSVPConfiguration = RSVPConfiguration()) {
        self.config = config
    }
    
    deinit {
        taskHolder.task?.cancel()
    }
    
    // MARK: - Propriedades Computadas
    
    /// Palavra textual sendo exibida no instante presente.
    public var currentWord: String {
        guard !words.isEmpty, currentIndex >= 0 && currentIndex < words.count else {
            return ""
        }
        return words[currentIndex]
    }
    
    /// Lista de palavras do chunk atual (se chunkSize > 1).
    public var currentChunkWords: [String] {
        guard !words.isEmpty, currentIndex >= 0 && currentIndex < words.count else {
            return []
        }
        let size = max(1, config.chunkSize)
        let end = min(currentIndex + size, words.count)
        return Array(words[currentIndex..<end])
    }
    
    /// Texto unificado do chunk atual.
    public var currentChunkText: String {
        currentChunkWords.joined(separator: " ")
    }
    
    /// Decomposição da palavra atual nos 3 segmentos visuais para fixação no ORP.
    public var currentSplitWord: ORPSplitWord {
        ORPHelper.splitWord(currentWord)
    }
    
    /// Síntese bimodal de fala sincronizada.
    public var bimodalSynthesizer: BimodalSpeechSynthesizer?
    
    /// Indica se o leitor está reproduzindo ativamente palavras.
    public var isPlaying: Bool {
        state == .playing
    }
    
    /// Indica se a leitura alcançou o término do documento.
    public var isCompleted: Bool {
        state == .completed || (totalWords > 0 && currentIndex >= totalWords)
    }
    
    /// Total de palavras disponíveis.
    public var totalWords: Int {
        words.count
    }
    
    /// Progresso normalizado de leitura de 0.0 a 1.0.
    public var progress: Double {
        guard totalWords > 0 else { return 0.0 }
        return min(max(0.0, Double(currentIndex) / Double(totalWords)), 1.0)
    }
    
    /// Estimativa de minutos restantes na velocidade atual em WPM.
    public var remainingMinutes: Double {
        guard config.wpm > 0 else { return 0.0 }
        let remainingWords = max(0, totalWords - currentIndex)
        return Double(remainingWords) / Double(config.wpm)
    }
    
    // MARK: - Carga de Conteúdo
    
    /// Carrega uma lista de palavras no motor e posiciona o cursor inicial.
    /// - Parameters:
    ///   - words: Sequência de palavras formatadas.
    ///   - initialIndex: Posição inicial (retomada de onde parou).
    public func load(words: [String], initialIndex: Int = 0) {
        pause()
        self.words = words
        let safeIndex = min(max(0, initialIndex), words.count)
        self.currentIndex = safeIndex
        self.state = (safeIndex >= words.count && !words.isEmpty) ? .completed : .idle
    }
    
    // MARK: - Controle de Reprodução
    
    /// Inicia ou retoma a reprodução serial das palavras.
    public func play() {
        guard !words.isEmpty else { return }
        
        // Se já havia finalizado o texto, recomeça do início
        if currentIndex >= words.count {
            currentIndex = 0
        }
        
        state = .playing
        startPlaybackLoop()
    }
    
    /// Pausa a reprodução no índice atual.
    public func pause() {
        taskHolder.task?.cancel()
        taskHolder.task = nil
        bimodalSynthesizer?.pause()
        
        if state == .playing {
            state = .paused
            onIndexChanged?(currentIndex)
        }
    }
    
    /// Alterna entre Play e Pause.
    public func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    /// Ajusta a velocidade de leitura (WPM).
    /// - Parameter newWPM: Palavras por minuto desejadas (100 a 1000).
    public func setWPM(_ newWPM: Int) {
        config.wpm = newWPM
    }
    
    // MARK: - Navegação e Seek
    
    /// Move o cursor de leitura diretamente para um índice específico.
    /// - Parameter index: Índice desejado.
    public func seek(to index: Int) {
        let clampedIndex = min(max(0, index), words.count)
        self.currentIndex = clampedIndex
        bimodalSynthesizer?.stop()
        
        if clampedIndex >= words.count && !words.isEmpty {
            state = .completed
            pause()
        } else if state == .completed {
            state = .paused
        }
        
        onIndexChanged?(currentIndex)
    }
    
    /// Avança uma quantidade fixa de palavras (default: 1 palavra).
    public func stepForward(count: Int = 1) {
        seek(to: currentIndex + count)
    }
    
    /// Retrocede uma quantidade fixa de palavras (Requisito de UX: botão -10 palavras).
    public func stepBackward(count: Int = 10) {
        seek(to: currentIndex - count)
    }
    
    /// Salta para o início da próxima frase (após ponto final, interrogação ou exclamação).
    public func advanceSentence() {
        guard !words.isEmpty else { return }
        let terminators: Set<Character> = [".", "!", "?"]
        
        for i in currentIndex..<words.count {
            let word = words[i]
            if let lastChar = word.last, terminators.contains(lastChar) {
                seek(to: min(i + 1, words.count))
                return
            }
        }
        seek(to: words.count)
    }
    
    /// Retorna para o início da frase atual ou da frase anterior.
    public func rewindSentence() {
        guard !words.isEmpty else { return }
        let terminators: Set<Character> = [".", "!", "?"]
        
        var searchIndex = max(0, currentIndex - 2)
        while searchIndex > 0 {
            let word = words[searchIndex]
            if let lastChar = word.last, terminators.contains(lastChar) {
                seek(to: searchIndex + 1)
                return
            }
            searchIndex -= 1
        }
        seek(to: 0)
    }
    
    /// Reinicia a leitura para o início do documento.
    public func reset() {
        pause()
        bimodalSynthesizer?.stop()
        seek(to: 0)
        state = .idle
    }
    
    // MARK: - Loop de Temporização de Alta Precisão
    
    /// Executa o ciclo de apresentação com atraso adaptativo por palavra.
    private func startPlaybackLoop() {
        taskHolder.task?.cancel()
        
        taskHolder.task = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.state == .playing else { break }
                
                // Verifica condição de término
                if self.currentIndex >= self.words.count {
                    self.state = .completed
                    self.onIndexChanged?(self.currentIndex)
                    break
                }
                
                let stepSize = max(1, self.config.chunkSize)
                let chunk = self.currentChunkWords
                guard !chunk.isEmpty else { break }
                
                let isParagraphEnd = chunk.contains(where: { $0.contains("\n") })
                let duration = stepSize > 1 ? self.config.duration(for: chunk, isEndOfParagraph: isParagraphEnd) : self.config.duration(for: self.currentWord, isEndOfParagraph: isParagraphEnd)
                
                if self.config.bimodalAudioEnabled {
                    let spokenText = chunk.joined(separator: " ")
                    self.bimodalSynthesizer?.speak(text: spokenText, wpm: self.config.wpm)
                }
                
                // Converte segundos em nanossegundos (1s = 1_000_000_000 ns)
                let sleepNanoseconds = UInt64(max(0.01, duration) * 1_000_000_000)
                
                do {
                    try await Task.sleep(nanoseconds: sleepNanoseconds)
                } catch {
                    // Cancelamento cooperativo
                    break
                }
                
                guard !Task.isCancelled, self.state == .playing else { break }
                
                let nextIndex = self.currentIndex + stepSize
                self.sessionWordsReadCount += chunk.count
                
                // Aplica aceleração gradual no Modo Treinador (Speed Ramp)
                if self.config.speedRampEnabled && (self.sessionWordsReadCount % self.config.speedRampIntervalWords == 0) {
                    let newWPM = min(self.config.wpm + self.config.speedRampDeltaWPM, self.config.speedRampMaxWPM)
                    self.config.wpm = newWPM
                }
                
                if nextIndex >= self.words.count {
                    self.currentIndex = self.words.count
                    self.state = .completed
                    self.onIndexChanged?(self.currentIndex)
                    break
                } else {
                    self.currentIndex = nextIndex
                    self.onIndexChanged?(self.currentIndex)
                }
            }
        }
    }
}
