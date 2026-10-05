//
//  OneWordAppRunner.swift
//  OneWordApp (macOS Native Runner & Local Server)
//

import SwiftUI
import SwiftData
import OneWord

@main
struct OneWordAppRunner: App {
    @State private var deepLinkDocument: OneWord.Document?
    
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            OneWord.Document.self,
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
            
            // Seed inicial de Livro se estiver vazio
            let bookCount = (try? context.fetchCount(FetchDescriptor<Book>())) ?? 0
            if bookCount == 0 {
                let book1 = Book(
                    title: "A Revolução do Foco",
                    author: "Cal Newport & OneWord Labs",
                    coverThemeColor: "#1E40AF"
                )
                let p1Text = "A atenção humana é o ativo mais escasso da modernidade. Quando lemos sem distrações, nosso cérebro alcança o estado de fluxo."
                book1.addPage(rawText: p1Text, words: p1Text.components(separatedBy: .whitespacesAndNewlines))
                context.insert(book1)
                try? context.save()
            }
            return container
        } catch {
            fatalError("Erro ao criar ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup("OneWord - Leitor RSVP") {
            MainTabView()
                .sheet(item: $deepLinkDocument) { document in
                    RSVPReaderView(document: document, modelContext: sharedModelContainer.mainContext)
                }
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
                            print("[OneWord DeepLink] Erro: \(error)")
                        }
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
