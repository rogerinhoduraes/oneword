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
        case .oledBlack:
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
    
    public init(
        theme: ReaderTheme = .system,
        font: ReaderFont = .rounded,
        fontSize: CGFloat = 46.0,
        showORPNotch: Bool = true
    ) {
        self.theme = theme
        self.font = font
        self.fontSize = fontSize
        self.showORPNotch = showORPNotch
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
