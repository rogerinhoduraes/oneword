//
//  EPUBParser.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import Compression

/// Representação estruturada de um livro ePub descompactado e parseado.
public struct EPUBBook: Sendable {
    public let title: String
    public let author: String
    public let coverImageData: Data?
    public let chapters: [EPUBChapter]
    
    public init(
        title: String,
        author: String,
        coverImageData: Data? = nil,
        chapters: [EPUBChapter] = []
    ) {
        self.title = title
        self.author = author
        self.coverImageData = coverImageData
        self.chapters = chapters
    }
}

/// Capítulo ou seção extraída de um ePub.
public struct EPUBChapter: Identifiable, Sendable {
    public var id: String { href }
    public let title: String
    public let href: String
    public let textContent: String
    public let words: [String]
    
    public init(
        title: String,
        href: String,
        textContent: String,
        words: [String]
    ) {
        self.title = title
        self.href = href
        self.textContent = textContent
        self.words = words
    }
}

/// Parser nativo de arquivos ePub (especificações OCF 3.0 / OPS / OPF) em Swift 6 puro.
/// Lê o container ZIP, localiza o arquivo OPF, extrai metadados, ordem de leitura (spine) e texto dos capítulos.
public final class EPUBParser: Sendable {
    
    public init() {}
    
    /// Analisa os dados binários de um arquivo .epub e retorna o conteúdo do livro formatado.
    public func parse(data: Data) throws -> EPUBBook {
        let zipEntries = try unzipEntries(from: data)
        guard !zipEntries.isEmpty else {
            throw EPUBError.invalidArchive(String(localized: "Arquivo ePub vazio ou corrompido."))
        }
        
        // 1. Localiza META-INF/container.xml para descobrir o arquivo .opf
        let containerPath = "META-INF/container.xml"
        guard let containerData = zipEntries[containerPath] ?? zipEntries.first(where: { $0.key.lowercased() == containerPath.lowercased() })?.value else {
            throw EPUBError.missingContainerXML
        }
        
        guard let opfPath = extractOpfPath(from: containerData) else {
            throw EPUBError.missingOPFFile
        }
        
        // 2. Extrai e analisa o arquivo OPF
        let normalizedOpfPath = opfPath.replacingOccurrences(of: "\\", with: "/")
        guard let opfData = zipEntries[normalizedOpfPath] ?? zipEntries.first(where: { $0.key.lowercased() == normalizedOpfPath.lowercased() })?.value else {
            throw EPUBError.missingOPFFile
        }
        
        let opfDir = (normalizedOpfPath as NSString).deletingLastPathComponent
        let opfString = String(data: opfData, encoding: .utf8) ?? String(decoding: opfData, as: UTF8.self)
        
        let title = extractRegexValue(pattern: "<dc:title[^>]*>([^<]+)</dc:title>", from: opfString) ?? "Livro Digital"
        let author = extractRegexValue(pattern: "<dc:creator[^>]*>([^<]+)</dc:creator>", from: opfString) ?? String(localized: "Autor Desconhecido")
        
        // 3. Analisa Manifest e Spine
        let manifest = parseManifest(from: opfString)
        let spine = parseSpine(from: opfString)
        
        // 4. Extrai capa se houver
        var coverData: Data? = nil
        if let coverHref = findCoverHref(in: manifest, opfString: opfString) {
            let fullCoverPath = resolveRelativePath(baseDir: opfDir, href: coverHref)
            coverData = zipEntries[fullCoverPath] ?? zipEntries.first(where: { $0.key.lowercased() == fullCoverPath.lowercased() })?.value
        }
        
        // 5. Extrai capítulos na ordem do Spine
        var chapters: [EPUBChapter] = []
        for (index, idref) in spine.enumerated() {
            guard let item = manifest[idref] else { continue }
            let fullPath = resolveRelativePath(baseDir: opfDir, href: item.href)
            
            guard let chapterData = zipEntries[fullPath] ?? zipEntries.first(where: { $0.key.lowercased() == fullPath.lowercased() })?.value else {
                continue
            }
            
            let chapterHtml = String(data: chapterData, encoding: .utf8) ?? String(decoding: chapterData, as: UTF8.self)
            let chapterText = extractCleanText(fromHTML: chapterHtml)
            let words = chapterText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
            
            guard !words.isEmpty else { continue }
            
            let chapterTitle = extractChapterTitle(fromHTML: chapterHtml) ?? String(localized: "Capítulo \(index + 1)")
            
            chapters.append(EPUBChapter(
                title: chapterTitle,
                href: item.href,
                textContent: chapterText,
                words: words
            ))
        }
        
        // Se o spine não produziu capítulos (ou OPF atípico), tenta buscar arquivos .xhtml / .html do manifest
        if chapters.isEmpty {
            for (id, item) in manifest where item.mediaType.contains("html") || item.mediaType.contains("xhtml") {
                let fullPath = resolveRelativePath(baseDir: opfDir, href: item.href)
                guard let chapterData = zipEntries[fullPath] else { continue }
                let chapterHtml = String(data: chapterData, encoding: .utf8) ?? String(decoding: chapterData, as: UTF8.self)
                let chapterText = extractCleanText(fromHTML: chapterHtml)
                let words = chapterText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
                guard !words.isEmpty else { continue }
                
                chapters.append(EPUBChapter(
                    title: id,
                    href: item.href,
                    textContent: chapterText,
                    words: words
                ))
            }
        }
        
        return EPUBBook(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            author: author.trimmingCharacters(in: .whitespacesAndNewlines),
            coverImageData: coverData,
            chapters: chapters
        )
    }
    
    // MARK: - Auxiliares de Extração e Limpeza
    
    private func resolveRelativePath(baseDir: String, href: String) -> String {
        let cleanHref = href.components(separatedBy: "#").first ?? href
        if baseDir.isEmpty || baseDir == "." {
            return cleanHref
        }
        return "\(baseDir)/\(cleanHref)".replacingOccurrences(of: "//", with: "/")
    }
    
    private func extractOpfPath(from containerData: Data) -> String? {
        guard let xml = String(data: containerData, encoding: .utf8) ?? String(data: containerData, encoding: .isoLatin1) else {
            return nil
        }
        return extractRegexValue(pattern: "full-path=\"([^\"]+)\"", from: xml)
    }
    
    private struct ManifestItem {
        let href: String
        let mediaType: String
        let properties: String?
    }
    
    private func parseManifest(from opfString: String) -> [String: ManifestItem] {
        var result: [String: ManifestItem] = [:]
        
        let pattern = "<item\\s+[^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return result
        }
        
        let nsString = opfString as NSString
        let matches = regex.matches(in: opfString, range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let itemTag = nsString.substring(with: match.range)
            guard let id = extractAttribute("id", from: itemTag),
                  let href = extractAttribute("href", from: itemTag) else {
                continue
            }
            let mediaType = extractAttribute("media-type", from: itemTag) ?? ""
            let properties = extractAttribute("properties", from: itemTag)
            result[id] = ManifestItem(href: href, mediaType: mediaType, properties: properties)
        }
        
        return result
    }
    
    private func parseSpine(from opfString: String) -> [String] {
        var idrefs: [String] = []
        let pattern = "<itemref\\s+[^>]*idref=\"([^\"]+)\"[^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return idrefs
        }
        let nsString = opfString as NSString
        let matches = regex.matches(in: opfString, range: NSRange(location: 0, length: nsString.length))
        for match in matches {
            if match.numberOfRanges > 1 {
                let idref = nsString.substring(with: match.range(at: 1))
                idrefs.append(idref)
            }
        }
        return idrefs
    }
    
    private func findCoverHref(in manifest: [String: ManifestItem], opfString: String) -> String? {
        // 1. Manifest com property cover-image
        if let coverItem = manifest.values.first(where: { $0.properties?.contains("cover-image") == true }) {
            return coverItem.href
        }
        // 2. Item com id 'cover' ou 'cover-image'
        if let coverItem = manifest["cover-image"] ?? manifest["cover"] {
            return coverItem.href
        }
        // 3. Meta name="cover" content="id"
        if let metaCoverId = extractRegexValue(pattern: "<meta[^>]*name=\"cover\"[^>]*content=\"([^\"]+)\"", from: opfString),
           let item = manifest[metaCoverId] {
            return item.href
        }
        // 4. Qualquer imagem contendo cover no href
        if let imageItem = manifest.values.first(where: { ($0.mediaType.contains("image") && $0.href.lowercased().contains("cover")) }) {
            return imageItem.href
        }
        return nil
    }
    
    private func extractChapterTitle(fromHTML html: String) -> String? {
        if let title = extractRegexValue(pattern: "<title[^>]*>([^<]+)</title>", from: html) {
            let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        if let h1 = extractRegexValue(pattern: "<h1[^>]*>([^<]+)</h1>", from: html) {
            let trimmed = h1.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }
    
    public func extractCleanText(fromHTML html: String) -> String {
        var text = html
        // Remove tags de estilo, script, cabeçalhos HTML desnecessários
        text = text.replacingOccurrences(of: "<script[\\s\\S]*?</script>", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[\\s\\S]*?</style>", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "<!--[\\s\\S]*?-->", with: " ", options: .regularExpression)
        
        // Converte quebras de bloco em quebras de parágrafo
        text = text.replacingOccurrences(of: "</?(p|div|h[1-6]|li|tr|br)[^>]*>", with: "\n", options: .regularExpression)
        
        // Remove quaisquer tags remanescentes
        text = text.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        
        // Decodifica entidades HTML comuns
        text = decodeHTMLEntities(text)
        
        // Normaliza múltiplos espaços e quebras
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        return lines.joined(separator: "\n\n")
    }
    
    public func decodeHTMLEntities(_ string: String) -> String {
        var result = string
        let entities = [
            ("&nbsp;", " "),
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&apos;", "'"),
            ("&#39;", "'"),
            ("&mdash;", "—"),
            ("&ndash;", "–"),
            ("&hellip;", "…"),
            ("&ldquo;", "“"),
            ("&rdquo;", "”"),
            ("&lsquo;", "‘"),
            ("&rsquo;", "’"),
            ("&aacute;", "á"),
            ("&eacute;", "é"),
            ("&iacute;", "í"),
            ("&oacute;", "ó"),
            ("&uacute;", "ú"),
            ("&Aacute;", "Á"),
            ("&Eacute;", "É"),
            ("&Iacute;", "Í"),
            ("&Oacute;", "Ó"),
            ("&Uacute;", "Ú"),
            ("&atilde;", "ã"),
            ("&otilde;", "õ"),
            ("&Atilde;", "Ã"),
            ("&Otilde;", "Õ"),
            ("&acirc;", "â"),
            ("&ecirc;", "ê"),
            ("&ocirc;", "ô"),
            ("&Acirc;", "Â"),
            ("&Ecirc;", "Ê"),
            ("&Ocirc;", "Ô"),
            ("&ccedil;", "ç"),
            ("&Ccedil;", "Ç"),
            ("&agrave;", "à"),
            ("&Agrave;", "À")
        ]
        for (entity, char) in entities {
            result = result.replacingOccurrences(of: entity, with: char)
        }
        
        // Entidades numéricas hex/decimais básicas
        let decimalPattern = "&#([0-9]{1,5});"
        if let regex = try? NSRegularExpression(pattern: decimalPattern) {
            let ns = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: ns.length)).reversed()
            var mutable = result
            for match in matches {
                if let range = Range(match.range, in: mutable),
                   let code = Int(ns.substring(with: match.range(at: 1))),
                   let unicode = UnicodeScalar(code) {
                    mutable.replaceSubrange(range, with: String(Character(unicode)))
                }
            }
            result = mutable
        }
        
        return result
    }
    
    private func extractRegexValue(pattern: String, from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let ns = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)),
              match.numberOfRanges > 1 else {
            return nil
        }
        return ns.substring(with: match.range(at: 1))
    }
    
    private func extractAttribute(_ name: String, from tag: String) -> String? {
        let pattern = "\(name)=\"([^\"]+)\""
        return extractRegexValue(pattern: pattern, from: tag)
    }
    
    // MARK: - Leitor de Container ZIP em Swift Puro
    
    /// Descompacta as entradas do arquivo ZIP na memória.
    private func unzipEntries(from data: Data) throws -> [String: Data] {
        var entries: [String: Data] = [:]
        var offset = 0
        let count = data.count
        
        while offset + 30 <= count {
            // Assinatura do cabeçalho local do arquivo: 0x04034b50 ("PK\x03\x04")
            let sig = data.withUnsafeBytes { $0.load(fromByteOffset: offset, as: UInt32.self) }
            if sig != 0x04034b50 {
                // Chegou ao fim das entradas locais (início do Central Directory 0x02014b50)
                break
            }
            
            let compressionMethod = data.withUnsafeBytes { $0.load(fromByteOffset: offset + 8, as: UInt16.self) }
            let compressedSize = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset + 18, as: UInt32.self) })
            let uncompressedSize = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset + 22, as: UInt32.self) })
            let filenameLength = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset + 26, as: UInt16.self) })
            let extraLength = Int(data.withUnsafeBytes { $0.load(fromByteOffset: offset + 28, as: UInt16.self) })
            
            let headerSize = 30 + filenameLength + extraLength
            guard offset + headerSize <= count else { break }
            
            let filenameData = data.subdata(in: (offset + 30)..<(offset + 30 + filenameLength))
            let filename = String(data: filenameData, encoding: .utf8) ?? String(decoding: filenameData, as: UTF8.self)
            
            let fileDataOffset = offset + headerSize
            guard fileDataOffset + compressedSize <= count else { break }
            
            let fileCompressedData = data.subdata(in: fileDataOffset..<(fileDataOffset + compressedSize))
            
            var decompressedData: Data? = nil
            if compressionMethod == 0 {
                // Sem compressão (Stored)
                decompressedData = fileCompressedData
            } else if compressionMethod == 8 {
                // Deflate
                decompressedData = decompressDeflate(data: fileCompressedData, uncompressedSize: uncompressedSize)
            }
            
            if let decompressedData {
                entries[filename] = decompressedData
            }
            
            offset = fileDataOffset + compressedSize
        }
        
        return entries
    }
    
    private func decompressDeflate(data: Data, uncompressedSize: Int) -> Data? {
        guard uncompressedSize > 0 else { return Data() }
        var destination = [UInt8](repeating: 0, count: uncompressedSize)
        
        let decompressedCount = data.withUnsafeBytes { rawSource in
            destination.withUnsafeMutableBytes { rawDest in
                compression_decode_buffer(
                    rawDest.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    uncompressedSize,
                    rawSource.baseAddress!.assumingMemoryBound(to: UInt8.self),
                    data.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        
        if decompressedCount > 0 {
            return Data(destination.prefix(decompressedCount))
        }
        return nil
    }
}

/// Erros específicos de processamento de ePub.
public enum EPUBError: LocalizedError, Sendable {
    case invalidArchive(String)
    case missingContainerXML
    case missingOPFFile
    case noReadableChapters
    
    public var errorDescription: String? {
        switch self {
        case .invalidArchive(let msg):
            return String(localized: "Arquivo ePub inválido: \(msg)")
        case .missingContainerXML:
            return String(localized: "Estrutura ePub corrompida: META-INF/container.xml não encontrado.")
        case .missingOPFFile:
            return String(localized: "Arquivo de metadados (.opf) não encontrado no pacote ePub.")
        case .noReadableChapters:
            return String(localized: "Nenhum capítulo legível encontrado no livro digital.")
        }
    }
}
