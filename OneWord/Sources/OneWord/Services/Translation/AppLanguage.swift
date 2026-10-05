//
//  AppLanguage.swift
//  OneWord
//
//  Idioma do app (português, inglês ou espanhol), que segue o idioma do sistema
//  com inglês como fallback. É também o idioma-alvo da tradução de livros e artigos.
//

import Foundation

public enum AppLanguage {
    /// "pt", "en" ou "es".
    public static var code: String {
        let preferred = Bundle.main.preferredLocalizations.first ?? "en"
        if preferred.hasPrefix("pt") { return "pt" }
        if preferred.hasPrefix("es") { return "es" }
        return "en"
    }
    
    /// Nome do idioma escrito no próprio idioma.
    public static var name: String {
        switch code {
        case "pt": return "Português"
        case "es": return "Español"
        default: return "English"
        }
    }
    
    public static var flag: String {
        switch code {
        case "pt": return "🇧🇷"
        case "es": return "🇪🇸"
        default: return "🇺🇸"
        }
    }
    
    /// Idioma-alvo para o framework Translation da Apple.
    public static var translationTarget: Locale.Language {
        Locale.Language(identifier: code == "pt" ? "pt-BR" : code)
    }
}
