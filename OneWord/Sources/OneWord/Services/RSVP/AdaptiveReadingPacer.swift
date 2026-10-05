//
//  AdaptiveReadingPacer.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation

/// Algoritmo neurocognitivo para modulação dinâmica do tempo de exposição no RSVP (Smart WPM).
/// Modula a duração de cada palavra com base no comprimento de caracteres, densidade silábica,
/// marcadores sintáticos, numerais e limites oracionais, reduzindo a sobrecarga foveal.
public final class AdaptiveReadingPacer: Sendable {
    
    public init() {}
    
    /// Calcula a duração foveal ótima em segundos para uma palavra ou chunk.
    /// - Parameters:
    ///   - word: Palavra a ser exibida.
    ///   - baseWPM: Velocidade nominal selecionada pelo usuário (ex: 300 WPM).
    ///   - isSmartWPMEnabled: Se falso, aplica apenas a cadência uniforme do WPM base.
    ///   - isEndOfParagraph: Indica se a palavra finaliza um parágrafo estrutural.
    /// - Returns: Duração calibrada em segundos.
    public func duration(
        for word: String,
        baseWPM: Int,
        isSmartWPMEnabled: Bool = true,
        isEndOfParagraph: Bool = false
    ) -> TimeInterval {
        guard baseWPM > 0 else { return 0.2 }
        let baseDuration = 60.0 / Double(baseWPM)
        
        guard isSmartWPMEnabled else {
            return baseDuration
        }
        
        let multiplier = cognitiveLoadMultiplier(for: word, isEndOfParagraph: isEndOfParagraph)
        // Garante que o multiplicador se mantenha em uma janela confortável (0.75x a 2.85x / 3.2x em parágrafos)
        let maxClamp = (isEndOfParagraph || word.contains("\n")) ? 3.2 : 2.85
        let clampedMultiplier = min(max(multiplier, 0.75), maxClamp)
        return baseDuration * clampedMultiplier
    }
    
    /// Multiplicador de carga cognitiva derivado de análise morfológica, pontuação e micro-pausas sinápticas oracionais.
    /// Baseado no Sentence Wrap-Up Effect (Rayner et al., 2012; Just & Carpenter, 1980) e alívio da memória de trabalho.
    public func cognitiveLoadMultiplier(for rawWord: String, isEndOfParagraph: Bool = false) -> Double {
        let clean = rawWord.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return 1.0 }
        
        var multiplier: Double = 1.0
        
        // 1. Comprimento e Complexidade Silábica (reconhecimento morfológico foveal)
        let charCount = clean.count
        switch charCount {
        case 1...3:
            // Artigos, conjunções curtas ("o", "de", "em", "que") requerem menor tempo de fixação
            multiplier *= 0.85
        case 4...7:
            multiplier *= 1.0
        case 8...11:
            multiplier *= 1.15
        default:
            // Palavras longas (> 11 letras) demandam síntese foveal estendida
            multiplier *= 1.30
        }
        
        // 2. Detecção de Micro-Pausa Sináptica Oracional (Sentence Wrap-Up Effect)
        // Lida com pontuação terminal direta ou entre aspas/parênteses (ex: "fim.", "mundo!", "verdade?", "ele.)")
        let isTerminalSentence = clean.hasSuffix(".") || clean.hasSuffix("!") || clean.hasSuffix("?") ||
                                 clean.hasSuffix(".\"") || clean.hasSuffix("!\"") || clean.hasSuffix("?\"") ||
                                 clean.hasSuffix(".”") || clean.hasSuffix("!”") || clean.hasSuffix("?”") ||
                                 clean.hasSuffix(".)") || clean.hasSuffix("!)") || clean.hasSuffix("?)")
        let isEllipsis = clean.hasSuffix("...") || clean.hasSuffix("…")
        let isClauseSeparator = clean.hasSuffix(",") || clean.hasSuffix(";") || clean.hasSuffix(":") ||
                                clean.hasSuffix(",\"") || clean.hasSuffix(";\"") || clean.hasSuffix(",”")
        let isDashOrParen = clean.hasSuffix("—") || clean.hasSuffix("-") || clean.hasSuffix(")") || clean.hasSuffix("]")
        
        if isEndOfParagraph || rawWord.contains("\n") {
            // Pausa sináptica de parágrafo: consolidação profunda do modelo situacional
            multiplier *= 2.80
        } else if isTerminalSentence {
            // Fechamento oracional: alívio da memória de trabalho fonológica e empacotamento semântico
            multiplier *= 2.40
        } else if isEllipsis {
            // Reticências: suspensão oracional reflexiva
            multiplier *= 2.10
        } else if isClauseSeparator {
            // Pausa oracional intermediária para orações coordenadas/subordinadas
            multiplier *= 1.45
        } else if isDashOrParen {
            multiplier *= 1.20
        }
        
        // 3. Numerais e Dados Numéricos (Conversão simbólica fonética)
        if clean.contains(where: { $0.isNumber }) {
            multiplier *= 1.25
        }
        
        // 4. Siglas ou Palavras em Caixa Alta (Ex: "NASA", "IA", "UNESCO")
        let letters = clean.filter { $0.isLetter }
        if letters.count >= 2 && letters.allSatisfy({ $0.isUppercase }) {
            multiplier *= 1.20
        }
        
        return multiplier
    }
    
    /// Duração adaptativa combinada para chunks de múltiplas palavras (Modo 2 ou 3 palavras).
    public func duration(
        for words: [String],
        baseWPM: Int,
        isSmartWPMEnabled: Bool = true,
        isEndOfParagraph: Bool = false
    ) -> TimeInterval {
        guard !words.isEmpty else { return 0.2 }
        guard baseWPM > 0 else { return 0.2 }
        
        let baseWordDuration = 60.0 / Double(baseWPM)
        let totalBaseDuration = baseWordDuration * Double(words.count)
        
        guard isSmartWPMEnabled else {
            return totalBaseDuration
        }
        
        // Média ponderada dos fatores das palavras individuais
        let averageFactor = words.reduce(0.0) { sum, word in
            let isLastInChunk = (word == words.last)
            return sum + cognitiveLoadMultiplier(for: word, isEndOfParagraph: isLastInChunk && isEndOfParagraph)
        } / Double(words.count)
        
        let maxClamp = (isEndOfParagraph || words.contains(where: { $0.contains("\n") })) ? 3.2 : 2.85
        let clampedFactor = min(max(averageFactor, 0.75), maxClamp)
        return totalBaseDuration * clampedFactor
    }
}
