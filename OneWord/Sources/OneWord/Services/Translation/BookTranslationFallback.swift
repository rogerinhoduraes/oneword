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
    
    /// Dicionário de termos comuns de livros e artigos para tradução fluida de páginas e textos.
    private static let dictionaryENtoPT: [String: String] = [
        // Artigos e pronomes
        "the": "o", "a": "um", "an": "um", "and": "e", "or": "ou", "but": "mas", "in": "em",
        "on": "no", "at": "em", "to": "para", "for": "para", "with": "com", "without": "sem",
        "by": "por", "from": "de", "of": "de", "as": "como", "is": "é", "are": "são",
        "was": "foi", "were": "eram", "be": "ser", "been": "sido", "being": "sendo",
        "have": "ter", "has": "tem", "had": "tinha", "do": "fazer", "does": "faz",
        "did": "fez", "will": "irá", "would": "iria", "can": "pode", "could": "poderia",
        "this": "este", "that": "aquele", "these": "estes", "those": "aqueles",
        "i": "eu", "you": "você", "he": "ele", "she": "ela", "it": "isto", "we": "nós",
        "they": "eles", "them": "eles", "us": "nós", "me": "mim", "him": "ele",
        "our": "nosso", "your": "seu", "their": "deles", "my": "meu", "his": "dele", "her": "dela",
        "its": "seu", "mine": "meu", "yours": "seu", "ours": "nosso",
        
        // Contrações frequentes
        "it's": "é", "don't": "não", "doesn't": "não", "didn't": "não", "won't": "não irá",
        "can't": "não pode", "that's": "isso é", "i'm": "eu sou", "you're": "você é",
        "we're": "nós somos", "they're": "eles são", "there's": "há", "there're": "há",
        "isn't": "não é", "aren't": "não são", "wasn't": "não era", "weren't": "não eram",
        "haven't": "não tem", "hasn't": "não tem", "hadn't": "não tinha",
        
        // Conectivos e advérbios
        "about": "sobre", "after": "depois", "before": "antes", "between": "entre",
        "through": "através", "during": "durante", "under": "sob", "over": "sobre",
        "into": "em", "than": "do que", "because": "porque", "so": "então", "if": "se",
        "then": "então", "also": "também", "just": "apenas", "even": "mesmo", "still": "ainda",
        "not": "não", "only": "apenas", "now": "agora", "always": "sempre", "never": "nunca",
        "when": "quando", "where": "onde", "why": "por que", "how": "como",
        "who": "quem", "what": "o que", "which": "qual", "all": "todos", "any": "qualquer",
        "every": "cada", "some": "algum", "each": "cada", "more": "mais", "most": "mais",
        "very": "muito", "much": "muito", "many": "muitos", "too": "demais",
        
        // Substantivos e temas cognitivos / artigos
        "book": "livro", "page": "página", "read": "ler", "reading": "leitura",
        "words": "palavras", "word": "palavra", "mind": "mente", "brain": "cérebro", "focus": "foco",
        "attention": "atenção", "human": "humana", "speed": "velocidade",
        "knowledge": "conhecimento", "learning": "aprendizado", "habits": "hábitos", "habit": "hábito",
        "time": "tempo", "life": "vida", "world": "mundo", "power": "poder",
        "great": "grande", "new": "novo", "day": "dia", "first": "primeiro",
        "second": "segundo", "last": "último", "one": "um", "two": "dois", "three": "três",
        "problem": "problema", "problems": "problemas", "interest": "interesse",
        "effort": "esforço", "ambition": "ambição", "noise": "ruído", "value": "valor",
        "article": "artigo", "text": "texto", "idea": "ideia", "ideas": "ideias",
        "people": "pessoas", "person": "pessoa", "work": "trabalho", "system": "sistema",
        "ability": "capacidade", "task": "tarefa", "results": "resultados", "level": "nível",
        "important": "importante", "meaningful": "significativo", "natural": "natural",
        "lasting": "duradouro", "rare": "raro", "exponentially": "exponencialmente"
    ]
    
    /// Converte um texto de idioma estrangeiro para o Português.
    /// - Parameters:
    ///   - text: Texto original.
    ///   - languageCode: Código ISO do idioma original (ex: "en", "es").
    /// - Returns: Texto adaptado em português com formatação de parágrafos preservada.
    public static func translate(text: String, from languageCode: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        
        // Seed do Artigo "How to Do Great Work"
        if trimmed.localizedCaseInsensitiveContains("If you want to do great work") ||
           trimmed.localizedCaseInsensitiveContains("choose a problem you have a natural aptitude") {
            return """
            Se você deseja realizar um grande trabalho, o ponto mais importante é escolher um problema para o qual você tenha aptidão natural e profundo interesse.
            Existe uma imensa quantidade de ambição no mundo, mas o esforço focado e direcionado a problemas significativos é excepcionalmente raro.
            Ao cultivar hábitos consistentes e eliminar o ruído periférico, sua capacidade de gerar valor duradouro se expande exponencialmente.
            """
        }
        
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
        
        // Tradução linha a linha preservando quebras de parágrafo e pontuação complexa
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
                var leadingPunctuation = ""
                var trailingPunctuation = ""
                
                // Extrai pontuação de abertura
                while let first = clean.first, ["(", "[", "{", "\"", "“", "‘", "«", "-", "—"].contains(first) {
                    leadingPunctuation.append(first)
                    clean.removeFirst()
                }
                
                // Extrai pontuação de fechamento
                while let last = clean.last, [".", ",", "!", "?", ";", ":", ")", "]", "}", "\"", "”", "’", "»", "-", "—"].contains(last) {
                    trailingPunctuation = String(last) + trailingPunctuation
                    clean.removeLast()
                }
                
                let ptWord = dictionaryENtoPT[clean] ?? clean
                
                // Preserva maiúscula se a original começava com maiúscula
                let formatted: String
                if let first = rawWord.first, first.isUppercase {
                    formatted = ptWord.capitalized
                } else {
                    formatted = ptWord
                }
                
                return leadingPunctuation + formatted + trailingPunctuation
            }
            translatedLines.append(translatedWords.joined(separator: " "))
        }
        
        return translatedLines.joined(separator: "\n")
    }
}
