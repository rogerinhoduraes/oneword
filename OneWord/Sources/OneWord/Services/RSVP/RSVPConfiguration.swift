//
//  RSVPConfiguration.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation

/// Configurações e parâmetros temporais para o motor RSVP (Rapid Serial Visual Presentation).
/// Controla velocidade (WPM), pausas dinâmicas por pontuação e auxílios cognitivos visuais.
public struct RSVPConfiguration: Sendable, Equatable {
    /// Velocidade de leitura em palavras por minuto (Words Per Minute).
    /// Faixa típica: 150 a 1000 WPM (padrão inicial: 300 WPM).
    public var wpm: Int {
        didSet {
            wpm = min(max(wpm, Self.minWPM), Self.maxWPM)
        }
    }
    
    /// Pausa extra em segundos para pontuações fortes (. ! ? ...) que encerram frases.
    /// Requisito de UX: ~200-300ms (padrão: 0.250s / 250ms).
    public var strongPunctuationExtraDelay: TimeInterval
    
    /// Pausa extra em segundos para pontuações intermediárias (, ; :).
    /// Requisito de UX: ~100-150ms (padrão: 0.120s / 120ms).
    public var mediumPunctuationExtraDelay: TimeInterval
    
    /// Pausa extra sutil para palavras longas (> 10 caracteres) para permitir absorção visual.
    public var longWordExtraDelay: TimeInterval
    
    /// Ativa ou desativa o cálculo dinâmico de pausas por pontuação.
    public var enableDynamicPauses: Bool
    
    /// Habilita destaque visual no Ponto Óptico de Reconhecimento (ORP - Optimal Recognition Point).
    public var enableORPHighlight: Bool
    
    /// Habilita o Modo Treinador com Aceleração Gradual (Speed Ramp).
    public var speedRampEnabled: Bool
    
    /// Intervalo de palavras para cada incremento de velocidade no Speed Ramp (ex: 40 palavras).
    public var speedRampIntervalWords: Int
    
    /// Incremento de WPM aplicado a cada intervalo no Speed Ramp (ex: +15 WPM).
    public var speedRampDeltaWPM: Int
    
    /// Velocidade máxima teto permitida para o Speed Ramp.
    public var speedRampMaxWPM: Int
    
    // MARK: - Constantes
    
    public static let minWPM: Int = 100
    public static let maxWPM: Int = 1000
    public static let defaultWPM: Int = 300
    
    // MARK: - Inicializador
    
    public init(
        wpm: Int = defaultWPM,
        strongPunctuationExtraDelay: TimeInterval = 0.250,
        mediumPunctuationExtraDelay: TimeInterval = 0.120,
        longWordExtraDelay: TimeInterval = 0.050,
        enableDynamicPauses: Bool = true,
        enableORPHighlight: Bool = true,
        speedRampEnabled: Bool = false,
        speedRampIntervalWords: Int = 40,
        speedRampDeltaWPM: Int = 15,
        speedRampMaxWPM: Int = 700
    ) {
        self.wpm = min(max(wpm, Self.minWPM), Self.maxWPM)
        self.strongPunctuationExtraDelay = strongPunctuationExtraDelay
        self.mediumPunctuationExtraDelay = mediumPunctuationExtraDelay
        self.longWordExtraDelay = longWordExtraDelay
        self.enableDynamicPauses = enableDynamicPauses
        self.enableORPHighlight = enableORPHighlight
        self.speedRampEnabled = speedRampEnabled
        self.speedRampIntervalWords = speedRampIntervalWords
        self.speedRampDeltaWPM = speedRampDeltaWPM
        self.speedRampMaxWPM = speedRampMaxWPM
    }
    
    // MARK: - Métodos de Cálculo Temporal
    
    /// Intervalo base de exibição por palavra sem considerar pontuações (em segundos).
    public var baseInterval: TimeInterval {
        guard wpm > 0 else { return 0.2 }
        return 60.0 / Double(wpm)
    }
    
    /// Calcula a duração total de exibição de uma palavra específica,
    /// somando o tempo base à pausa dinâmica cognitiva conforme a pontuação final.
    /// - Parameter word: Palavra a ser avaliada.
    /// - Returns: Duração em segundos (TimeInterval).
    public func duration(for word: String) -> TimeInterval {
        var interval = baseInterval
        
        guard enableDynamicPauses, !word.isEmpty else {
            return interval
        }
        
        let trimmed = word.trimmingCharacters(in: .whitespaces)
        guard let lastChar = trimmed.last else { return interval }
        
        // Pausa forte: ponto final, exclamação, interrogação ou reticências
        if [".", "!", "?"].contains(lastChar) || trimmed.hasSuffix("...") {
            interval += strongPunctuationExtraDelay
        }
        // Pausa intermediária: vírgula, ponto e vírgula, dois pontos, travessão
        else if [",", ";", ":", "—"].contains(lastChar) {
            interval += mediumPunctuationExtraDelay
        }
        
        // Compensação adicional para palavras extensas
        if trimmed.count > 10 {
            interval += longWordExtraDelay
        }
        
        return interval
    }
}
