//
//  OCRError.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation

/// Representa erros específicos ocorridos durante o ciclo de captura, pré-processamento e reconhecimento OCR.
public enum OCRError: LocalizedError, Sendable, Equatable {
    /// Os dados da imagem fornecidos são inválidos ou não puderam ser decodificados.
    case invalidImageData
    
    /// Não foi possível extrair ou gerar um CGImage válido a partir da imagem.
    case cgImageCreationFailed
    
    /// O Vision Framework falhou ao processar a requisição de reconhecimento.
    case recognitionFailed(reason: String)
    
    /// O reconhecimento foi concluído, porém nenhum caractere ou texto legível foi detectado na imagem.
    case noTextDetected
    
    /// O usuário não concedeu permissão para o uso da câmera fotográfica.
    case cameraPermissionDenied
    
    /// O usuário cancelou o processo de captura ou a operação foi abortada.
    case cancelled
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Dados de imagem inválidos ou corrompidos."
        case .cgImageCreationFailed:
            return "Não foi possível converter a imagem para CGImage para processamento gráfico."
        case .recognitionFailed(let reason):
            return "Falha no reconhecimento de texto via Vision: \(reason)"
        case .noTextDetected:
            return "Nenhum texto legível foi detectado na página escaneada. Tente capturar com melhor iluminação e enquadramento."
        case .cameraPermissionDenied:
            return "Acesso à câmera não autorizado. Habilite a permissão nas configurações do sistema."
        case .cancelled:
            return "Operação de captura cancelada."
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .invalidImageData:
            return "O buffer de imagem não contém um formato de imagem reconhecido."
        case .cgImageCreationFailed:
            return "A renderização de bitmap da imagem falhou."
        case .recognitionFailed(let reason):
            return reason
        case .noTextDetected:
            return "O motor de OCR não encontrou regiões com probabilidade suficiente de caracteres de texto."
        case .cameraPermissionDenied:
            return "Permissão negada pelo usuário no iOS."
        case .cancelled:
            return "O fluxo foi interrompido voluntariamente."
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .noTextDetected:
            return "Certifique-se de que a página está bem iluminada, sem reflexos e com o texto focado."
        case .cameraPermissionDenied:
            return "Acesse Ajustes > OneWord e autorize o uso da Câmera."
        default:
            return "Tente novamente ou selecione uma imagem diferente da galeria."
        }
    }
}
