//
//  ORPHelper.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation

/// Estrutura que decompõe uma palavra em três segmentos visuais para fixação no ORP (Optimal Recognition Point).
public struct ORPSplitWord: Sendable, Equatable {
    /// Caracteres antes do ponto focal de fixação.
    public let prefix: String
    
    /// Caractere exato de fixação óptica (ponto focal, normalmente colorido em destaque).
    public let focalCharacter: Character
    
    /// Caracteres posteriores ao ponto focal, incluindo eventuais pontuações.
    public let suffix: String
    
    /// Palavra integral original.
    public let originalWord: String
    
    /// Índice baseado em zero do caractere focal dentro da palavra.
    public let focalIndex: Int
}

/// Auxiliar para cálculo do Ponto Óptico de Reconhecimento (Optimal Recognition Point - ORP).
/// O cérebro humano reconhece palavras com maior rapidez quando o olhar fixa ligeiramente
/// à esquerda do centro da palavra (~30% a 35% do comprimento).
public enum ORPHelper {
    
    /// Determina o índice ótimo de fixação visual para uma dada palavra.
    /// - Parameter word: Palavra a ser avaliada.
    /// - Returns: Índice (zero-based) do caractere focal.
    public static func orpIndex(for word: String) -> Int {
        let count = word.count
        switch count {
        case 0, 1:
            return 0
        case 2...5:
            return 1
        case 6...9:
            return 2
        case 10...13:
            return 3
        default:
            return 4
        }
    }
    
    /// Decompõe uma palavra em prefixo, caractere focal (ORP) e sufixo.
    /// - Parameter word: Palavra a ser decomposta.
    /// - Returns: Estrutura `ORPSplitWord` com os 3 componentes.
    public static func splitWord(_ word: String) -> ORPSplitWord {
        guard !word.isEmpty else {
            return ORPSplitWord(prefix: "", focalCharacter: " ", suffix: "", originalWord: "", focalIndex: 0)
        }
        
        let index = min(orpIndex(for: word), max(0, word.count - 1))
        let stringIndex = word.index(word.startIndex, offsetBy: index)
        
        let prefix = String(word[..<stringIndex])
        let focal = word[stringIndex]
        let suffixIndex = word.index(after: stringIndex)
        let suffix = String(word[suffixIndex...])
        
        return ORPSplitWord(
            prefix: prefix,
            focalCharacter: focal,
            suffix: suffix,
            originalWord: word,
            focalIndex: index
        )
    }
}
