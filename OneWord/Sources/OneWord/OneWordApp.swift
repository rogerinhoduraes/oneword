//
//  OneWordApp.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
import SwiftData

/// Ponto de entrada principal do aplicativo OneWord (iOS 17+).
/// Configura o contêiner de persistência nativo do SwiftData e injeta o contexto na hierarquia SwiftUI.
@main
public struct OneWordApp: App {
    
    /// Contêiner compartilhado de dados do SwiftData com esquema tipado.
    public let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Document.self,
            DocumentContent.self,
            ReadingProgress.self,
            ReadingSession.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Seed inicial para primeiro acesso
            let context = container.mainContext
            let count = (try? context.fetchCount(FetchDescriptor<Document>())) ?? 0
            if count == 0 {
                let parser = TextParser()
                
                let doc1Text = """
                A leitura dinâmica através do método RSVP projeta uma única palavra por vez no centro visual da tela.
                Ao eliminar a necessidade de movimentos sacádicos dos olhos e diminuir a vocalização interna, o leitor consegue absorver informações em velocidades muito superiores à média convencional, mantendo alto nível de retenção cognitiva e foco absoluto.
                Observe como as vírgulas desaceleram ligeiramente a exibição, e os pontos finais concedem pausas estratégicas para o cérebro assimilar a frase completa antes de prosseguir.
                """
                let (_, doc1Words) = parser.parse(rawText: doc1Text)
                let doc1 = Document(title: "Introdução ao Método RSVP", rawText: doc1Text, words: doc1Words)
                context.insert(doc1)
                
                let doc2Text = """
                O foco profundo é uma habilidade rara e valiosa no século vinte e um.
                Quando treinamos nossa percepção visual para absorver palavras sequenciais em fluxo ininterrupto, a mente silencia as distrações do ambiente.
                A cada sessão de treino, sua velocidade e conforto cognitivo se expandem de forma natural e consistente.
                """
                let (_, doc2Words) = parser.parse(rawText: doc2Text)
                let doc2 = Document(title: "A Arte do Foco e Concentração", rawText: doc2Text, words: doc2Words)
                context.insert(doc2)
                
                try? context.save()
            }
            
            // Seed de sessões de demonstração se não houver nenhuma
            let sessionCount = (try? context.fetchCount(FetchDescriptor<ReadingSession>())) ?? 0
            if sessionCount == 0 {
                let calendar = Calendar.current
                let now = Date()
                
                let s1 = ReadingSession(
                    date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                    durationSeconds: 120.0,
                    wordsRead: 850,
                    averageWPM: 425,
                    documentTitle: "Introdução ao Método RSVP"
                )
                let s2 = ReadingSession(
                    date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                    durationSeconds: 190.0,
                    wordsRead: 1420,
                    averageWPM: 450,
                    documentTitle: "A Arte do Foco e Concentração"
                )
                let s3 = ReadingSession(
                    date: now,
                    durationSeconds: 95.0,
                    wordsRead: 720,
                    averageWPM: 480,
                    documentTitle: "Introdução ao Método RSVP"
                )
                context.insert(s1)
                context.insert(s2)
                context.insert(s3)
                try? context.save()
            }
            
            return container
        } catch {
            fatalError("Não foi possível criar o ModelContainer do SwiftData: \(error.localizedDescription)")
        }
    }()

    public init() {}

    public var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
