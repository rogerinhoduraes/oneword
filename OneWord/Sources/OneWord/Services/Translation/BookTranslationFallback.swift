//
//  BookTranslationFallback.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation

/// Provedor de fallback resiliente para tradução instantânea em ambientes de simulador ou offline
/// onde os modelos neurais do iOS Translation ainda não foram baixados pelo usuário.
public enum BookTranslationFallback {
    
    /// Dicionário de frases e parágrafos completos conhecidos de demonstração e clássicos internacionais.
    private static let knownPhrases: [String: String] = [
        "deep work": "trabalho focado",
        "atomic habits": "hábitos atômicos",
        "focus": "foco",
        "the power of now": "o poder do agora"
    ]
    
    /// Dicionário de termos comuns de livros para tradução fluida de páginas.
    private static let dictionaryENtoPT: [String: String] = [
        "the": "o", "a": "um", "an": "um", "and": "e", "or": "ou", "but": "mas", "in": "em",
        "on": "no", "at": "em", "to": "para", "for": "para", "with": "com", "without": "sem",
        "by": "por", "from": "de", "of": "de", "as": "como", "is": "é", "are": "são",
        "was": "foi", "were": "eram", "be": "ser", "been": "sido", "being": "sendo",
        "have": "ter", "has": "tem", "had": "tinha", "do": "fazer", "does": "faz",
        "did": "fez", "will": "irá", "would": "iria", "can": "pode", "could": "poderia",
        "this": "este", "that": "aquele", "these": "estes", "those": "aqueles",
        "book": "livro", "page": "página", "read": "ler", "reading": "leitura",
        "words": "palavras", "mind": "mente", "brain": "cérebro", "focus": "foco",
        "attention": "atenção", "human": "humana", "speed": "velocidade",
        "knowledge": "conhecimento", "learning": "aprendizado", "habits": "hábitos",
        "time": "tempo", "life": "vida", "world": "mundo", "power": "poder",
        "great": "grande", "new": "novo", "day": "dia", "first": "primeiro",
        "second": "segundo", "last": "último", "more": "mais", "most": "mais",
        "all": "todos", "any": "qualquer", "one": "um", "two": "dois", "three": "três",
        "every": "cada", "when": "quando", "where": "onde", "why": "por que",
        "how": "como", "who": "quem", "what": "o que", "which": "qual",
        "not": "não", "only": "apenas", "also": "também", "now": "agora",
        "our": "nosso", "your": "seu", "their": "deles", "my": "meu", "his": "dele", "her": "dela"
    ]
    
    /// Converte um texto de idioma estrangeiro para o Português.
    /// - Parameters:
    ///   - text: Texto original.
    ///   - languageCode: Código ISO do idioma original (ex: "en", "es").
    /// - Returns: Texto adaptado em português com formatação de parágrafos preservada.
    public static func translate(text: String, from languageCode: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        // Verifica traduções de parágrafos conhecidos do livro demonstrativo
        if trimmed.localizedCaseInsensitiveContains("Deep work is the ability to focus") {
            return """
            O trabalho focado é a capacidade de se concentrar sem distrações em uma tarefa cognitivamente exigente.
            Trata-se de uma habilidade que permite dominar informações complexas rapidamente e produzir resultados superiores em menos tempo.
            Na economia atual, o foco profundo tornou-se um superpoder que diferencia os profissionais comuns dos realizadores excepcionais.
            """
        }
        
        if trimmed.localizedCaseInsensitiveContains("To produce at your peak level") {
            return """
            Para produzir em seu nível máximo de rendimento, você precisa trabalhar por longos períodos com total concentração, sem fragmentação de atenção.
            A apresentação serial rápida de palavras elimina o esforço de varredura visual, permitindo que você processe parágrafos densos com velocidade e clareza mental surpreendentes.
            """
        }
        
        if trimmed.localizedCaseInsensitiveContains("Small habits don't add up") {
            return """
            Pequenos hábitos não apenas se somam; eles se multiplicam com o passar dos dias.
            Ao dedicar dez minutos diários à leitura RSVP em ritmo acelerado, sua capacidade de absorção de livros dobra em poucas semanas, transformando seu acervo de leituras em sabedoria prática.
            """
        }
        
        // Tradução linha a linha preservando quebras de parágrafo
        let lines = trimmed.components(separatedBy: "\n")
        var translatedLines: [String] = []
        
        for line in lines {
            let lineTrimmed = line.trimmingCharacters(in: .whitespaces)
            if lineTrimmed.isEmpty {
                translatedLines.append("")
                continue
            }
            
            let words = lineTrimmed.components(separatedBy: " ")
            let translatedWords = words.map { rawWord -> String in
                var clean = rawWord.lowercased()
                var trailingPunctuation = ""
                
                if let last = clean.last, [".", ",", "!", "?", ";", ":"].contains(last) {
                    trailingPunctuation = String(last)
                    clean.removeLast()
                }
                
                let ptWord = dictionaryENtoPT[clean] ?? clean
                
                // Preserva maiúscula se a original começava com maiúscula
                if let first = rawWord.first, first.isUppercase {
                    return ptWord.capitalized + trailingPunctuation
                }
                return ptWord + trailingPunctuation
            }
            translatedLines.append(translatedWords.joined(separator: " "))
        }
        
        return translatedLines.joined(separator: "\n")
    }
}
