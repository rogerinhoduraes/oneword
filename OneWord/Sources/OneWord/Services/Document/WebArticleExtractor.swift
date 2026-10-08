//
//  WebArticleExtractor.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftData

/// Artigo ou conteúdo da web extraído e higienizado para leitura RSVP.
public struct ExtractedArticle: Sendable {
    public let title: String
    public let author: String?
    public let sourceURL: URL?
    public let textContent: String
    public let words: [String]
    
    public var wordCount: Int { words.count }
    
    public func estimatedMinutes(at wpm: Int = 300) -> Double {
        guard wpm > 0 else { return 0 }
        return Double(wordCount) / Double(wpm)
    }
}

/// Serviço de extração e higienização de artigos da web e textos de clipboard para o leitor RSVP.
/// Remove anúncios, scripts, cabeçalhos, rodapés e navegações, retendo apenas o núcleo textual foveal.
public final class WebArticleExtractor: Sendable {
    
    public init() {}
    
    /// Baixa e extrai o artigo a partir de uma URL web.
    public func extract(from url: URL) async throws -> ExtractedArticle {
        guard let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            throw WebExtractorError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw WebExtractorError.httpError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        let htmlString = decodeHTML(data, response: response)
        let article = extract(fromHTML: htmlString, sourceURL: url)
        guard !article.words.isEmpty else {
            throw WebExtractorError.emptyContent
        }
        return article
    }
    
    /// Decodifica o corpo respeitando o charset do servidor; sem charset, tenta UTF-8 e cai para Windows-1252.
    private func decodeHTML(_ data: Data, response: URLResponse) -> String {
        if let name = response.textEncodingName {
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(name as CFString)
            if cfEncoding != kCFStringEncodingInvalidId {
                let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
                if let decoded = String(data: data, encoding: encoding) { return decoded }
            }
        }
        return String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .windowsCP1252)
            ?? String(decoding: data, as: UTF8.self)
    }
    
    /// Analisa uma string HTML ou texto bruto diretamente (ex: colado pelo usuário).
    public func extract(fromHTML html: String, sourceURL: URL? = nil, fallbackTitle: String = String(localized: "Artigo da Web")) -> ExtractedArticle {
        // Se a string não contiver tags HTML evidentes, trata como texto puro
        if !html.contains("<") || !html.contains(">") {
            let (clean, words) = TextParser().parse(rawText: html)
            return ExtractedArticle(
                title: fallbackTitle,
                author: nil,
                sourceURL: sourceURL,
                textContent: clean,
                words: words
            )
        }
        
        // Extrai Título
        let title = extractTitle(fromHTML: html) ?? fallbackTitle
        
        // Extrai Autor
        let author = extractAuthor(fromHTML: html)
        
        // Remove elementos não textuais
        var cleanedHTML = html
        let tagsToRemove = [
            "<script[\\s\\S]*?</script>",
            "<style[\\s\\S]*?</style>",
            "<noscript[\\s\\S]*?</noscript>",
            "<svg[\\s\\S]*?</svg>",
            "<form[\\s\\S]*?</form>",
            "<!--[\\s\\S]*?-->"
        ]
        for pattern in tagsToRemove {
            cleanedHTML = cleanedHTML.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }
        
        // Foca no conteúdo principal (<article> ou <main>); o <header> interno é mantido (título/lide).
        // Sem container principal, <header> da página também é descartado.
        let mainBody = extractMainArticleBody(fromHTML: cleanedHTML)
        var articleBody = mainBody ?? cleanedHTML
        var chromePatterns = [
            "<footer[\\s\\S]*?</footer>",
            "<nav[\\s\\S]*?</nav>",
            "<aside[\\s\\S]*?</aside>"
        ]
        if mainBody == nil { chromePatterns.append("<header[\\s\\S]*?</header>") }
        for pattern in chromePatterns {
            articleBody = articleBody.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }
        
        // Converte quebras de bloco em quebras de parágrafo
        var processed = articleBody.replacingOccurrences(of: "</?(p|div|h[1-6]|li|tr|br)[^>]*>", with: "\n", options: .regularExpression)
        
        // Remove quaisquer tags HTML remanescentes
        processed = processed.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        
        // Decodifica entidades
        let decoded = EPUBParser().decodeHTMLEntities(processed)
        
        // Limpa e normaliza linhas
        let lines = decoded.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count >= 2 }
        
        let (textContent, words) = TextParser().parse(rawText: lines.joined(separator: "\n\n"))
        
        return ExtractedArticle(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author?.trimmingCharacters(in: .whitespacesAndNewlines),
            sourceURL: sourceURL,
            textContent: textContent,
            words: words
        )
    }
    
    /// Converte um artigo extraído em uma entidade `Document` do SwiftData.
    @MainActor
    public func saveAsDocument(article: ExtractedArticle, context: ModelContext) throws -> Document {
        let doc = Document(
            title: article.title,
            rawText: article.textContent,
            words: article.words
        )
        context.insert(doc)
        try context.save()
        return doc
    }
    
    // MARK: - Auxiliares Privados
    
    private func extractTitle(fromHTML html: String) -> String? {
        if let ogTitle = extractMetaTag(property: "og:title", from: html) { return ogTitle }
        if let twitterTitle = extractMetaTag(name: "twitter:title", from: html) { return twitterTitle }
        if let titleTag = extractRegex(pattern: "<title[^>]*>([^<]+)</title>", from: html) { return titleTag }
        if let h1Tag = extractRegex(pattern: "<h1[^>]*>([^<]+)</h1>", from: html) { return h1Tag }
        return nil
    }
    
    private func extractAuthor(fromHTML html: String) -> String? {
        if let authorMeta = extractMetaTag(name: "author", from: html) { return authorMeta }
        if let ogAuthor = extractMetaTag(property: "article:author", from: html) { return ogAuthor }
        return nil
    }
    
    private func extractMainArticleBody(fromHTML html: String) -> String? {
        // Tenta encontrar <article>...</article>
        if let articleMatch = extractRegex(pattern: "<article[^>]*>([\\s\\S]*?)</article>", from: html) {
            return articleMatch
        }
        // Tenta encontrar <main>...</main>
        if let mainMatch = extractRegex(pattern: "<main[^>]*>([\\s\\S]*?)</main>", from: html) {
            return mainMatch
        }
        return nil
    }
    
    private func extractMetaTag(name: String? = nil, property: String? = nil, from html: String) -> String? {
        let attr = name != nil ? "name=\"\(name!)\"" : "property=\"\(property!)\""
        let pattern1 = "<meta\\s+[^>]*\(attr)[^>]*content=\"([^\"]+)\""
        if let val = extractRegex(pattern: pattern1, from: html) { return val }
        let pattern2 = "<meta\\s+[^>]*content=\"([^\"]+)\"[^>]*\(attr)"
        if let val = extractRegex(pattern: pattern2, from: html) { return val }
        return nil
    }
    
    private func extractRegex(pattern: String, from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              match.numberOfRanges > 1 else {
            return nil
        }
        return ns.substring(with: match.range(at: 1))
    }
}

public enum WebExtractorError: LocalizedError, Sendable {
    case invalidURL
    case httpError(Int)
    case emptyContent
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "A URL fornecida é inválida.")
        case .httpError(let code):
            return String(localized: "Erro HTTP \(code) ao baixar o artigo.")
        case .emptyContent:
            return String(localized: "Nenhum texto legível foi encontrado nesta página.")
        }
    }
}
