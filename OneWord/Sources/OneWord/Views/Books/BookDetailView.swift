//
//  BookDetailView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
import SwiftData
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

/// Tela de Detalhes do Livro.
/// Exibe informações, capa, estatísticas de progresso, índice de páginas escaneadas
/// e permite escanear novas páginas físicas em lote ou avulsas via Vision OCR.
public struct BookDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable public var book: Book
    
    // Controle de Leitura RSVP
    @State private var readingReaderViewModel: RSVPReaderViewModel?
    
    // Escaneamento de Páginas
    @State private var isShowingDocumentScanner: Bool = false
    @State private var isShowingCameraFallback: Bool = false
    @State private var isShowingPhotoPicker: Bool = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isShowingPDFImporter: Bool = false
    
    #if canImport(UIKit)
    @State private var scannedDocumentImages: [UIImage] = []
    @State private var cameraFallbackImage: UIImage?
    #endif
    
    // Feedback de Processamento
    @State private var isProcessing: Bool = false
    @State private var processingProgressText: String = ""
    
    // Edição de Capa
    @State private var isShowingEditCoverSheet: Bool = false
    
    public init(book: Book) {
        self.book = book
    }
    
    public var body: some View {
        mainContent
            .background(Color.bookGroupedBg)
            .navigationTitle(book.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            isShowingEditCoverSheet = true
                        } label: {
                            Label("Alterar Capa", systemImage: "photo")
                        }
                        
                        Button {
                            book.resetProgress()
                            try? modelContext.save()
                        } label: {
                            Label("Reiniciar Leitura", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header com Capa e Detalhes
                BookHeaderSection(
                    book: book,
                    onStartReading: { pageNum in
                        startReading(fromPage: pageNum)
                    }
                )
                
                // Barra de Ações Rápidas (Escanear Páginas)
                BookActionsBarSection(
                    onScanTapped: {
                        #if canImport(VisionKit) && !targetEnvironment(simulator)
                        isShowingDocumentScanner = true
                        #else
                        isShowingCameraFallback = true
                        #endif
                    },
                    onPhotosTapped: {
                        isShowingPhotoPicker = true
                    },
                    onPDFTapped: {
                        isShowingPDFImporter = true
                    }
                )
                
                // Índice de Páginas Escaneadas
                BookPagesIndexSection(
                    book: book,
                    onSelectPage: { pageNum in
                        startReading(fromPage: pageNum)
                    },
                    onDeletePage: { page in
                        deletePage(page)
                    }
                )
            }
            .padding(.vertical)
        }
        #if os(iOS)
        .fullScreenCover(item: Binding<IdentifiableReaderModel?>(
            get: { readingReaderViewModel.map { IdentifiableReaderModel(viewModel: $0) } },
            set: { readingReaderViewModel = $0?.viewModel }
        )) { wrapper in
            RSVPReaderView(viewModel: wrapper.viewModel)
        }
        #else
        .sheet(item: Binding<IdentifiableReaderModel?>(
            get: { readingReaderViewModel.map { IdentifiableReaderModel(viewModel: $0) } },
            set: { readingReaderViewModel = $0?.viewModel }
        )) { wrapper in
            RSVPReaderView(viewModel: wrapper.viewModel)
        }
        #endif
        #if canImport(VisionKit) && canImport(UIKit)
        .sheet(isPresented: $isShowingDocumentScanner) {
            VisionDocumentScannerView(scannedImages: $scannedDocumentImages)
        }
        .onChange(of: scannedDocumentImages) { _, newImages in
            guard !newImages.isEmpty else { return }
            processScannedImages(newImages)
        }
        #endif
        #if canImport(UIKit)
        .sheet(isPresented: $isShowingCameraFallback) {
            CameraPickerView(selectedImage: $cameraFallbackImage)
        }
        .onChange(of: cameraFallbackImage) { _, newImage in
            if let newImage {
                processScannedImages([newImage])
            }
        }
        #endif
        .photosPicker(isPresented: $isShowingPhotoPicker, selection: $selectedPhotoItems, matching: .images)
        .onChange(of: selectedPhotoItems) { _, items in
            guard !items.isEmpty else { return }
            processSelectedPhotos(items)
        }
        .fileImporter(
            isPresented: $isShowingPDFImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            processImportedPDF(result: result)
        }
        .overlay {
            if isProcessing {
                OCRProcessingOverlay(message: processingProgressText)
            }
        }
    }
    
    // MARK: - Ações de Leitura & Processamento
    
    private func startReading(fromPage pageNumber: Int?) {
        let vm = RSVPReaderViewModel(
            book: book,
            startPageNumber: pageNumber,
            modelContext: modelContext
        )
        self.readingReaderViewModel = vm
    }
    
    private func deletePage(_ page: BookPage) {
        if let idx = book.pages.firstIndex(where: { $0.id == page.id }) {
            book.pages.remove(at: idx)
            modelContext.delete(page)
            
            for (newIdx, remainingPage) in book.sortedPages.enumerated() {
                remainingPage.pageNumber = newIdx + 1
            }
            try? modelContext.save()
        }
    }
    
    #if canImport(UIKit)
    private func processScannedImages(_ images: [UIImage]) {
        guard !images.isEmpty else { return }
        
        Task {
            await MainActor.run {
                isProcessing = true
                processingProgressText = "Iniciando reconhecimento de texto..."
            }
            
            let ocrService = VisionOCRService()
            
            for (index, image) in images.enumerated() {
                await MainActor.run {
                    processingProgressText = "Processando OCR: Página \(index + 1) de \(images.count)..."
                }
                
                do {
                    let result = try await ocrService.recognizeText(from: image)
                    let jpegData = image.jpegData(compressionQuality: 0.6)
                    
                    await MainActor.run {
                        _ = book.addPage(
                            rawText: result.cleanedText,
                            words: result.words,
                            imageData: jpegData
                        )
                    }
                } catch {
                    print("Erro ao processar página \(index + 1): \(error)")
                }
            }
            
            await MainActor.run {
                try? modelContext.save()
                isProcessing = false
                scannedDocumentImages = []
                cameraFallbackImage = nil
            }
        }
    }
    #endif
    
    private func processSelectedPhotos(_ items: [PhotosPickerItem]) {
        Task {
            await MainActor.run {
                isProcessing = true
                processingProgressText = "Carregando fotos da galeria..."
            }
            
            #if canImport(UIKit)
            var loadedImages: [UIImage] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    loadedImages.append(uiImage)
                }
            }
            
            processScannedImages(loadedImages)
            #else
            await MainActor.run { isProcessing = false }
            #endif
            
            await MainActor.run {
                selectedPhotoItems = []
            }
        }
    }
    
    private func processImportedPDF(result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        
        Task {
            await MainActor.run {
                isProcessing = true
                processingProgressText = "Extraindo páginas do PDF..."
            }
            
            let pdfService = PDFImportService()
            do {
                let pagesData = try pdfService.extractPages(from: url)
                await MainActor.run {
                    for (text, words) in pagesData {
                        _ = book.addPage(rawText: text, words: words)
                    }
                    try? modelContext.save()
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }
}

// MARK: - Subcomponents

private struct BookHeaderSection: View {
    let book: Book
    let onStartReading: (Int?) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            BookCoverView(
                title: book.title,
                author: book.author,
                coverImageData: book.coverImageData,
                themeColorHex: book.coverThemeColor,
                width: 140,
                height: 205
            )
            
            VStack(spacing: 6) {
                Text(book.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if !book.author.isEmpty {
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Métricas Rápidas
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(book.totalPages)")
                        .font(.headline)
                    Text("Páginas")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Divider().frame(height: 24)
                
                VStack(spacing: 2) {
                    Text("\(book.totalWords)")
                        .font(.headline)
                    Text("Palavras")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Divider().frame(height: 24)
                
                VStack(spacing: 2) {
                    let mins = Int(book.remainingReadingTimeMinutes(wpm: 300))
                    Text("\(max(1, mins)) min")
                        .font(.headline)
                    Text("Tempo Rest.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.bookCardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Barra de Progresso
            if book.totalWords > 0 {
                VStack(spacing: 6) {
                    ProgressView(value: book.progressPercentage)
                        .tint(.blue)
                    
                    HStack {
                        Text("\(Int(book.progressPercentage * 100))% concluído")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("Pág. \(book.currentPageNumber) de \(book.totalPages)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 24)
            }
            
            // Botão Principal de Leitura
            Button {
                onStartReading(nil)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: book.isCompleted ? "arrow.counterclockwise" : "play.fill")
                    Text(buttonTitle)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(book.totalWords == 0 ? Color.secondary.opacity(0.3) : Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(book.totalWords == 0)
            .padding(.horizontal, 24)
        }
    }
    
    private var buttonTitle: String {
        if book.totalWords == 0 {
            return "Escaneie páginas para ler"
        }
        if book.currentGlobalWordIndex == 0 {
            return "Iniciar Leitura RSVP"
        }
        if book.isCompleted {
            return "Ler Livro Novamente"
        }
        return "Continuar da Pág. \(book.currentPageNumber)"
    }
}

private struct BookActionsBarSection: View {
    let onScanTapped: () -> Void
    let onPhotosTapped: () -> Void
    let onPDFTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Adicionar Conteúdo")
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            
            HStack(spacing: 12) {
                Button(action: onScanTapped) {
                    VStack(spacing: 6) {
                        Image(systemName: "doc.viewfinder.fill")
                            .font(.title2)
                        Text("Escanear Páginas")
                            .font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue.opacity(0.12))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                
                Button(action: onPhotosTapped) {
                    VStack(spacing: 6) {
                        Image(systemName: "photo.stack.fill")
                            .font(.title2)
                        Text("Fotos da Galeria")
                            .font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.purple.opacity(0.12))
                    .foregroundStyle(.purple)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                
                Button(action: onPDFTapped) {
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.title2)
                        Text("Importar PDF")
                            .font(.caption.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.orange.opacity(0.12))
                    .foregroundStyle(.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

private struct BookPagesIndexSection: View {
    let book: Book
    let onSelectPage: (Int) -> Void
    let onDeletePage: (BookPage) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Índice de Páginas")
                    .font(.headline)
                
                Spacer()
                
                Text("\(book.totalPages) \(book.totalPages == 1 ? "página" : "páginas")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            
            if book.pages.isEmpty {
                ContentUnavailableView(
                    "Nenhuma página escaneada",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Toque em 'Escanear Páginas' acima para capturar suas folhas físicas e começar a ler.")
                )
                .frame(height: 180)
            } else {
                VStack(spacing: 10) {
                    ForEach(book.sortedPages) { page in
                        PageRowItem(
                            page: page,
                            isCurrentPage: (book.currentPageNumber == page.pageNumber) && !book.isCompleted,
                            onTap: { onSelectPage(page.pageNumber) },
                            onDelete: { onDeletePage(page) }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

private struct PageRowItem: View {
    let page: BookPage
    let isCurrentPage: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isCurrentPage ? Color.blue : Color.secondary.opacity(0.15))
                        .frame(width: 38, height: 38)
                    
                    Text("\(page.pageNumber)")
                        .font(.headline)
                        .foregroundStyle(isCurrentPage ? .white : .primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Página \(page.pageNumber)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        if isCurrentPage {
                            Text("LENDO AGORA")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        Text("\(page.wordCount) palavras")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(page.previewSnippet)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color.bookCardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Excluir Página", systemImage: "trash")
            }
        }
    }
}

private struct OCRProcessingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.white)
                
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(28)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

private struct IdentifiableReaderModel: Identifiable {
    let id = UUID()
    let viewModel: RSVPReaderViewModel
}

private extension Color {
    static var bookGroupedBg: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGroupedBackground)
        #else
        return Color(.windowBackgroundColor)
        #endif
    }
    
    static var bookCardBg: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #else
        return Color(.controlBackgroundColor)
        #endif
    }
}
