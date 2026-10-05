//
//  DocumentScannerView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

#if canImport(VisionKit) && canImport(UIKit)
import VisionKit
#endif

#if canImport(UIKit)
import UIKit
#endif

/// Tela modal para captura de páginas físicas de livros via Câmera e Galeria de Fotos,
/// com processamento offline pelo Vision OCR e revisão antes de salvar no SwiftData.
public struct DocumentScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel = DocumentScannerViewModel()
    
    // Estados locais de seleção de mídia
    @State private var selectedPhotoItem: PhotosPickerItem?
    #if canImport(UIKit)
    @State private var capturedCameraImage: UIImage?
    #endif
    @State private var isShowingCamera: Bool = false
    
    #if canImport(VisionKit) && canImport(UIKit)
    @State private var scannedDocumentPages: [UIImage] = []
    @State private var isShowingVisionScanner: Bool = false
    #endif
    
    @State private var isShowingFileImporter: Bool = false
    @State private var translateToPortugueseOnSave: Bool = true
    
    /// Callback opcional chamado quando o documento é criado (para abrir o leitor diretamente).
    public var onDocumentSaved: ((Document) -> Void)?
    
    public init(onDocumentSaved: ((Document) -> Void)? = nil) {
        self.onDocumentSaved = onDocumentSaved
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColorOrFallback: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isProcessing {
                    processingOverlay
                } else if viewModel.isReviewingScannedContent {
                    reviewContentForm
                } else {
                    captureSelectionView
                }
            }
            .navigationTitle("Escanear Página")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
            #if canImport(VisionKit) && canImport(UIKit)
            .fullScreenCover(isPresented: $isShowingVisionScanner) {
                VisionDocumentScannerView(scannedImages: $scannedDocumentPages)
                    .ignoresSafeArea()
            }
            .onChange(of: scannedDocumentPages) { _, newPages in
                guard let first = newPages.first else { return }
                Task {
                    await viewModel.processImage(first)
                }
            }
            #endif
            #if canImport(UIKit)
            .fullScreenCover(isPresented: $isShowingCamera) {
                CameraPickerView(selectedImage: $capturedCameraImage)
                    .ignoresSafeArea()
            }
            .onChange(of: capturedCameraImage) { _, newImage in
                if let newImage {
                    Task {
                        await viewModel.processImage(newImage)
                    }
                }
            }
            #endif
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await viewModel.processImageData(data)
                    }
                }
            }
            .fileImporter(
                isPresented: $isShowingFileImporter,
                allowedContentTypes: [.pdf, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    importDocumentFile(at: url)
                case .failure(let error):
                    viewModel.errorMessage = String(localized: "Falha ao selecionar arquivo: \(error.localizedDescription)")
                    viewModel.showErrorAlert = true
                }
            }
            .alert("Aviso de OCR", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? String(localized: "Ocorreu um erro no processamento."))
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Menu inicial de opções de captura (Câmera, Galeria ou Arquivo PDF/TXT).
    private var captureSelectionView: some View {
        VStack(spacing: 28) {
            Spacer()
            
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.tint)
            
            VStack(spacing: 8) {
                Text("Capturar Página ou Livro")
                    .font(.title2.bold())
                
                Text("Aponte a câmera para um parágrafo ou página física, ou importe diretamente um documento PDF do seu dispositivo.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                #if canImport(UIKit)
                Button {
                    startCameraScan()
                } label: {
                    Label("Escanear Livro com a Câmera", systemImage: "camera.viewfinder")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
                #endif
                
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("Escolher da Galeria de Fotos", systemImage: "photo.on.rectangle.angled")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(uiColorOrFallback: .secondarySystemGroupedBackground))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                
                Button {
                    isShowingFileImporter = true
                } label: {
                    Label("Importar Arquivo (PDF ou TXT)", systemImage: "doc.badge.plus")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(uiColorOrFallback: .secondarySystemGroupedBackground))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 24)
                
                // Opção de demonstração / fallback para testes rápidos
                Button {
                    loadDemoText()
                } label: {
                    Text("Carregar Trecho de Exemplo")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(.bottom, 24)
        }
    }
    
    /// Indicador visual animado durante o reconhecimento óptico.
    private var processingOverlay: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.4)
            
            Text(viewModel.statusMessage)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColorOrFallback: .systemBackground).opacity(0.85))
    }
    
    /// Tela de revisão do texto extraído antes de persistir no SwiftData.
    private var reviewContentForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Seção de Título
                VStack(alignment: .leading, spacing: 8) {
                    Text("Título do Documento")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    
                    TextField("Digite um título", text: $viewModel.editableTitle)
                        .font(.headline)
                        .padding()
                        .background(Color(uiColorOrFallback: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                
                // Badges de metadados extraídos
                HStack(spacing: 12) {
                    if let result = viewModel.scanResult {
                        Label("\(result.wordCount) palavras", systemImage: "text.word.spacing")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.12))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                        
                        Label(String(format: String(localized: "%.0f%% precisão"), result.averageConfidence * 100), systemImage: "checkmark.seal")
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.12))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }
                
                // Detecção de Idioma Estrangeiro e Opção de Tradução para Português
                let detectedLang = BookTranslationService.detectLanguage(for: viewModel.editableText)
                let langInfo = BookTranslationService.languageInfo(for: detectedLang)
                
                if !langInfo.isPortuguese {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("\(langInfo.flag) Idioma Detectado:")
                                .font(.caption.bold())
                                .foregroundStyle(.primary)
                            Text(langInfo.name)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        
                        Toggle(isOn: $translateToPortugueseOnSave) {
                            HStack(spacing: 6) {
                                Image(systemName: "character.bubble")
                                    .foregroundStyle(.indigo)
                                Text("Traduzir para Português 🇧🇷")
                                    .font(.subheadline.weight(.medium))
                            }
                        }
                        .tint(.indigo)
                    }
                    .padding(14)
                    .background(Color.indigo.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                
                // Seção de Texto Higienizado
                VStack(alignment: .leading, spacing: 8) {
                    Text("Texto Higienizado (Quebras Artificiais Removidas)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $viewModel.editableText)
                        .frame(minHeight: 220)
                        .padding(8)
                        .background(Color(uiColorOrFallback: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                
                // Ação de Salvamento
                Button {
                    let doc = viewModel.saveDocument(
                        in: modelContext,
                        translateToPortuguese: translateToPortugueseOnSave
                    )
                    if let doc {
                        onDocumentSaved?(doc)
                        dismiss()
                    }
                } label: {
                    Label("Salvar e Iniciar Leitura RSVP", systemImage: "book.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.top, 12)
            }
            .padding(20)
        }
    }
    
    // MARK: - Ações Auxiliares
    
    private func loadDemoText() {
        let demoRaw = """
        O método RSVP (Rapid Serial Visual Presentation) revoluciona a forma como processamos textos físicos e digitais.
        
        Ao fixar o olhar no centro óptico de reconhecimento e apresentar as palavras sequencialmente com pausas calculadas para vírgulas e pontos finais, a velocidade de leitura pode dobrar com facilidade, mantendo foco absoluto e alta retenção.
        """
        viewModel.editableTitle = "Introdução ao Método RSVP"
        viewModel.editableText = demoRaw
        viewModel.isReviewingScannedContent = true
    }
    
    private func startCameraScan() {
        #if canImport(VisionKit) && canImport(UIKit)
        if VNDocumentCameraViewController.isSupported {
            isShowingVisionScanner = true
            return
        }
        #endif
        #if canImport(UIKit)
        isShowingCamera = true
        #endif
    }
    
    private func importDocumentFile(at url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let importer = PDFImportService()
            let isPDF = url.pathExtension.lowercased() == "pdf"
            let (title, text, words) = isPDF 
                ? try importer.extractText(from: url)
                : try importer.extractTextFromTXT(at: url)
            
            viewModel.editableTitle = title
            viewModel.editableText = text
            viewModel.scanResult = OCRResult(
                rawText: text,
                cleanedText: text,
                words: words,
                averageConfidence: 1.0
            )
            viewModel.isReviewingScannedContent = true
        } catch {
            viewModel.errorMessage = String(localized: "Erro ao importar arquivo: \(error.localizedDescription)")
            viewModel.showErrorAlert = true
        }
    }
}

// Extensão utilitária para compatibilidade cross-platform (iOS / macOS previews)
private extension Color {
    init(uiColorOrFallback: UIColorType) {
        #if canImport(UIKit)
        switch uiColorOrFallback {
        case .systemGroupedBackground:
            self.init(uiColor: .systemGroupedBackground)
        case .secondarySystemGroupedBackground:
            self.init(uiColor: .secondarySystemGroupedBackground)
        case .systemBackground:
            self.init(uiColor: .systemBackground)
        }
        #else
        self.init(.windowBackgroundColor)
        #endif
    }
    
    enum UIColorType {
        case systemGroupedBackground
        case secondarySystemGroupedBackground
        case systemBackground
    }
}
