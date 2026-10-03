//
//  OCRResult.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import CoreGraphics

/// Metadados de uma linha de texto reconhecida pelo Vision Framework.
public struct RecognizedLineInfo: Sendable, Equatable {
    /// Texto reconhecido para esta linha.
    public let text: String
    
    /// Nível de confiança atribuído pelo Vision (0.0 a 1.0).
    public let confidence: Float
    
    /// Bounding box normalizado no espaço de coordenadas do Vision (origem inferior-esquerda).
    public let boundingBox: CGRect
    
    public init(text: String, confidence: Float, boundingBox: CGRect) {
        self.text = text
        self.confidence = confidence
        self.boundingBox = boundingBox
    }
}

/// Resultado consolidado do processamento OCR e do parser de texto.
public struct OCRResult: Sendable, Equatable {
    /// Texto bruto extraído diretamente das observações do Vision.
    public let rawText: String
    
    /// Texto limpo, com quebras de linha de parágrafo preservadas e quebras artificiais unificadas.
    public let cleanedText: String
    
    /// Sequência ordenada de palavras (tokens) prontas para o motor RSVP.
    public let words: [String]
    
    /// Grau médio de confiança do reconhecimento óptico (de 0.0 a 1.0).
    public let averageConfidence: Float
    
    /// Lista estruturada de linhas com metadados de posicionamento.
    public let lines: [RecognizedLineInfo]
    
    public init(
        rawText: String,
        cleanedText: String,
        words: [String],
        averageConfidence: Float,
        lines: [RecognizedLineInfo] = []
    ) {
        self.rawText = rawText
        self.cleanedText = cleanedText
        self.words = words
        self.averageConfidence = averageConfidence
        self.lines = lines
    }
    
    /// Total de palavras extraídas.
    public var wordCount: Int {
        words.count
    }
    
    /// Título sugerido automaticamente a partir das primeiras palavras do documento.
    public var suggestedTitle: String {
        guard !words.isEmpty else { return "Documento Escaneado" }
        let candidateWords = words.prefix(6)
        var title = candidateWords.joined(separator: " ")
        // Remove pontuações finais indesejadas no título
        while let last = title.last, [",", ".", ";", ":", "-", "—"].contains(last) {
            title.removeLast()
        }
        return title.isEmpty ? "Documento Escaneado" : title
    }
}
