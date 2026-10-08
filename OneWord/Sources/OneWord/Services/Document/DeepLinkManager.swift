//
//  DeepLinkManager.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS/macOS
//

import Foundation
import SwiftData

/// Gerenciador de Deep Links (URL Schemes `oneword://`) para integração com a Extensão do Chrome e outros navegadores.
///
/// Esquemas suportados:
/// - `oneword://read?text=<texto>&title=<titulo>&url=<url_origem>`: Abre e inicia a leitura imediata do texto fornecido.
/// - `oneword://open?url=<url_web>`: Baixa e extrai o artigo da web fornecido via `WebArticleExtractor` e inicia a leitura.
@MainActor
public final class DeepLinkManager: Sendable {
    public static let shared = DeepLinkManager()
    
    private init() {}
    
    /// Analisa e processa um URL de deep link recebido pelo aplicativo.
    /// - Parameters:
    ///   - url: URL com esquema `oneword://`
    ///   - context: Contexto do SwiftData para persistência do documento importado.
    /// - Returns: O `Document` criado e pronto para leitura, ou `nil` caso não seja uma requisição de leitura direta.
    public func handle(url: URL, context: ModelContext) async throws -> Document? {
        guard let scheme = url.scheme?.lowercased(), scheme == "oneword" else {
            return nil
        }
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        let action = (components.host ?? components.path).trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        let queryItems = components.queryItems ?? []
        
        func param(_ name: String) -> String? {
            queryItems.first(where: { $0.name.lowercased() == name.lowercased() })?.value
        }
        
        switch action {
        case "read":
            guard let rawText = param("text"), !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            
            let title = param("title")?.trimmingCharacters(in: .whitespacesAndNewlines)
            let finalTitle = (title?.isEmpty == false) ? title! : String(localized: "Artigo do Chrome")
            
            let parser = TextParser()
            let (cleanedText, words) = parser.parse(rawText: rawText)
            
            let document = Document(
                title: finalTitle,
                rawText: cleanedText,
                words: words
            )
            
            context.insert(document)
            try? context.save()
            return document
            
        case "open", "import":
            if let targetURLString = param("url"), let targetURL = URL(string: targetURLString) {
                let extractor = WebArticleExtractor()
                let extracted = try await extractor.extract(from: targetURL)
                
                let document = Document(
                    title: extracted.title,
                    rawText: extracted.textContent,
                    words: extracted.words
                )
                
                context.insert(document)
                try? context.save()
                return document
            } else if let rawText = param("text"), !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let title = param("title") ?? String(localized: "Artigo Web")
                let parser = TextParser()
                let (cleanedText, words) = parser.parse(rawText: rawText)
                
                let document = Document(
                    title: title,
                    rawText: cleanedText,
                    words: words
                )
                
                context.insert(document)
                try? context.save()
                return document
            }
            return nil
            
        default:
            return nil
        }
    }
}
