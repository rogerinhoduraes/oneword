//
//  DocumentScannerViewModel.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftData
import Observation

#if canImport(UIKit)
import UIKit
#endif

/// ViewModel responsável pelo fluxo de captura da câmera/galeria,
/// processamento com o Vision Framework, higienização do texto e criação de novos documentos.
@Observable
@MainActor
public final class DocumentScannerViewModel {
    
    // MARK: - Dependências
    
    private let ocrService: OCRServiceProtocol
    private let parser: TextParser
    
    // MARK: - Estados de UI e Processamento
    
    /// Indica se o pipeline OCR está em execução no momento.
    public var isProcessing: Bool = false
    
    /// Mensagem de status exibida ao usuário durante as etapas do OCR.
    public var statusMessage: String = ""
    
    /// Mensagem de erro em caso de falha no escaneamento ou decodificação.
    public var errorMessage: String?
    
    /// Controla exibição de alerta de erro.
    public var showErrorAlert: Bool = false
    
    /// Resultado consolidado retornado pelo serviço de OCR.
    public var scanResult: OCRResult?
    
    /// Título editável do documento antes do salvamento.
    public var editableTitle: String = ""
    
    /// Texto higienizado editável antes da confirmação final.
    public var editableText: String = ""
    
    /// Indica se um documento foi processado e aguarda confirmação de salvamento.
    public var isReviewingScannedContent: Bool = false
    
    // MARK: - Inicializador
    
    public init(
        ocrService: OCRServiceProtocol = VisionOCRService(),
        parser: TextParser = TextParser()
    ) {
        self.ocrService = ocrService
        self.parser = parser
    }
    
    // MARK: - Processamento de Imagem
    
    #if canImport(UIKit)
    /// Processa uma foto capturada pela câmera do dispositivo ou selecionada da galeria.
    /// - Parameter image: Instância de UIImage.
    public func processImage(_ image: UIImage) async {
        isProcessing = true
        statusMessage = String(localized: "Escaneando página com Vision OCR...")
        errorMessage = nil
        showErrorAlert = false
        
        do {
            let result = try await ocrService.recognizeText(from: image)
            
            // Popula estados com os dados extraídos
            self.scanResult = result
            self.editableTitle = result.suggestedTitle
            self.editableText = result.cleanedText
            self.isReviewingScannedContent = true
            self.isProcessing = false
        } catch let error as OCRError {
            handleError(error.localizedDescription)
        } catch {
            handleError(String(localized: "Falha inesperada no processamento da imagem: \(error.localizedDescription)"))
        }
    }
    #endif
    
    /// Processa dados brutos de imagem (ex: Data recebido de PhotosPicker).
    /// - Parameter data: Bytes codificados da imagem.
    public func processImageData(_ data: Data) async {
        isProcessing = true
        statusMessage = String(localized: "Extraindo caracteres ópticos...")
        errorMessage = nil
        showErrorAlert = false
        
        do {
            let result = try await ocrService.recognizeText(from: data)
            
            self.scanResult = result
            self.editableTitle = result.suggestedTitle
            self.editableText = result.cleanedText
            self.isReviewingScannedContent = true
            self.isProcessing = false
        } catch let error as OCRError {
            handleError(error.localizedDescription)
        } catch {
            handleError(String(localized: "Falha inesperada ao processar dados de imagem: \(error.localizedDescription)"))
        }
    }
    
    // MARK: - Persistência
    
    /// Salva o documento escaneado no banco de dados SwiftData e retorna a entidade criada.
    /// - Parameter context: Contexto SwiftData (`ModelContext`).
    /// - Returns: Instância de `Document` persistida ou `nil` se texto estiver vazio.
    @discardableResult
    public func saveDocument(in context: ModelContext, translateToPortuguese: Bool = false) -> Document? {
        let finalTitle = editableTitle.trimmingCharacters(in: .whitespaces).isEmpty ? String(localized: "Documento Escaneado") : editableTitle
        let (_, words) = parser.parse(rawText: editableText)
        
        guard !words.isEmpty else {
            handleError(String(localized: "O documento não contém palavras suficientes para leitura."))
            return nil
        }
        
        let detectedLang = BookTranslationService.detectLanguage(for: editableText)
        let newDocument = Document(
            title: finalTitle,
            rawText: editableText,
            words: words,
            initialWordIndex: 0,
            originalLanguage: detectedLang
        )
        
        if translateToPortuguese, newDocument.isForeignLanguage {
            let lang = detectedLang ?? "en"
            let translated = BookTranslationFallback.translate(text: editableText, from: lang)
            let (_, translatedWords) = parser.parse(rawText: translated)
            newDocument.applyTranslation(text: translated, words: translatedWords)
            newDocument.toggleTranslation(active: true)
        }
        
        context.insert(newDocument)
        
        do {
            try context.save()
            reset()
            return newDocument
        } catch {
            handleError(String(localized: "Erro ao salvar documento na biblioteca: \(error.localizedDescription)"))
            return nil
        }
    }
    
    /// Reinicia o estado do scanner para nova captura.
    public func reset() {
        isProcessing = false
        statusMessage = ""
        errorMessage = nil
        showErrorAlert = false
        scanResult = nil
        editableTitle = ""
        editableText = ""
        isReviewingScannedContent = false
    }
    
    // MARK: - Tratamento de Erros
    
    private func handleError(_ message: String) {
        self.errorMessage = message
        self.showErrorAlert = true
        self.isProcessing = false
        self.isReviewingScannedContent = false
    }
}
