//
//  PDFImportService.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import PDFKit

/// Serviço responsável por importar e extrair texto digital de arquivos PDF e TXT
/// armazenados no iCloud Drive ou na pasta Arquivos do iPhone.
public struct PDFImportService: Sendable {
    
    private let parser: TextParser
    
    public init(parser: TextParser = TextParser()) {
        self.parser = parser
    }
    
    /// Extrai o texto completo de um documento PDF através de uma URL de arquivo local.
    /// - Parameter url: Localização do arquivo no sistema de arquivos.
    /// - Returns: Tupla com título sugerido, texto higienizado e tokens de palavras para RSVP.
    /// - Throws: Erro caso o PDF esteja bloqueado, corrompido ou sem texto vetorial legível.
    public func extractText(from url: URL) throws -> (title: String, cleanedText: String, words: [String]) {
        guard let pdf = PDFDocument(url: url) else {
            throw OCRError.invalidImageData
        }
        
        var fullText = ""
        let pageCount = pdf.pageCount
        
        for i in 0..<pageCount {
            if let page = pdf.page(at: i), let pageString = page.string {
                fullText += pageString + "\n\n"
            }
        }
        
        guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OCRError.noTextDetected
        }
        
        let (cleaned, words) = parser.parse(rawText: fullText)
        
        // Tenta obter o título dos metadados do PDF ou do nome do arquivo
        var title = pdf.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        if title == nil || title?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            title = url.deletingPathExtension().lastPathComponent
        }
        
        return (title ?? "Documento PDF", cleaned, words)
    }
    
    /// Extrai texto de um arquivo de texto puro (.txt).
    /// - Parameter url: Caminho do arquivo .txt.
    /// - Returns: Título, texto limpo e tokens de palavras.
    public func extractTextFromTXT(at url: URL) throws -> (title: String, cleanedText: String, words: [String]) {
        let content = try String(contentsOf: url, encoding: .utf8)
        let (cleaned, words) = parser.parse(rawText: content)
        let title = url.deletingPathExtension().lastPathComponent
        return (title, cleaned, words)
    }
}
