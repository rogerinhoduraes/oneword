//
//  OCRServiceProtocol.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import CoreGraphics
import ImageIO

#if canImport(UIKit)
import UIKit
#endif

/// Contrato formal para o serviço de reconhecimento óptico de caracteres (OCR).
/// Permite injeção de dependências, desacoplamento do framework de visão computacional
/// e criação facilitada de mocks para testes unitários automatizados.
public protocol OCRServiceProtocol: Sendable {
    #if canImport(UIKit)
    /// Reconhece texto a partir de uma instância de UIImage capturada da câmera ou galeria.
    /// - Parameter image: Imagem contendo página ou parágrafo de texto.
    /// - Returns: Estrutura `OCRResult` com texto bruto, texto higienizado e tokens para RSVP.
    /// - Throws: `OCRError` caso a imagem seja inválida, ocorra erro no Vision ou nenhum texto seja encontrado.
    func recognizeText(from image: UIImage) async throws -> OCRResult
    #endif
    
    /// Reconhece texto a partir de um CGImage nativo com informação de orientação.
    /// - Parameters:
    ///   - cgImage: Referência CoreGraphics para o bitmap.
    ///   - orientation: Orientação do sensor ou EXIF.
    /// - Returns: Estrutura `OCRResult`.
    /// - Throws: `OCRError`.
    func recognizeText(from cgImage: CGImage, orientation: CGImagePropertyOrientation) async throws -> OCRResult
    
    /// Reconhece texto a partir de um buffer de bytes brutos de imagem (ex: PNG, HEIC, JPEG).
    /// - Parameter data: Dados brutos codificados da imagem.
    /// - Returns: Estrutura `OCRResult`.
    /// - Throws: `OCRError`.
    func recognizeText(from data: Data) async throws -> OCRResult
}
