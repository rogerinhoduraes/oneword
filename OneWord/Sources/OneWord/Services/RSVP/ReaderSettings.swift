//
//  ReaderSettings.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI

/// Temas visuais de contraste e conforto de leitura para a tela RSVP.
public enum ReaderTheme: String, CaseIterable, Identifiable, Sendable {
    case system = "Sistema"
    case light = "Claro"
    case sepia = "Sépia"
    case dark = "Escuro"
    case oledBlack = "OLED Preto"
    case circadianRed = "Vermelho Noturno (OLED)"
    
    public var id: String { rawValue }
    
    /// Cor de fundo da tela conforme o tema.
    public var backgroundColor: Color {
        switch self {
        case .system:
            return Color(uiColorOrFallback: .systemBackground)
        case .light:
            return Color.white
        case .sepia:
            return Color(red: 0.98, green: 0.95, blue: 0.88)
        case .dark:
            return Color(red: 0.12, green: 0.12, blue: 0.13)
        case .oledBlack, .circadianRed:
            return Color.black
        }
    }
    
    /// Cor principal do texto para o tema selecionado.
    public var textColor: Color {
        switch self {
        case .system:
            return Color.primary
        case .light:
            return Color.black
        case .sepia:
            return Color(red: 0.28, green: 0.20, blue: 0.12)
        case .dark, .oledBlack:
            return Color(white: 0.92)
        case .circadianRed:
            return Color(red: 0.95, green: 0.18, blue: 0.18) // Vermelho profundo anti-fadiga circadiana
        }
    }
}

/// Famílias tipográficas otimizadas para leitura RSVP.
public enum ReaderFont: String, CaseIterable, Identifiable, Sendable {
    case rounded = "Arredondada"
    case serif = "Serifada (Livro)"
    case monospaced = "Monoespaçada"
    case system = "Sistema Padrão"
    
    public var id: String { rawValue }
    
    /// Aplica a fonte estilizada ao texto SwiftUI com o tamanho selecionado.
    public func font(size: CGFloat) -> Font {
        switch self {
        case .rounded:
            return .system(size: size, weight: .bold, design: .rounded)
        case .serif:
            return .system(size: size, weight: .bold, design: .serif)
        case .monospaced:
            return .system(size: size, weight: .bold, design: .monospaced)
        case .system:
            return .system(size: size, weight: .bold, design: .default)
        }
    }
}

/// Configuração personalizada de leitura do usuário, persistida em AppStorage / UserDefaults.
public struct ReaderSettings: Sendable, Equatable {
    public var theme: ReaderTheme = .system
    public var font: ReaderFont = .rounded
    public var fontSize: CGFloat = 46.0
    public var showORPNotch: Bool = true
    public var smartWPMEnabled: Bool = true
    public var chunkSize: Int = 1
    public var bimodalAudioEnabled: Bool = false
    
    public init(
        theme: ReaderTheme = .system,
        font: ReaderFont = .rounded,
        fontSize: CGFloat = 46.0,
        showORPNotch: Bool = true,
        smartWPMEnabled: Bool = true,
        chunkSize: Int = 1,
        bimodalAudioEnabled: Bool = false
    ) {
        self.theme = theme
        self.font = font
        self.fontSize = fontSize
        self.showORPNotch = showORPNotch
        self.smartWPMEnabled = smartWPMEnabled
        self.chunkSize = min(max(chunkSize, 1), 3)
        self.bimodalAudioEnabled = bimodalAudioEnabled
    }
}

// MARK: - Persistência

extension ReaderSettings {
    private enum Key {
        static let theme = "reader.theme"
        static let font = "reader.font"
        static let fontSize = "reader.fontSize"
        static let showORPNotch = "reader.showORPNotch"
        static let smartWPM = "reader.smartWPM"
        static let chunkSize = "reader.chunkSize"
        static let bimodalAudio = "reader.bimodalAudio"
    }
    
    /// Carrega as preferências salvas; chaves ausentes mantêm o valor padrão.
    public static func load(from defaults: UserDefaults = .standard) -> ReaderSettings {
        var settings = ReaderSettings()
        if let raw = defaults.string(forKey: Key.theme), let theme = ReaderTheme(rawValue: raw) { settings.theme = theme }
        if let raw = defaults.string(forKey: Key.font), let font = ReaderFont(rawValue: raw) { settings.font = font }
        if defaults.object(forKey: Key.fontSize) != nil { settings.fontSize = CGFloat(defaults.double(forKey: Key.fontSize)) }
        if defaults.object(forKey: Key.showORPNotch) != nil { settings.showORPNotch = defaults.bool(forKey: Key.showORPNotch) }
        if defaults.object(forKey: Key.smartWPM) != nil { settings.smartWPMEnabled = defaults.bool(forKey: Key.smartWPM) }
        if defaults.object(forKey: Key.chunkSize) != nil { settings.chunkSize = min(max(defaults.integer(forKey: Key.chunkSize), 1), 3) }
        if defaults.object(forKey: Key.bimodalAudio) != nil { settings.bimodalAudioEnabled = defaults.bool(forKey: Key.bimodalAudio) }
        return settings
    }
    
    public func save(to defaults: UserDefaults = .standard) {
        defaults.set(theme.rawValue, forKey: Key.theme)
        defaults.set(font.rawValue, forKey: Key.font)
        defaults.set(Double(fontSize), forKey: Key.fontSize)
        defaults.set(showORPNotch, forKey: Key.showORPNotch)
        defaults.set(smartWPMEnabled, forKey: Key.smartWPM)
        defaults.set(chunkSize, forKey: Key.chunkSize)
        defaults.set(bimodalAudioEnabled, forKey: Key.bimodalAudio)
    }
}

/// Preferências globais simples do app.
public enum AppSettings {
    public static let defaultWPMKey = "default_wpm"
    public static let wpmRange = 100...1000
    
    /// Velocidade inicial do leitor (WPM), salva pelo benchmark, pelos Atalhos e pela aba Ajustes.
    public static var defaultWPM: Int {
        let stored = UserDefaults.standard.integer(forKey: defaultWPMKey)
        return stored > 0 ? min(max(stored, wpmRange.lowerBound), wpmRange.upperBound) : 300
    }
}

private extension Color {
    init(uiColorOrFallback: UIColorType) {
        #if canImport(UIKit)
        switch uiColorOrFallback {
        case .systemBackground:
            self.init(uiColor: .systemBackground)
        }
        #else
        self.init(.windowBackgroundColor)
        #endif
    }
    
    enum UIColorType {
        case systemBackground
    }
}
