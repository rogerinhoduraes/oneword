//
//  AddBookSheetView.swift
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

/// Folha modal para criação de um novo Livro na biblioteca.
/// Permite escanear a capa com a câmera, escolher da galeria ou definir tema de capa minimalista.
public struct AddBookSheetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var author: String = ""
    @State private var selectedThemeHex: String = "#1E40AF"
    
    // Capa
    @State private var coverImageData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isShowingCameraPicker: Bool = false
    #if canImport(UIKit)
    @State private var cameraCapturedImage: UIImage?
    #endif
    
    /// Callback opcional chamado quando o livro é criado
    public var onBookCreated: ((Book) -> Void)?
    
    private let colorPresets: [(name: String, hex: String)] = [
        ("Azul Real", "#1E40AF"),
        ("Esmeralda", "#047857"),
        ("Vinho", "#881337"),
        ("Roxo", "#6B21A8"),
        ("Âmbar", "#B45309"),
        ("Grafite", "#334155")
    ]
    
    public init(onBookCreated: ((Book) -> Void)? = nil) {
        self.onBookCreated = onBookCreated
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                // MARK: - Preview da Capa
                Section {
                    HStack {
                        Spacer()
                        BookCoverView(
                            title: title.isEmpty ? String(localized: "Título do Livro") : title,
                            author: author,
                            coverImageData: coverImageData,
                            themeColorHex: selectedThemeHex,
                            width: 120,
                            height: 175
                        )
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }
                
                // MARK: - Dados do Livro
                Section("Informações Básicas") {
                    TextField("Título do Livro", text: $title)
                        .autocorrectionDisabled()
                    
                    TextField("Autor (Opcional)", text: $author)
                        .autocorrectionDisabled()
                }
                
                // MARK: - Captura da Capa
                Section("Capa do Livro") {
                    Button {
                        isShowingCameraPicker = true
                    } label: {
                        Label("Fotografar Capa com Câmera", systemImage: "camera.fill")
                    }
                    
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Escolher Foto da Galeria", systemImage: "photo.on.rectangle.angled")
                    }
                    
                    if coverImageData != nil {
                        Button(role: .destructive) {
                            coverImageData = nil
                        } label: {
                            Label("Remover Foto (Usar Capa Tipográfica)", systemImage: "trash")
                        }
                    }
                }
                
                // MARK: - Cor Tema (Fallback / Borda)
                Section("Cor da Capa Procedural") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colorPresets, id: \.hex) { preset in
                            Circle()
                                .fill(Color(hex: preset.hex))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedThemeHex == preset.hex ? 3 : 0)
                                )
                                .onTapGesture {
                                    selectedThemeHex = preset.hex
                                }
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Novo Livro")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Criar Livro") {
                        saveBook()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.bold)
                }
            }
            #if canImport(UIKit)
            .sheet(isPresented: $isShowingCameraPicker) {
                CameraPickerView(selectedImage: $cameraCapturedImage)
            }
            .onChange(of: cameraCapturedImage) { _, newImage in
                if let newImage, let jpegData = newImage.jpegData(compressionQuality: 0.8) {
                    self.coverImageData = jpegData
                }
            }
            #endif
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            self.coverImageData = data
                        }
                    }
                }
            }
        }
    }
    
    private func saveBook() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        
        let book = Book(
            title: trimmedTitle,
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            coverImageData: coverImageData,
            coverThemeColor: selectedThemeHex
        )
        
        modelContext.insert(book)
        try? modelContext.save()
        
        dismiss()
        onBookCreated?(book)
    }
}
