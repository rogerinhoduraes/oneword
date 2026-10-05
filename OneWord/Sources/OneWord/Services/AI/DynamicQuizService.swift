//
//  DynamicQuizService.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import NaturalLanguage

/// Serviço para geração autônoma de questionários de compreensão e retenção para qualquer livro ou artigo lido.
public final class DynamicQuizService: Sendable {
    
    public init() {}
    
    /// Gera de 3 a 5 perguntas de múltipla escolha a partir do texto do documento.
    public func generateQuiz(from text: String, title: String = String(localized: "Questionário do Livro"), count: Int = 3) -> [BenchmarkQuestion] {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 35 && $0.components(separatedBy: .whitespaces).count >= 7 }
        
        guard sentences.count >= count else {
            return []
        }
        
        var questions: [BenchmarkQuestion] = []
        var usedIndices = Set<Int>()
        
        for (i, sentence) in sentences.enumerated() {
            if usedIndices.count >= count { break }
            guard !usedIndices.contains(i) else { continue }
            
            // Procura verbos e relações declarativas
            let words = sentence.components(separatedBy: .whitespaces).filter { $0.count > 3 }
            guard words.count >= 4 else { continue }
            
            let targetWord = words.first(where: { $0.allSatisfy { $0.isLetter } && $0.count >= 5 }) ?? words[1]
            let maskedSentence = sentence.replacingOccurrences(of: targetWord, with: "_______")
            
            let distractor1 = generateDistractor(for: targetWord, offset: 1)
            let distractor2 = generateDistractor(for: targetWord, offset: 2)
            
            var options = [targetWord, distractor1, distractor2]
            options.shuffle()
            let correctIndex = options.firstIndex(of: targetWord) ?? 0
            
            let question = BenchmarkQuestion(
                id: usedIndices.count + 1,
                text: String(localized: "Complete o sentido do trecho lido:\n\"\(maskedSentence)\""),
                options: options,
                correctIndex: correctIndex
            )
            
            questions.append(question)
            usedIndices.insert(i)
        }
        
        return questions
    }
    
    private func generateDistractor(for word: String, offset: Int) -> String {
        let pool: [String]
        switch AppLanguage.code {
        case "pt":
            pool = [
                "dispersão", "aceleração", "mecanismo", "foco", "leitura",
                "processamento", "retenção", "memória", "atenção", "fóvea",
                "estabilidade", "frequência", "amplitude", "interferência", "continuidade"
            ]
        case "es":
            pool = [
                "dispersión", "aceleración", "mecanismo", "enfoque", "lectura",
                "procesamiento", "retención", "memoria", "atención", "fóvea",
                "estabilidad", "frecuencia", "amplitud", "interferencia", "continuidad"
            ]
        default:
            pool = [
                "dispersion", "acceleration", "mechanism", "focus", "reading",
                "processing", "retention", "memory", "attention", "fovea",
                "stability", "frequency", "amplitude", "interference", "continuity"
            ]
        }
        let lower = word.lowercased()
        let available = pool.filter { $0 != lower }
        let index = abs(word.hashValue + offset) % available.count
        return available[index].capitalized
    }
}
