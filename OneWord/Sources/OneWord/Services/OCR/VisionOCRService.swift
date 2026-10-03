//
//  VisionOCRService.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import Vision
import CoreGraphics
import ImageIO
import CoreImage

#if canImport(UIKit)
import UIKit
#endif

/// Implementação de alta performance do serviço de OCR utilizando o Apple Vision Framework nativo.
/// Configurado com reconhecimento preciso (`VNRequestTextRecognitionLevel.accurate`),
/// correção ortográfica integrada e execução cooperativa assíncrona fora da thread principal.
public final class VisionOCRService: OCRServiceProtocol {
    
    // MARK: - Propriedades
    
    /// Parser responsável por higienizar linhas e quebras artificiais de parágrafo.
    private let parser: TextParser
    
    /// Lista de códigos de idiomas prioritários para reconhecimento óptico (ex: ["pt-BR", "en-US"]).
    public let recognitionLanguages: [String]
    
    /// Nível de precisão do Vision (padrão: .accurate para alta fidelidade em páginas de livros).
    public let recognitionLevel: VNRequestTextRecognitionLevel
    
    /// Habilita modelos de linguagem estatísticos do iOS para auto-correção de caracteres ambíguos.
    public let usesLanguageCorrection: Bool
    
    // MARK: - Inicializador
    
    /// Inicializa uma nova instância do serviço de OCR.
    /// - Parameters:
    ///   - parser: Instância customizada do parser de texto (default: TextParser padrão).
    ///   - recognitionLanguages: Idiomas suportados em ordem de prioridade (default: ["pt-BR", "en-US"]).
    ///   - recognitionLevel: Nível de precisão do Vision (default: .accurate).
    ///   - usesLanguageCorrection: Habilita correção de linguagem (default: true).
    public init(
        parser: TextParser = TextParser(),
        recognitionLanguages: [String] = ["pt-BR", "en-US", "es-ES"],
        recognitionLevel: VNRequestTextRecognitionLevel = .accurate,
        usesLanguageCorrection: Bool = true
    ) {
        self.parser = parser
        self.recognitionLanguages = recognitionLanguages
        self.recognitionLevel = recognitionLevel
        self.usesLanguageCorrection = usesLanguageCorrection
    }
    
    // MARK: - OCRServiceProtocol
    
    #if canImport(UIKit)
    /// Processa uma instância de UIImage, preservando a orientação do sensor da câmera ou EXIF.
    public func recognizeText(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            // Tenta obter cgImage a partir de CIImage se a UIImage foi sintetizada
            if let ciImage = image.ciImage {
                let context = CIContext(options: nil)
                guard let renderedCG = context.createCGImage(ciImage, from: ciImage.extent) else {
                    throw OCRError.cgImageCreationFailed
                }
                return try await recognizeText(from: renderedCG, orientation: image.cgImagePropertyOrientation)
            }
            throw OCRError.cgImageCreationFailed
        }
        
        return try await recognizeText(from: cgImage, orientation: image.cgImagePropertyOrientation)
    }
    #endif
    
    /// Processa um buffer de dados brutos de imagem (JPEG, HEIC, PNG) via ImageIO.
    public func recognizeText(from data: Data) async throws -> OCRResult {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw OCRError.invalidImageData
        }
        return try await recognizeText(from: cgImage, orientation: .up)
    }
    
    /// Executa o pipeline de visão computacional em um `CGImage` com orientação informada.
    public func recognizeText(
        from cgImage: CGImage,
        orientation: CGImagePropertyOrientation = .up
    ) async throws -> OCRResult {
        // Executa fora da thread principal para não engasgar a taxa de atualização da UI
        try await Task.detached(priority: .userInitiated) { [weak self, parser, recognitionLanguages, recognitionLevel, usesLanguageCorrection] in
            guard self != nil else { throw OCRError.cancelled }
            
            return try await withCheckedThrowingContinuation { continuation in
                let request = VNRecognizeTextRequest { request, error in
                    if let error {
                        continuation.resume(throwing: OCRError.recognitionFailed(reason: error.localizedDescription))
                        return
                    }
                    
                    guard let observations = request.results as? [VNRecognizedTextObservation],
                          !observations.isEmpty else {
                        continuation.resume(throwing: OCRError.noTextDetected)
                        return
                    }
                    
                    var recognizedLines: [RecognizedLineInfo] = []
                    var totalConfidence: Float = 0.0
                    var count: Float = 0.0
                    
                    for observation in observations {
                        // Obtém o candidato de maior probabilidade para a observação
                        if let topCandidate = observation.topCandidates(1).first {
                            let text = topCandidate.string.trimmingCharacters(in: .whitespaces)
                            guard !text.isEmpty else { continue }
                            
                            let lineInfo = RecognizedLineInfo(
                                text: text,
                                confidence: topCandidate.confidence,
                                boundingBox: observation.boundingBox
                            )
                            recognizedLines.append(lineInfo)
                            totalConfidence += topCandidate.confidence
                            count += 1.0
                        }
                    }
                    
                    guard !recognizedLines.isEmpty else {
                        continuation.resume(throwing: OCRError.noTextDetected)
                        return
                    }
                    
                    // Ordena espacialmente as linhas e unifica o texto estruturado
                    let parseResult = parser.parse(lines: recognizedLines)
                    
                    guard !parseResult.words.isEmpty else {
                        continuation.resume(throwing: OCRError.noTextDetected)
                        return
                    }
                    
                    let averageConfidence = count > 0 ? (totalConfidence / count) : 0.0
                    let rawTextMerged = recognizedLines.map(\.text).joined(separator: "\n")
                    
                    let result = OCRResult(
                        rawText: rawTextMerged,
                        cleanedText: parseResult.cleanedText,
                        words: parseResult.words,
                        averageConfidence: averageConfidence,
                        lines: recognizedLines
                    )
                    
                    continuation.resume(returning: result)
                }
                
                // Configuração das propriedades avançadas do request
                request.recognitionLevel = recognitionLevel
                request.usesLanguageCorrection = usesLanguageCorrection
                request.recognitionLanguages = recognitionLanguages
                
                // Se suportado no runtime iOS, habilita detecção automática de idioma
                if #available(iOS 16.0, macOS 13.0, *) {
                    request.automaticallyDetectsLanguage = true
                }
                
                let handler = VNImageRequestHandler(
                    cgImage: cgImage,
                    orientation: orientation,
                    options: [:]
                )
                
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.recognitionFailed(reason: error.localizedDescription))
                }
            }
        }.value
    }
}
