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
        
        return (title(for: url), cleaned, words)
    }
    
    /// Título dos metadados do PDF, com fallback para o nome do arquivo.
    public func title(for url: URL) -> String {
        let metadata = PDFDocument(url: url)?.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String
        if let metadata, !metadata.trimmingCharacters(in: .whitespaces).isEmpty {
            return metadata
        }
        let fileName = url.deletingPathExtension().lastPathComponent
        return fileName.isEmpty ? String(localized: "Documento PDF") : fileName
    }
    
    /// Extrai o texto de cada página individualmente para alimentar livros multi-páginas.
    /// - Parameter url: Localização do arquivo PDF.
    /// - Returns: Lista de tuplas contendo o texto limpo e o array de palavras de cada página.
    public func extractPages(from url: URL) throws -> [(text: String, words: [String])] {
        guard let pdf = PDFDocument(url: url) else {
            throw OCRError.invalidImageData
        }
        
        var pages: [(text: String, words: [String])] = []
        for i in 0..<pdf.pageCount {
            if let page = pdf.page(at: i), let raw = page.string {
                let (cleaned, words) = parser.parse(rawText: raw)
                if !words.isEmpty {
                    pages.append((cleaned, words))
                }
            }
        }
        
        guard !pages.isEmpty else {
            throw OCRError.noTextDetected
        }
        
        return pages
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
