//
//  LibraryViewModel.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftData
import Observation

/// ViewModel responsável pelo gerenciamento da biblioteca de documentos,
/// filtragem/busca e coordenação de fluxo para scanner e leitor RSVP.
@Observable
@MainActor
public final class LibraryViewModel {
    
    // MARK: - Estado da UI
    
    /// Termo de busca digitado pelo usuário na barra de pesquisa.
    public var searchText: String = ""
    
    /// Controla a exibição do modal de escaneamento e captura de texto.
    public var isShowingScannerSheet: Bool = false
    
    /// Controla a exibição do seletor da galeria de fotos.
    public var isShowingPhotoPicker: Bool = false
    
    /// Documento selecionado atualmente para leitura em tela cheia.
    public var selectedDocumentForReading: Document?
    
    // MARK: - Inicializador
    
    public init() {}
    
    // MARK: - Ações de Negócio
    
    /// Filtra documentos conforme o termo digitado na barra de busca.
    /// - Parameter documents: Lista completa de documentos retornada pelo `@Query`.
    /// - Returns: Lista filtrada ou integral.
    public func filteredDocuments(_ documents: [Document]) -> [Document] {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            return documents
        }
        return documents.filter { doc in
            doc.title.localizedCaseInsensitiveContains(searchText) ||
            (doc.content?.rawText.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    /// Exclui um documento do banco de dados SwiftData e salva o contexto.
    /// - Parameters:
    ///   - document: Documento a ser removido.
    ///   - context: Contexto do SwiftData (`ModelContext`).
    public func deleteDocument(_ document: Document, in context: ModelContext) {
        context.delete(document)
        do {
            try context.save()
        } catch {
            print("Erro ao excluir documento do SwiftData: \(error.localizedDescription)")
        }
    }
    
    /// Reinicia o progresso de leitura do documento selecionado para zero.
    /// - Parameter document: Documento cujo progresso será zerado.
    public func resetProgress(for document: Document) {
        document.resetProgress()
    }
}
