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
                ReadingSession.self,
                Book.self,
                BookPage.self
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
            
            // Livro com múltiplas páginas mockadas
            let sampleBook = Book(
                title: "O Guia da Superleitura",
                author: "Jim Kwik & RSVP Labs",
                coverThemeColor: "#2563EB"
            )
            sampleBook.addPage(
                rawText: "Capítulo 1: O cérebro humano processa imagens e conceitos em milissegundos. Quando treinamos nossa atenção visual, a velocidade de apreensão ultrapassa qualquer barreira tradicional.",
                words: ["Capítulo", "1:", "O", "cérebro", "humano", "processa", "imagens", "e", "conceitos", "em", "milissegundos.", "Quando", "treinamos", "nossa", "atenção", "visual,", "a", "velocidade", "de", "apreensão", "ultrapassa", "qualquer", "barreira", "tradicional."]
            )
            sampleBook.addPage(
                rawText: "Capítulo 2: Eliminar a subvocalização é o segredo para saltar de duzentas para seiscentas palavras por minuto com total nitidez e foco inabalável.",
                words: ["Capítulo", "2:", "Eliminar", "a", "subvocalização", "é", "o", "segredo", "para", "saltar", "de", "duzentas", "para", "seiscentas", "palavras", "por", "minuto", "com", "total", "nitidez", "e", "foco", "inabalável."]
            )
            container.mainContext.insert(sampleBook)
            
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
