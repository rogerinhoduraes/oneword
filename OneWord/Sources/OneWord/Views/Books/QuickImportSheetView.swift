//
//  QuickImportSheetView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
import SwiftData

/// Modal versátil para importação rápida de conteúdo via URL da web ou colando texto diretamente da área de transferência.
public struct QuickImportSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    public enum ImportMode: String, CaseIterable, Identifiable {
        case url = "Link da Web"
        case text = "Colar Texto"
        
        public var id: String { rawValue }
    }
    
    @State private var mode: ImportMode = .url
    @State private var urlString: String = ""
    @State private var title: String = ""
    @State private var pastedText: String = ""
    
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var extractedArticle: ExtractedArticle? = nil
    
    /// Callback opcional quando o documento é criado com sucesso
    public var onDocumentCreated: ((Document) -> Void)?
    
    public init(onDocumentCreated: ((Document) -> Void)? = nil) {
        self.onDocumentCreated = onDocumentCreated
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // Modo de Entrada
                Section {
                    Picker("Origem do Conteúdo", selection: $mode) {
                        ForEach(ImportMode.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color.clear)
                
                if mode == .url {
                    urlSection
                } else {
                    textSection
                }
                
                if let article = extractedArticle {
                    previewSection(article: article)
                }
                
                if let errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Importar Conteúdo")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    if extractedArticle != nil || (!pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && mode == .text) {
                        Button("Salvar & Ler") {
                            saveAndOpen()
                        }
                        .bold()
                        .disabled(isLoading)
                    }
                }
            }
        }
    }
    
    // MARK: - Seção URL
    
    private var urlSection: some View {
        Section("URL do Artigo ou Post") {
            HStack {
                Image(systemName: "link")
                    .foregroundStyle(.blue)
                TextField("https://exemplo.com/artigo", text: $urlString)
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    #endif
                
                if !urlString.isEmpty {
                    Button {
                        urlString = ""
                        extractedArticle = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Button {
                fetchWebArticle()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .padding(.trailing, 4)
                        Text("Extraindo conteúdo foveal...")
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Extrair Artigo Limpo")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(urlString.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
    }
    
    // MARK: - Seção Colar Texto
    
    private var textSection: some View {
        Group {
            Section("Título do Artigo") {
                TextField("Ex: Resumo de Artigo Científico", text: $title)
            }
            
            Section("Conteúdo Textual") {
                TextEditor(text: $pastedText)
                    .frame(minHeight: 180)
                
                #if os(iOS)
                Button {
                    if let string = UIPasteboard.general.string {
                        pastedText = string
                        if title.isEmpty {
                            title = string.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) ?? "Texto Copiado"
                        }
                    }
                } label: {
                    Label("Colar da Área de Transferência", systemImage: "doc.on.clipboard.fill")
                }
                #endif
            }
        }
    }
    
    // MARK: - Preview do Artigo
    
    private func previewSection(article: ExtractedArticle) -> some View {
        Section("Pré-visualização do Conteúdo") {
            VStack(alignment: .leading, spacing: 8) {
                Text(article.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                if let author = article.author, !author.isEmpty {
                    Text("Por \(author)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 16) {
                    Label("\(article.wordCount) palavras", systemImage: "text.word.spacing")
                    Label(String(format: "%.1f min (300 WPM)", article.estimatedMinutes(at: 300)), systemImage: "clock")
                }
                .font(.footnote)
                .foregroundStyle(.blue)
                
                Text(article.textContent.prefix(250) + "...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Ações
    
    private func fetchWebArticle() {
        errorMessage = nil
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), url.scheme != nil else {
            errorMessage = "Insira uma URL válida iniciando com http:// ou https://"
            return
        }
        
        isLoading = true
        Task {
            do {
                let article = try await WebArticleExtractor().extract(from: url)
                await MainActor.run {
                    self.extractedArticle = article
                    self.title = article.title
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func saveAndOpen() {
        let finalArticle: ExtractedArticle
        if let current = extractedArticle {
            finalArticle = current
        } else {
            let effectiveTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Texto Colado" : title
            finalArticle = WebArticleExtractor().extract(fromHTML: pastedText, fallbackTitle: effectiveTitle)
        }
        
        guard !finalArticle.words.isEmpty else {
            errorMessage = "Nenhum texto para leitura encontrado."
            return
        }
        
        do {
            let doc = try WebArticleExtractor().saveAsDocument(article: finalArticle, context: modelContext)
            onDocumentCreated?(doc)
            dismiss()
        } catch {
            errorMessage = "Erro ao salvar: \(error.localizedDescription)"
        }
    }
}
