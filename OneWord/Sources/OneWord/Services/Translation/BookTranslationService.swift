//
//  BookTranslationService.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import NaturalLanguage

/// Informações sobre o idioma detectado no texto de um livro ou documento.
public struct DetectedLanguageInfo: Sendable, Equatable {
    public let code: String
    public let name: String
    public let flag: String
    public let isPortuguese: Bool
    
    public init(code: String, name: String, flag: String, isPortuguese: Bool) {
        self.code = code
        self.name = name
        self.flag = flag
        self.isPortuguese = isPortuguese
    }
}

/// Serviço responsável pela detecção de idiomas via NaturalLanguage framework
/// e formatação de metadados para tradução de páginas e livros estrangeiros.
public final class BookTranslationService: Sendable {
    
    public init() {}
    
    /// Detecta o idioma dominante de uma amostra de texto usando o NaturalLanguage da Apple (100% offline).
    /// - Parameter text: Texto textual a ser analisado.
    /// - Returns: Código ISO do idioma (ex: "en", "es", "fr", "pt") ou nil se indeterminado.
    public func detectLanguage(for text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        return recognizer.dominantLanguage?.rawValue
    }
    
    /// Retorna informações estruturadas (nome amigável em português e bandeira emoji) para um código de idioma.
    /// - Parameter code: Código ISO do idioma (ex: "en", "es", "fr", "de", "it", "pt").
    public static func languageInfo(for code: String?) -> DetectedLanguageInfo {
        guard let code = code?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines), !code.isEmpty else {
            return DetectedLanguageInfo(code: "pt", name: "Português", flag: "🇧🇷", isPortuguese: true)
        }
        
        // Verifica se é variante de português
        if code.hasPrefix("pt") {
            return DetectedLanguageInfo(code: "pt", name: "Português", flag: "🇧🇷", isPortuguese: true)
        }
        
        switch code {
        case "en":
            return DetectedLanguageInfo(code: "en", name: "Inglês", flag: "🇺🇸", isPortuguese: false)
        case "es":
            return DetectedLanguageInfo(code: "es", name: "Espanhol", flag: "🇪🇸", isPortuguese: false)
        case "fr":
            return DetectedLanguageInfo(code: "fr", name: "Francês", flag: "🇫🇷", isPortuguese: false)
        case "de":
            return DetectedLanguageInfo(code: "de", name: "Alemão", flag: "🇩🇪", isPortuguese: false)
        case "it":
            return DetectedLanguageInfo(code: "it", name: "Italiano", flag: "🇮🇹", isPortuguese: false)
        case "ja":
            return DetectedLanguageInfo(code: "ja", name: "Japonês", flag: "🇯🇵", isPortuguese: false)
        case "zh", "zh-hans", "zh-hant":
            return DetectedLanguageInfo(code: "zh", name: "Chinês", flag: "🇨🇳", isPortuguese: false)
        case "ru":
            return DetectedLanguageInfo(code: "ru", name: "Russo", flag: "🇷🇺", isPortuguese: false)
        default:
            let localizedName = Locale(identifier: "pt_BR").localizedString(forLanguageCode: code)?.capitalized ?? code.uppercased()
            return DetectedLanguageInfo(code: code, name: localizedName, flag: "🌐", isPortuguese: false)
        }
    }
}
