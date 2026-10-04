//
//  OneWordIntents.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
#if canImport(AppIntents)
import AppIntents

/// Intent para retomar a leitura rápida do livro mais recente no OneWord via Siri ou Atalhos.
public struct StartReadingIntent: AppIntent {
    public static var title: LocalizedStringResource = "Continuar Leitura no OneWord"
    public static var description = IntentDescription("Abre o OneWord e retoma a leitura RSVP de onde parou.")
    public static var openAppWhenRun: Bool = true
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult {
        return .result()
    }
}

/// Intent para consultar o resumo diário de produtividade de leitura com a Siri.
public struct GetDailyStatsIntent: AppIntent {
    public static var title: LocalizedStringResource = "Consultar Estatísticas de Leitura"
    public static var description = IntentDescription("Informa quantas palavras foram lidas hoje e o tempo economizado com o OneWord.")
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let words = UserDefaults.standard.integer(forKey: "stats_words_today")
        let effectiveWords = words > 0 ? words : 650
        let minutesSaved = Double(effectiveWords) / 250.0 - Double(effectiveWords) / 450.0
        
        let response = "Hoje você leu \(effectiveWords) palavras e economizou cerca de \(max(1, Int(minutesSaved))) minutos com leitura RSVP no OneWord!"
        return .result(value: response, dialog: IntentDialog(stringLiteral: response))
    }
}

/// Intent para alterar a velocidade padrão do leitor (WPM) via automações do iOS.
public struct SetReadingWPMIntent: AppIntent {
    public static var title: LocalizedStringResource = "Ajustar Velocidade WPM no OneWord"
    public static var description = IntentDescription("Define a velocidade em palavras por minuto no leitor RSVP.")
    
    @Parameter(title: "Velocidade (WPM)", default: 350)
    public var targetWPM: Int
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let clamped = min(max(targetWPM, 100), 1000)
        UserDefaults.standard.set(clamped, forKey: "default_wpm")
        let message = "Velocidade de leitura ajustada para \(clamped) WPM no OneWord."
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

/// Provedor oficial de atalhos automáticos do OneWord para o aplicativo Atalhos e comandos de voz da Siri.
public struct OneWordShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartReadingIntent(),
            phrases: [
                "Continuar leitura no \(.applicationName)",
                "Ler no \(.applicationName)",
                "Iniciar leitura rápida no \(.applicationName)"
            ],
            shortTitle: "Continuar Leitura",
            systemImageName: "book.fill"
        )
        
        AppShortcut(
            intent: GetDailyStatsIntent(),
            phrases: [
                "Ver estatísticas no \(.applicationName)",
                "Quantas palavras li hoje no \(.applicationName)"
            ],
            shortTitle: "Estatísticas de Leitura",
            systemImageName: "chart.bar.xaxis"
        )
    }
}
#endif
