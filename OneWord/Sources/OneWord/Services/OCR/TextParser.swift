//
//  TextParser.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation

/// Responsável pela higienização, estruturação e tokenização do texto bruto extraído pelo OCR.
/// Remove quebras de linha artificiais geradas pela formatação de páginas físicas e prepara
/// o array de palavras para o motor de apresentação serial rápida (RSVP).
public struct TextParser: Sendable {
    
    public init() {}
    
    // MARK: - API Principal
    
    /// Processa o texto bruto do OCR, retornando o texto estruturado e o array de palavras tokenizadas.
    /// - Parameter rawText: String bruta contendo quebras de linha e hifens do OCR.
    /// - Returns: Tupla contendo `cleanedText` (legível) e `words` (otimizado para RSVP).
    public func parse(rawText: String) -> (cleanedText: String, words: [String]) {
        let cleaned = cleanText(rawText)
        let words = tokenizeWords(from: cleaned)
        return (cleaned, words)
    }
    
    /// Processa uma lista estruturada de linhas reconhecidas, ordenando-as espacialmente antes do parsing.
    /// - Parameter lines: Linhas reconhecidas pelo Vision com coordenadas.
    /// - Returns: Tupla contendo `cleanedText` e `words`.
    public func parse(lines: [RecognizedLineInfo]) -> (cleanedText: String, words: [String]) {
        let sortedLines = sortLinesSpatially(lines)
        let mergedRaw = sortedLines.map(\.text).joined(separator: "\n")
        return parse(rawText: mergedRaw)
    }
    
    // MARK: - Higienização e Remoção de Quebras de Linha
    
    /// Limpa o texto bruto: remove hifenização ao final de linha, unifica linhas pertencentes ao mesmo
    /// parágrafo e preserva divisões de parágrafos legítimas (linhas em branco).
    /// - Parameter rawText: Texto original extraído do OCR.
    /// - Returns: Texto com parágrafos fluidos e pontuação preservada.
    public func cleanText(_ rawText: String) -> String {
        guard !rawText.isEmpty else { return "" }
        
        // 1. Normaliza quebras de linha para \n
        var text = rawText
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        
        // 2. Remove caracteres de controle invisíveis e espaços não separáveis
        text = text.replacingOccurrences(of: "\u{00A0}", with: " ")
        text = text.replacingOccurrences(of: "\u{200B}", with: "") // Zero-width space
        
        // 3. Trata hifenização ao final de linha (ex: "desenvolvi-\n mento" -> "desenvolvimento")
        text = dehyphenate(text)
        
        // 4. Separação em blocos de parágrafos reais (linhas em branco como delimitadores)
        let rawParagraphs = text.components(separatedBy: "\n\n")
        
        var cleanedParagraphs: [String] = []
        
        for paragraph in rawParagraphs {
            let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            
            // Quebra as linhas dentro deste parágrafo
            let lines = trimmed.components(separatedBy: "\n")
            var paragraphBuffer = ""
            
            for line in lines {
                let cleanLine = line.trimmingCharacters(in: .whitespaces)
                guard !cleanLine.isEmpty else { continue }
                
                if paragraphBuffer.isEmpty {
                    paragraphBuffer = cleanLine
                } else {
                    // Se for marcador de lista, travessão de diálogo ou citação, preserva a quebra
                    if cleanLine.hasPrefix("—") || cleanLine.hasPrefix("- ") || cleanLine.hasPrefix("•") {
                        paragraphBuffer += "\n" + cleanLine
                    } else {
                        // Linha corrida comum de página de livro: une com espaço simples
                        paragraphBuffer += " " + cleanLine
                    }
                }
            }
            
            cleanedParagraphs.append(paragraphBuffer)
        }
        
        return cleanedParagraphs.joined(separator: "\n\n")
    }
    
    /// Converte um texto limpo em uma sequência linear de palavras para o leitor RSVP.
    /// Preserva pontuação colada à palavra (ex: "verdade?", "atenção,", "fim.") para que
    /// o motor RSVP aplique as pausas cognitivas dinâmicas correspondentes.
    /// - Parameter text: Texto limpo com parágrafos.
    /// - Returns: Array com palavras formatadas.
    public func tokenizeWords(from text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        
        // Divide por qualquer espaço em branco ou quebra de linha
        let rawTokens = text.components(separatedBy: .whitespacesAndNewlines)
        
        var tokens: [String] = []
        tokens.reserveCapacity(rawTokens.count)
        
        for token in rawTokens {
            let trimmed = token.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            // Descarta artefatos isolados de ruído de OCR (hífens soltos, bullets isolados)
            if isNoiseArtifact(trimmed) {
                continue
            }
            
            tokens.append(trimmed)
        }
        
        return tokens
    }
    
    // MARK: - Tratamento de Hifenização
    
    /// Resolve palavras que foram quebradas no fim da linha física com hífen.
    /// Exemplos:
    /// - "cons- \n ciência" -> "consciência"
    /// - "super-\n homem" -> "super-homem" (mantém hífen se for palavra composta)
    private func dehyphenate(_ text: String) -> String {
        // Padrão regex para detectar hífens no final de linha seguidos por quebra e nova palavra
        // Grupo 1: Letra antes do hífen
        // Grupo 2: Caractere de hífen (-, ‐, ‑, –)
        // Grupo 3: Quebra de linha e possíveis espaços
        // Grupo 4: Primeira letra da linha seguinte
        let pattern = "([\\p{L}])[-‐‑–][ \\t]*\\n+[ \\t]*([\\p{L}])"
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return text
        }
        
        let range = NSRange(location: 0, length: (text as NSString).length)
        
        // Em português e inglês, se a segunda palavra começa com minúscula, 99% das vezes é uma quebra tipográfica da mesma palavra
        let modified = regex.stringByReplacingMatches(
            in: text,
            options: [],
            range: range,
            withTemplate: "$1$2"
        )
        
        return modified
    }
    
    // MARK: - Ordenação Espacial de Linhas OCR
    
    /// Ordena as linhas reconhecidas pelo Vision no fluxo de leitura natural:
    /// do topo para a base (coordenada Y decrescente no Vision) e da esquerda para a direita (X crescente).
    /// Agrupa linhas com alturas verticais semelhantes (mesma faixa de linha).
    /// - Parameter lines: Linhas detectadas com coordenadas normalizadas.
    /// - Returns: Linhas reordenadas de forma legível.
    public func sortLinesSpatially(_ lines: [RecognizedLineInfo]) -> [RecognizedLineInfo] {
        guard lines.count > 1 else { return lines }
        
        // Vision tem origem no canto inferior esquerdo (0,0) até superior direito (1,1).
        // Portanto, linhas mais altas na página possuem Y maior.
        // Tolerância vertical típica para agrupar palavras na mesma linha (~1.5% da altura da página)
        let verticalTolerance: CGFloat = 0.015
        
        return lines.sorted { first, second in
            let yDelta = abs(first.boundingBox.midY - second.boundingBox.midY)
            if yDelta <= verticalTolerance {
                // Mesma linha física: ordena da esquerda para a direita
                return first.boundingBox.minX < second.boundingBox.minX
            } else {
                // Linhas diferentes: a mais acima vem primeiro (maior Y no Vision)
                return first.boundingBox.midY > second.boundingBox.midY
            }
        }
    }
    
    // MARK: - Utilitários
    
    /// Verifica se uma linha ou trecho termina com pontuação forte (. ! ?).
    private func endsWithSentenceTerminator(_ text: String) -> Bool {
        guard let lastChar = text.trimmingCharacters(in: .whitespaces).last else {
            return false
        }
        return [".", "!", "?"].contains(lastChar)
    }
    
    /// Detecta se um token consiste exclusivamente em ruído gráfico de OCR.
    private func isNoiseArtifact(_ token: String) -> Bool {
        let noiseSet = CharacterSet(charactersIn: "-–—•·~_|=+*^`¬")
        let nonNoise = token.unicodeScalars.filter { !noiseSet.contains($0) }
        return nonNoise.isEmpty
    }
}
