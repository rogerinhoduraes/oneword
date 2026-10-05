//
//  LibraryView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Tela principal da Biblioteca do OneWord.
/// Oferece estante de Livros estilo Apple Books (com capas físicas escaneadas ou tipográficas,
/// múltiplas páginas e progresso contínuo) e seção de Artigos/Documentos Avulsos.
public struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.lastAccessedAt, order: .reverse) private var books: [Book]
    @Query(sort: \Document.lastAccessedAt, order: .reverse) private var documents: [Document]
    
    @State private var viewModel = LibraryViewModel()
    @State private var libraryTab: LibraryTab = .books
    @State private var isShowingAddBookSheet: Bool = false
    @State private var isShowingEPUBPicker: Bool = false
    @State private var isShowingQuickImportSheet: Bool = false
    @State private var isShowingFlashcardReview: Bool = false
    @State private var isShowingReadingGuide: Bool = false
    @State private var selectedBookForNavigation: Book?
    
    public enum LibraryTab: String, CaseIterable, Identifiable {
        case books = "Livros"
        case articles = "Artigos Avulsos"
        
        public var id: String { rawValue }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Seletor de Categoria (Livros vs Artigos)
                Picker("Biblioteca", selection: $libraryTab) {
                    ForEach(LibraryTab.allCases) { tab in
                        Text(LocalizedStringKey(tab.rawValue)).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 12)
                
                Group {
                    switch libraryTab {
                    case .books:
                        booksView
                    case .articles:
                        documentsView
                    }
                }
            }
            .navigationTitle("OneWord")
            .searchable(text: $viewModel.searchText, prompt: "Buscar na biblioteca...")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    toolbarLeadingItems
                }
                #else
                ToolbarItem(placement: .navigation) {
                    toolbarLeadingItems
                }
                #endif
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            isShowingAddBookSheet = true
                        } label: {
                            Label("Novo Livro Físico", systemImage: "book.badge.plus")
                        }
                        
                        Button {
                            isShowingEPUBPicker = true
                        } label: {
                            Label("Importar Livro ou PDF (.pdf / .epub / .txt)", systemImage: "arrow.down.doc.fill")
                        }
                        
                        Button {
                            isShowingQuickImportSheet = true
                        } label: {
                            Label("Importar Artigo Web ou Texto", systemImage: "link.badge.plus")
                        }
                        
                        Divider()
                        
                        Button {
                            viewModel.isShowingScannerSheet = true
                        } label: {
                            Label("Escanear Documento Avulso", systemImage: "camera.fill")
                        }
                        
                        Divider()
                        
                        Button {
                            isShowingReadingGuide = true
                        } label: {
                            Label("Guia: Técnicas & Recursos", systemImage: "brain.head.profile")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $isShowingFlashcardReview) {
                FlashcardReviewView()
            }
            .sheet(isPresented: $isShowingAddBookSheet) {
                AddBookSheetView { newBook in
                    self.selectedBookForNavigation = newBook
                }
            }
            .sheet(isPresented: $isShowingQuickImportSheet) {
                QuickImportSheetView { newDoc in
                    viewModel.selectedDocumentForReading = newDoc
                }
            }
            .sheet(isPresented: $viewModel.isShowingScannerSheet) {
                DocumentScannerView { newDoc in
                    viewModel.selectedDocumentForReading = newDoc
                }
            }
            .sheet(isPresented: $isShowingReadingGuide) {
                ReadingGuideView()
            }
            .fileImporter(
                isPresented: $isShowingEPUBPicker,
                allowedContentTypes: [.epub, .plainText, .pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    if url.pathExtension.lowercased() == "pdf" {
                        let isSecured = url.startAccessingSecurityScopedResource()
                        defer {
                            if isSecured { url.stopAccessingSecurityScopedResource() }
                        }
                        if let extracted = try? PDFImportService().extractText(from: url) {
                            let doc = Document(title: extracted.title, rawText: extracted.cleanedText, words: extracted.words)
                            modelContext.insert(doc)
                            try? modelContext.save()
                            libraryTab = .articles
                            viewModel.selectedDocumentForReading = doc
                        }
                    } else if let newBook = try? EPUBImportService().importFile(from: url, context: modelContext) {
                        self.selectedBookForNavigation = newBook
                    }
                case .failure:
                    break
                }
            }
            #if os(iOS)
            .fullScreenCover(item: $viewModel.selectedDocumentForReading) { document in
                RSVPReaderView(document: document, modelContext: modelContext)
            }
            #else
            .sheet(item: $viewModel.selectedDocumentForReading) { document in
                RSVPReaderView(document: document, modelContext: modelContext)
            }
            #endif
            .navigationDestination(item: $selectedBookForNavigation) { book in
                BookDetailView(book: book)
            }
        }
    }
    
    // MARK: - Barra de Ferramentas Superior
    
    private var toolbarLeadingItems: some View {
        HStack(spacing: 12) {
            
            let dueCount = FlashcardService.shared.dueFlashcards.count
            Button {
                isShowingFlashcardReview = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "rectangle.stack.badge.play")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    
                    if dueCount > 0 {
                        Text("\(dueCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(3)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 8, y: -6)
                    }
                }
            }
            .help("Revisão Espaçada de Flashcards")
            
            Button {
                isShowingReadingGuide = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            .help("Guia: Técnicas de Leitura & Recursos")
        }
    }
    
    // MARK: - Estante de Livros
    
    private var filteredBooks: [Book] {
        let trimmed = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return books }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.author.localizedCaseInsensitiveContains(trimmed)
        }
    }
    
    private var booksView: some View {
        Group {
            if books.isEmpty {
                emptyBooksStateView
            } else if filteredBooks.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)],
                        spacing: 24
                    ) {
                        ForEach(filteredBooks) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                bookGridCard(book)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    selectedBookForNavigation = book
                                } label: {
                                    Label("Abrir Livro", systemImage: "book")
                                }
                                
                                Button {
                                    book.resetProgress()
                                    try? modelContext.save()
                                } label: {
                                    Label("Reiniciar Leitura", systemImage: "arrow.counterclockwise")
                                }
                                
                                Button(role: .destructive) {
                                    modelContext.delete(book)
                                    try? modelContext.save()
                                } label: {
                                    Label("Excluir Livro", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
    }
    
    private func bookGridCard(_ book: Book) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Capa Estilizada com Lombada
            BookCoverView(
                title: book.title,
                author: book.author,
                coverImageData: book.coverImageData,
                themeColorHex: book.coverThemeColor,
                width: 155,
                height: 225
            )
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Barra de Progresso do Livro
            if book.totalWords > 0 {
                ProgressView(value: book.progressPercentage)
                    .tint(book.isCompleted ? .green : .blue)
                    .padding(.top, 2)
            }
            
            // Título e Autor
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                
                if !book.author.isEmpty {
                    Text(book.author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    Text("\(book.totalPages) \(book.totalPages == 1 ? String(localized: "pág.") : String(localized: "págs."))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if book.isForeignLanguage {
                        Text(book.hasTranslation ? "\(book.detectedLanguageInfo.flag) ➔ 🇧🇷" : book.detectedLanguageInfo.flag)
                            .font(.caption2)
                    }
                    
                    Spacer()
                    
                    if book.totalWords > 0 {
                        Text("\(Int(book.progressPercentage * 100))%")
                            .font(.caption2.bold())
                            .foregroundStyle(book.isCompleted ? .green : .blue)
                    }
                }
                .padding(.top, 2)
            }
        }
    }
    
    private var emptyBooksStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("Sua Estante está Vazia")
                    .font(.title2.bold())
                
                Text("Adicione livros físicos para escanear a capa e digitalizar suas páginas página a página para leitura RSVP.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                isShowingAddBookSheet = true
            } label: {
                Label("Adicionar Meu Primeiro Livro", systemImage: "book.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Seção de Artigos / Documentos Avulsos
    
    private var documentsView: some View {
        let displayList = viewModel.filteredDocuments(documents)
        
        return Group {
            if documents.isEmpty {
                emptyDocumentsStateView
            } else if displayList.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            } else {
                List {
                    ForEach(displayList) { document in
                        documentCardRow(document)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.selectedDocumentForReading = document
                            }
                            .contextMenu {
                                Button {
                                    viewModel.selectedDocumentForReading = document
                                } label: {
                                    Label("Ler com RSVP", systemImage: "play.fill")
                                }
                                
                                if document.isForeignLanguage {
                                    Button {
                                        translateOrToggleDocument(document)
                                    } label: {
                                        Label(
                                            document.hasTranslation ? (document.isTranslationActive ? String(localized: "Exibir no Idioma Original (\(document.detectedLanguageInfo.flag))") : String(localized: "Exibir em Português 🇧🇷")) : String(localized: "Traduzir para Português 🇧🇷"),
                                            systemImage: "character.bubble"
                                        )
                                    }
                                }
                                
                                Button {
                                    viewModel.resetProgress(for: document)
                                } label: {
                                    Label("Reiniciar Leitura", systemImage: "arrow.counterclockwise")
                                }
                                
                                Divider()
                                
                                Button(role: .destructive) {
                                    viewModel.deleteDocument(document, in: modelContext)
                                } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteDocument(document, in: modelContext)
                                } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                if document.isForeignLanguage {
                                    Button {
                                        translateOrToggleDocument(document)
                                    } label: {
                                        Label(
                                            document.hasTranslation ? (document.isTranslationActive ? String(localized: "Ver Original") : String(localized: "Ver em Português")) : String(localized: "Traduzir"),
                                            systemImage: "character.bubble"
                                        )
                                    }
                                    .tint(.indigo)
                                }
                                
                                Button {
                                    viewModel.resetProgress(for: document)
                                } label: {
                                    Label("Reiniciar", systemImage: "arrow.counterclockwise")
                                }
                                .tint(.orange)
                            }
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.sidebar)
                #endif
            }
        }
    }
    
    private func documentCardRow(_ document: Document) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Text(document.previewSnippet(maxLength: 95))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Text("\(Int(document.progressPercentage * 100))%")
                    .font(.caption.bold().monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(document.isCompleted ? Color.green.opacity(0.15) : Color.blue.opacity(0.12))
                    .foregroundStyle(document.isCompleted ? .green : Color.blue)
                    .clipShape(Capsule())
            }
            
            ProgressView(value: document.progressPercentage)
                .tint(document.isCompleted ? .green : .blue)
            
            HStack {
                Label("\(document.totalWords) palavras", systemImage: "text.word.spacing")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                if document.isForeignLanguage {
                    Button {
                        translateOrToggleDocument(document)
                    } label: {
                        HStack(spacing: 3) {
                            if document.isTranslationActive {
                                Text("🇧🇷 Traduzido")
                            } else if document.hasTranslation {
                                Text("\(document.detectedLanguageInfo.flag) Original")
                            } else {
                                Text("\(document.detectedLanguageInfo.flag) Traduzir 🇧🇷")
                            }
                        }
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(document.isTranslationActive ? Color.green.opacity(0.18) : Color.indigo.opacity(0.14))
                        .foregroundStyle(document.isTranslationActive ? Color.green : Color.indigo)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.borderless)
                }
                
                Spacer()
                
                let remaining = document.remainingReadingTimeMinutes(wpm: 300)
                Label(remaining < 1.0 ? String(localized: "Menos de 1 min") : String(format: String(localized: "%.0f min rest."), remaining), systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
    
    private var emptyDocumentsStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("Nenhum Artigo Avulso")
                    .font(.title2.bold())
                
                Text("Escaneie uma única página avulsa ou documento rápido para leitura instantânea.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                viewModel.isShowingScannerSheet = true
            } label: {
                Label("Escanear Página Rápida", systemImage: "camera.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Ações de Tradução de Artigos
    
    private func translateOrToggleDocument(_ document: Document) {
        if !document.hasTranslation {
            let lang = document.detectedLanguageCode ?? "en"
            if let content = document.content {
                let translated = BookTranslationFallback.translate(text: content.rawText, from: lang)
                let parser = TextParser()
                let parsed = parser.parse(rawText: translated)
                document.applyTranslation(text: translated, words: parsed.words)
                document.toggleTranslation(active: true)
                try? modelContext.save()
            }
        } else {
            document.toggleTranslation(active: !document.isTranslationActive)
            try? modelContext.save()
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(ModelContainer.preview)
}
