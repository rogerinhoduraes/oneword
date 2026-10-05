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
                ReadingSession.self,
                Book.self,
                BookPage.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                let context = container.mainContext
                
                // Seed de Livro inicial se a estante estiver vazia
                let bookCount = (try? context.fetchCount(FetchDescriptor<Book>())) ?? 0
                if bookCount == 0 {
                    let book1 = Book(
                        title: "A Revolução do Foco",
                        author: "Cal Newport & OneWord Labs",
                        coverThemeColor: "#1E40AF"
                    )
                    
                    let p1Text = """
                    A atenção humana é o ativo mais escasso da modernidade. Quando lemos sem distrações, nosso cérebro alcança o estado de fluxo.
                    Ao projetar uma única palavra por vez no campo foveal central, a técnica RSVP silencia os impulsos de divagação mental e maximiza a velocidade de apreensão de cada parágrafo com precisão cirúrgica.
                    """
                    let p1Words = p1Text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                    book1.addPage(rawText: p1Text, words: p1Words)
                    
                    let p2Text = """
                    No segundo estágio do treino, a velocidade de quatrocentas palavras por minuto torna-se confortável e intuitiva.
                    Pausas dinâmicas ao final de cada frase concedem ao córtex pré-frontal o tempo exato para sintetizar o significado global da mensagem sem interrupção sacádica.
                    """
                    let p2Words = p2Text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                    book1.addPage(rawText: p2Text, words: p2Words)
                    
                    let p3Text = """
                    A biblioteca do OneWord permite organizar páginas escaneadas sequencialmente em cada livro físico.
                    Você pode pausar a qualquer momento e retomar de onde parou, ou avançar diretamente para qualquer capítulo através do índice de páginas.
                    """
                    let p3Words = p3Text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                    book1.addPage(rawText: p3Text, words: p3Words)
                    
                    context.insert(book1)
                    try? context.save()
                }
                
                // Seed de Livro Internacional em Inglês para testar a tradução para Português
                let currentBooks = (try? context.fetch(FetchDescriptor<Book>())) ?? []
                if !currentBooks.contains(where: { $0.title == "Deep Work" }) {
                    let bookEN = Book(
                        title: "Deep Work",
                        author: "Cal Newport",
                        coverThemeColor: "#7C3AED",
                        detectedLanguageCode: "en"
                    )
                    
                    let p1Text = """
                    Deep work is the ability to focus without distraction on a cognitively demanding task. It's a skill that allows you to quickly master complicated information and produce better results in less time. In today's economy, deep focus has become a superpower.
                    """
                    let p1Words = p1Text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                    bookEN.addPage(rawText: p1Text, words: p1Words)
                    
                    let p2Text = """
                    To produce at your peak level you need to work for extended periods with full concentration on a single task free from all distraction. The RSVP technique allows you to absorb complex paragraphs with maximum speed and clarity.
                    """
                    let p2Words = p2Text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                    bookEN.addPage(rawText: p2Text, words: p2Words)
                    
                    let p3Text = """
                    Small habits don't add up; they multiply over time. By dedicating ten minutes daily to rapid reading, your book absorption rate doubles in just a few weeks.
                    """
                    let p3Words = p3Text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                    bookEN.addPage(rawText: p3Text, words: p3Words)
                    
                    context.insert(bookEN)
                    try? context.save()
                }
                
                // Seed de Documentos avulsos
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
                
                // Seed de Artigo Internacional em Inglês para testar tradução de artigos
                let currentDocs = (try? context.fetch(FetchDescriptor<Document>())) ?? []
                if !currentDocs.contains(where: { $0.title == "How to Do Great Work" }) {
                    let parser = TextParser()
                    let docENText = """
                    If you want to do great work, the most important thing is to choose a problem you have a natural aptitude for and a deep interest in.
                    There is an immense amount of ambition in the world, but focused effort directed toward meaningful problems is exceptionally rare.
                    By cultivating consistent habits and eliminating peripheral noise, your ability to create lasting value expands exponentially.
                    """
                    let (_, docENWords) = parser.parse(rawText: docENText)
                    let docEN = Document(
                        title: "How to Do Great Work",
                        rawText: docENText,
                        words: docENWords,
                        originalLanguage: "en"
                    )
                    context.insert(docEN)
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
                        documentTitle: "A Revolução do Foco"
                    )
                    let s2 = ReadingSession(
                        date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                        durationSeconds: 190.0,
                        wordsRead: 1420,
                        averageWPM: 450,
                        documentTitle: "A Revolução do Foco"
                    )
                    let s3 = ReadingSession(
                        date: now,
                        durationSeconds: 95.0,
                        wordsRead: 720,
                        averageWPM: 480,
                        documentTitle: "A Revolução do Foco"
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

    @State private var deepLinkDocument: Document?
    
    public init() {}

    public var body: some Scene {
        WindowGroup {
            MainTabView()
                #if os(iOS)
                .fullScreenCover(item: $deepLinkDocument) { document in
                    RSVPReaderView(document: document, modelContext: sharedModelContainer.mainContext)
                }
                #else
                .sheet(item: $deepLinkDocument) { document in
                    RSVPReaderView(document: document, modelContext: sharedModelContainer.mainContext)
                }
                #endif
                .onAppear {
                    OneWordLocalServer.shared.onDocumentReceived = { document in
                        self.deepLinkDocument = document
                    }
                    OneWordLocalServer.shared.start(context: sharedModelContainer.mainContext)
                }
                .onOpenURL { url in
                    Task { @MainActor in
                        do {
                            if let document = try await DeepLinkManager.shared.handle(url: url, context: sharedModelContainer.mainContext) {
                                self.deepLinkDocument = document
                            }
                        } catch {
                            print("[OneWord DeepLink] Erro ao processar URL \(url): \(error.localizedDescription)")
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
