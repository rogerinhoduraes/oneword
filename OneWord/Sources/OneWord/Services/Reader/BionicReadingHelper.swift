//
//  BionicReadingHelper.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftUI

/// Segmento de uma palavra adaptada para leitura biônica (ponto de fixação foveal).
public struct BionicWordSegment: Sendable, Identifiable {
    public var id: String { "\(prefix)_\(suffix)" }
    public let prefix: String  // Letras em negrito para fixação do olhar
    public let suffix: String  // Letras restantes completadas pelo cérebro
    public let fullWord: String
    
    public init(prefix: String, suffix: String, fullWord: String) {
        self.prefix = prefix
        self.suffix = suffix
        self.fullWord = fullWord
    }
}

/// Auxiliar de formatação para Leitura Biônica (Bionic Reading).
/// Destaca as primeiras letras de cada palavra para direcionar as fixações foveais
/// e acelerar a varredura visual em parágrafos contínuos.
public final class BionicReadingHelper: Sendable {
    
    public init() {}
    
    /// Atalho estático para decompor uma palavra individual.
    public static func splitWord(_ word: String) -> BionicWordSegment {
        BionicReadingHelper().splitWord(word)
    }
    
    /// Atalho estático para formatar texto completo para AttributedString.
    public static func formatToAttributedString(_ text: String, textColor: Color = .primary) -> AttributedString {
        BionicReadingHelper().formatToAttributedString(text, textColor: textColor)
    }
    
    /// Decompõe uma palavra individual no prefixo de fixação em negrito e no sufixo complementar.
    public func splitWord(_ word: String) -> BionicWordSegment {
        guard !word.isEmpty else {
            return BionicWordSegment(prefix: "", suffix: "", fullWord: "")
        }
        
        let lettersOnly = word.filter { $0.isLetter }
        guard !lettersOnly.isEmpty else {
            return BionicWordSegment(prefix: word, suffix: "", fullWord: word)
        }
        
        let letterCount = lettersOnly.count
        let boldCount: Int
        switch letterCount {
        case 1:
            boldCount = 1
        case 2...3:
            boldCount = 1
        case 4...6:
            boldCount = 2
        case 7...9:
            boldCount = 3
        default:
            boldCount = max(4, Int(Double(letterCount) * 0.45))
        }
        
        var currentLetterIdx = 0
        var splitIndex = word.startIndex
        
        for idx in word.indices {
            if word[idx].isLetter {
                currentLetterIdx += 1
                if currentLetterIdx == boldCount {
                    splitIndex = word.index(after: idx)
                    break
                }
            }
        }
        
        let prefix = String(word[..<splitIndex])
        let suffix = String(word[splitIndex...])
        return BionicWordSegment(prefix: prefix, suffix: suffix, fullWord: word)
    }
    
    /// Converte um texto completo em um `AttributedString` formatado com âncoras biônicas em negrito.
    public func formatToAttributedString(_ text: String, textColor: Color = .primary) -> AttributedString {
        var attributed = AttributedString()
        let wordsWithSeparators = tokenizePreservingSeparators(text)
        
        for token in wordsWithSeparators {
            if token.allSatisfy({ $0.isWhitespace || $0.isNewline }) {
                attributed.append(AttributedString(token))
            } else {
                let segment = splitWord(token)
                var boldPart = AttributedString(segment.prefix)
                boldPart.inlinePresentationIntent = .stronglyEmphasized
                boldPart.foregroundColor = textColor
                
                var normalPart = AttributedString(segment.suffix)
                normalPart.foregroundColor = textColor.opacity(0.85)
                
                attributed.append(boldPart)
                attributed.append(normalPart)
            }
        }
        
        return attributed
    }
    
    /// Divide o texto preservando espaços e quebras de linha.
    private func tokenizePreservingSeparators(_ text: String) -> [String] {
        var tokens: [String] = []
        var currentToken = ""
        var isReadingWhitespace = false
        
        for char in text {
            let isSpace = char.isWhitespace || char.isNewline
            if tokens.isEmpty && currentToken.isEmpty {
                isReadingWhitespace = isSpace
            }
            
            if isSpace == isReadingWhitespace {
                currentToken.append(char)
            } else {
                if !currentToken.isEmpty {
                    tokens.append(currentToken)
                }
                currentToken = String(char)
                isReadingWhitespace = isSpace
            }
        }
        if !currentToken.isEmpty {
            tokens.append(currentToken)
        }
        return tokens
    }
}
