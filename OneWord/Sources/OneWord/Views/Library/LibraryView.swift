//
//  LibraryView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
import SwiftData

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
                        Text(tab.rawValue).tag(tab)
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
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            isShowingAddBookSheet = true
                        } label: {
                            Label("Novo Livro", systemImage: "book.badge.plus")
                        }
                        
                        Button {
                            viewModel.isShowingScannerSheet = true
                        } label: {
                            Label("Escanear Documento Avulso", systemImage: "camera.fill")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $isShowingAddBookSheet) {
                AddBookSheetView { newBook in
                    self.selectedBookForNavigation = newBook
                }
            }
            .sheet(isPresented: $viewModel.isShowingScannerSheet) {
                DocumentScannerView { newDoc in
                    viewModel.selectedDocumentForReading = newDoc
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
                    Text("\(book.totalPages) \(book.totalPages == 1 ? "pág." : "págs.")")
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.deleteDocument(document, in: modelContext)
                                } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
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
                
                Spacer()
                
                let remaining = document.remainingReadingTimeMinutes(wpm: 300)
                Label(remaining < 1.0 ? "Menos de 1 min" : String(format: "%.0f min rest.", remaining), systemImage: "clock")
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    LibraryView()
        .modelContainer(ModelContainer.preview)
}
