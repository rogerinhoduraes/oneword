//
//  ModelContainer+Preview.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftData

@MainActor
public extension ModelContainer {
    /// Contêiner de dados em memória para Previews no SwiftUI e testes automatizados.
    static var previewContainer: ModelContainer = {
        do {
            let schema = Schema([
                Document.self,
                DocumentContent.self,
                ReadingProgress.self,
                ReadingSession.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            
            // Popula com dados mockados para testes e preview da UI
            let sampleText = """
            A leitura dinâmica através do método RSVP projeta uma única palavra por vez no centro visual da tela.
            Ao eliminar a necessidade de movimentos sacádicos dos olhos e diminuir a vocalização interna, o leitor consegue absorver informações em velocidades muito superiores à média convencional, mantendo alto nível de retenção cognitiva e foco absoluto.
            """
            
            let sampleWords = sampleText
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            
            let sampleDoc = Document(
                title: "Introdução ao Método RSVP",
                rawText: sampleText,
                words: sampleWords,
                initialWordIndex: 0
            )
            
            container.mainContext.insert(sampleDoc)
            try container.mainContext.save()
            
            return container
        } catch {
            fatalError("Falha ao inicializar o ModelContainer de Preview: \(error.localizedDescription)")
        }
    }()
    
    /// Alias conveniente para SwiftUI Previews
    static var preview: ModelContainer {
        previewContainer
    }
}
