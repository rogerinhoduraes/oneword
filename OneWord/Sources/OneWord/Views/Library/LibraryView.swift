//
//  LibraryView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
import SwiftData

/// Tela principal do OneWord: gerencia a biblioteca de documentos persistidos via SwiftData,
/// exibe cards informativos com progresso de leitura e fornece pontos de entrada para captura e leitura.
public struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Document.lastAccessedAt, order: .reverse) private var documents: [Document]
    
    @State private var viewModel = LibraryViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Group {
                let displayList = viewModel.filteredDocuments(documents)
                
                if documents.isEmpty {
                    emptyLibraryStateView
                } else if displayList.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                } else {
                    documentsListView(displayList)
                }
            }
            .navigationTitle("OneWord")
            .searchable(text: $viewModel.searchText, prompt: "Buscar por título ou conteúdo...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isShowingScannerSheet = true
                    } label: {
                        Label("Escanear", systemImage: "camera.badge.ellipsis")
                            .font(.headline)
                    }
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
        }
    }
    
    // MARK: - Lista de Documentos
    
    private func documentsListView(_ docs: [Document]) -> some View {
        List {
            ForEach(docs) { document in
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
    
    // MARK: - Card Individual de Documento
    
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
                
                // Badge de progresso
                Text("\(Int(document.progressPercentage * 100))%")
                    .font(.caption.bold().monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(document.isCompleted ? Color.green.opacity(0.15) : Color.accentColor.opacity(0.12))
                    .foregroundStyle(document.isCompleted ? .green : Color.accentColor)
                    .clipShape(Capsule())
            }
            
            // Barra de progresso visual fina
            ProgressView(value: document.progressPercentage)
                .tint(document.isCompleted ? .green : .accentColor)
            
            // Metadados inferiores (palavras, tempo estimado e última leitura)
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
    
    // MARK: - Estado Vazio
    
    private var emptyLibraryStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.pages")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(.tint)
            
            VStack(spacing: 8) {
                Text("Sua Biblioteca está Vazia")
                    .font(.title2.bold())
                
                Text("Aponte a câmera para qualquer página de livro ou revista para extrair o texto e iniciar a leitura dinâmica RSVP.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button {
                viewModel.isShowingScannerSheet = true
            } label: {
                Label("Escanear Primeira Página", systemImage: "camera.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.top, 8)
        }
        .padding()
    }
}
