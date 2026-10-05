//
//  TextSummarizerService.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import NaturalLanguage

/// Resumo executivo dos pontos focais de um capítulo ou artigo.
public struct ExecutiveSummary: Identifiable, Sendable {
    public var id: String { bullets.joined() }
    public let title: String
    public let bullets: [String]
    public let wordCount: Int
    public let estimatedReadingSeconds: Int
    
    public init(title: String, bullets: [String], wordCount: Int) {
        self.title = title
        self.bullets = bullets
        self.wordCount = wordCount
        self.estimatedReadingSeconds = max(5, Int(Double(wordCount) / 5.0)) // ~300 WPM
    }
}

/// Modelo neurocognitivo de pré-ativação de esquemas conceituais (Priming).
/// Prepara o córtex pré-frontal e a área de Wernicke antes do fluxo contínuo de palavras no RSVP.
public struct CognitivePrimingContext: Identifiable, Sendable {
    public var id: String { title + focusQuestion }
    public let title: String
    public let anchorConcepts: [String]
    public let keyInsights: [String]
    public let focusQuestion: String
    public let estimatedReadingSeconds: Int
    
    public init(
        title: String,
        anchorConcepts: [String],
        keyInsights: [String],
        focusQuestion: String,
        estimatedReadingSeconds: Int
    ) {
        self.title = title
        self.anchorConcepts = anchorConcepts
        self.keyInsights = keyInsights
        self.focusQuestion = focusQuestion
        self.estimatedReadingSeconds = estimatedReadingSeconds
    }
}

/// Serviço de sumarização extrativa e síntese de tópicos executivos 100% on-device (sem envio de dados para servidores).
public final class TextSummarizerService: Sendable {
    public static let shared = TextSummarizerService()
    
    public init() {}
    
    /// Atalho para retornar diretamente a lista de frases resumidas.
    public func summarize(text: String, maxSentences: Int = 4) -> [String] {
        return summarize(text: text, title: "Resumo", maxBullets: maxSentences).bullets
    }
    
    /// Gera um resumo de 3 a 5 pontos focais a partir do texto de um capítulo ou artigo.
    public func summarize(text: String, title: String = String(localized: "Resumo Executivo"), maxBullets: Int = 4) -> ExecutiveSummary {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else {
            return ExecutiveSummary(title: title, bullets: [String(localized: "Conteúdo indisponível para resumo.")], wordCount: 0)
        }
        
        let sentences = extractSentences(from: cleanText)
        guard sentences.count > maxBullets else {
            return ExecutiveSummary(title: title, bullets: sentences, wordCount: cleanText.components(separatedBy: .whitespacesAndNewlines).count)
        }
        
        // 1. Calcula frequências das palavras de conteúdo (excluindo stopwords)
        let wordFrequencies = computeContentWordFrequencies(from: cleanText)
        
        // 2. Pontua cada sentença
        var scoredSentences: [(sentence: String, score: Double, originalIndex: Int)] = []
        for (index, sentence) in sentences.enumerated() {
            let score = scoreSentence(sentence, wordFrequencies: wordFrequencies, index: index, totalSentences: sentences.count)
            scoredSentences.append((sentence: sentence, score: score, originalIndex: index))
        }
        
        // 3. Seleciona as sentenças de maior pontuação e as ordena pela cronologia original do texto
        let topSentences = scoredSentences
            .sorted(by: { $0.score > $1.score })
            .prefix(maxBullets)
            .sorted(by: { $0.originalIndex < $1.originalIndex })
            .map { $0.sentence }
        
        let totalWords = topSentences.joined(separator: " ").components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        
        return ExecutiveSummary(title: title, bullets: topSentences, wordCount: totalWords)
    }
    
    /// Gera o contexto neurocognitivo de Priming (Pré-leitura ativa) para preparar a rede atencional antes do RSVP.
    /// Baseado na ativação pré-frontal de esquemas prévios e no Efeito de Pré-questionamento (Pre-questioning Effect).
    public func generatePrimingContext(from text: String, title: String = String(localized: "Leitura Focada")) -> CognitivePrimingContext {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else {
            return CognitivePrimingContext(
                title: title,
                anchorConcepts: [String(localized: "Foco"), String(localized: "Atenção"), String(localized: "Leitura")],
                keyInsights: [String(localized: "Conteúdo inicial para calibração visual foveal.")],
                focusQuestion: String(localized: "Qual é a ideia principal que o autor deseja transmitir neste texto?"),
                estimatedReadingSeconds: 30
            )
        }
        
        let wordFrequencies = computeContentWordFrequencies(from: cleanText)
        
        // 1. Extração dos conceitos-âncora mais proeminentes
        let topConcepts = wordFrequencies
            .filter { $0.key.count >= 4 }
            .sorted(by: { $0.value > $1.value })
            .prefix(4)
            .map { $0.key.capitalized }
        
        // 2. Extração dos insights estruturais (resumo curto de 2 a 3 sentenças)
        let summary = summarize(text: cleanText, title: title, maxBullets: 3)
        let bullets = summary.bullets.isEmpty ? [String(localized: "Observe a progressão dos argumentos principais.")] : summary.bullets
        
        // 3. Elaboração da questão focal norteadora (Efeito de Pré-questionamento)
        let mainConcept = topConcepts.first ?? String(localized: "o tema central")
        let focusQuestion: String
        if let firstBullet = bullets.first, firstBullet.count > 20 {
            focusQuestion = String(localized: "Ao acompanhar as palavras no RSVP, foque em identificar como o autor desenvolve o papel de \"\(mainConcept)\".")
        } else {
            focusQuestion = String(localized: "Qual é o objetivo principal e a tese defendida pelo autor neste trecho?")
        }
        
        let wordCount = cleanText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let estSeconds = max(10, Int(Double(wordCount) / 5.0))
        
        return CognitivePrimingContext(
            title: title,
            anchorConcepts: Array(topConcepts),
            keyInsights: bullets,
            focusQuestion: focusQuestion,
            estimatedReadingSeconds: estSeconds
        )
    }
    
    // MARK: - Auxiliares de Processamento
    
    private func extractSentences(from text: String) -> [String] {
        var sentences: [String] = []
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let raw = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            if raw.count > 15 && !raw.hasPrefix("<") {
                sentences.append(raw)
            }
            return true
        }
        
        if sentences.isEmpty {
            sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.count > 15 }
        }
        return sentences
    }
    
    private func computeContentWordFrequencies(from text: String) -> [String: Double] {
        var freqs: [String: Double] = [:]
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        
        let stopwords: Set<String> = [
            "de", "a", "o", "que", "e", "do", "da", "em", "um", "para", "é", "com", "não", "uma", "os", "no", "se", "na", "por", "mais", "as", "dos", "como", "mas", "foi", "ao", "ele", "das", "tem", "à", "seu", "sua", "ou", "ser", "quando", "muito", "nos", "já", "eu", "também", "só", "pelo", "pela", "até", "isso", "ela", "entre", "era", "depois", "sem", "mesmo", "aos", "ter", "seus", "quem", "nas", "me", "esse", "eles", "the", "and", "is", "of", "to", "in", "it", "you", "that", "he", "was", "for", "on", "are", "as", "with", "his", "they", "i", "at", "be", "this", "have", "from", "or", "one", "had", "by", "word", "but", "not", "what", "all", "were", "we", "when", "your", "can", "said"
        ]
        
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            let word = String(text[range]).lowercased()
            if word.count >= 3 && !stopwords.contains(word) && word.allSatisfy({ $0.isLetter }) {
                freqs[word, default: 0.0] += 1.0
            }
            return true
        }
        
        // Normaliza pelo valor máximo
        if let maxFreq = freqs.values.max(), maxFreq > 0 {
            for (key, val) in freqs {
                freqs[key] = val / maxFreq
            }
        }
        
        return freqs
    }
    
    private func scoreSentence(_ sentence: String, wordFrequencies: [String: Double], index: Int, totalSentences: Int) -> Double {
        var score: Double = 0.0
        let words = sentence.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { $0.count >= 3 }
        guard !words.isEmpty else { return 0.0 }
        
        for word in words {
            if let weight = wordFrequencies[word] {
                score += weight
            }
        }
        
        // Média ponderada pela quantidade de palavras
        score = score / Double(words.count)
        
        // Bônus de posição: sentenças no início do texto/parágrafo sintetizam teses principais
        if index == 0 {
            score *= 1.45
        } else if index == 1 || index == totalSentences - 1 {
            score *= 1.25
        }
        
        return score
    }
}
