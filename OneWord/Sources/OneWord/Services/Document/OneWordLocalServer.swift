//
//  OneWordLocalServer.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS/macOS
//

import Foundation
import Network
import SwiftData

/// Servidor HTTP local ultraleve e assíncrono (Network.framework) para conexão
/// direta em tempo real com a Extensão do Chrome em `http://127.0.0.1:8765`.
@MainActor
public final class OneWordLocalServer: ObservableObject {
    public static let shared = OneWordLocalServer()
    
    @Published public private(set) var isRunning: Bool = false
    public let defaultPort: UInt16 = 8765
    
    private var listener: NWListener?
    private var modelContext: ModelContext?
    
    /// Callback disparado na thread principal quando um documento é recebido da extensão
    public var onDocumentReceived: (@MainActor (Document) -> Void)?
    
    private init() {}
    
    /// Inicia o servidor local vinculado ao contexto de dados
    public func start(context: ModelContext, port: UInt16 = 8765) {
        guard !isRunning else { return }
        self.modelContext = context
        
        do {
            let parameters = NWParameters.tcp
            parameters.allowLocalEndpointReuse = true
            parameters.requiredInterfaceType = .loopback
            
            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                print("[OneWord LocalServer] Porta inválida: \(port)")
                return
            }
            
            let newListener = try NWListener(using: parameters, on: nwPort)
            self.listener = newListener
            
            newListener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in
                    switch state {
                    case .ready:
                        self?.isRunning = true
                        print("[OneWord LocalServer] Servidor ativo em http://127.0.0.1:\(port)")
                    case .failed(let error):
                        self?.isRunning = false
                        print("[OneWord LocalServer] Falha no listener: \(error.localizedDescription)")
                    case .cancelled:
                        self?.isRunning = false
                    default:
                        break
                    }
                }
            }
            
            newListener.newConnectionHandler = { [weak self] connection in
                self?.handleIncomingConnection(connection)
            }
            
            newListener.start(queue: .global(qos: .userInitiated))
        } catch {
            print("[OneWord LocalServer] Erro ao iniciar listener: \(error.localizedDescription)")
        }
    }
    
    /// Encerra o listener local
    public func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }
    
    // MARK: - Processamento de Conexões e Requisições HTTP
    
    private nonisolated static func successJSON(title: String) -> String {
        let object: [String: Any] = ["success": true, "title": title]
        let data = (try? JSONSerialization.data(withJSONObject: object)) ?? Data("{\"success\":true}".utf8)
        return String(decoding: data, as: UTF8.self)
    }
    
    /// Limite do corpo aceito (artigos longos cabem folgadamente).
    private nonisolated static let maxRequestBytes = 8 * 1024 * 1024
    
    /// Verdadeiro quando os cabeçalhos terminaram e o corpo declarado em `Content-Length` já chegou por inteiro.
    private nonisolated static func isRequestComplete(_ data: Data) -> Bool {
        guard let headerEnd = data.range(of: Data("\r\n\r\n".utf8)) else { return false }
        let headers = String(decoding: data[..<headerEnd.lowerBound], as: UTF8.self)
        var contentLength = 0
        for line in headers.components(separatedBy: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2, parts[0].trimmingCharacters(in: .whitespaces).lowercased() == "content-length" {
                contentLength = Int(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0
            }
        }
        return data.count - headerEnd.upperBound >= contentLength
    }
    
    /// Aceita apenas requisições sem `Origin` (curl, apps nativos) ou vindas de extensões do navegador;
    /// páginas web (http/https) não podem injetar documentos na biblioteca.
    private nonisolated static func allowedOrigin(in headerLines: [String]) -> (allowed: Bool, origin: String?) {
        for line in headerLines {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2, parts[0].lowercased() == "origin" {
                let origin = parts[1].trimmingCharacters(in: .whitespaces)
                let isExtension = origin.hasPrefix("chrome-extension://") || origin.hasPrefix("moz-extension://") || origin.hasPrefix("safari-web-extension://")
                return (isExtension, isExtension ? origin : nil)
            }
        }
        return (true, nil)
    }
    
    private nonisolated func handleIncomingConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        readNextChunk(connection: connection, accumulatedData: Data())
    }
    
    private nonisolated func readNextChunk(connection: NWConnection, accumulatedData: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            var data = accumulatedData
            if let content = content {
                data.append(content)
            }
            
            if data.count > Self.maxRequestBytes {
                self?.sendHTTPResponse(connection: connection, status: "413 Payload Too Large", body: "{\"error\":\"Payload Too Large\"}", origin: nil)
            } else if Self.isRequestComplete(data) || (isComplete && !data.isEmpty) {
                self?.processHTTPRequest(data: data, connection: connection)
            } else if error != nil || isComplete {
                connection.cancel()
            } else {
                self?.readNextChunk(connection: connection, accumulatedData: data)
            }
        }
    }
    
    private nonisolated func processHTTPRequest(data: Data, connection: NWConnection) {
        guard let requestString = String(data: data, encoding: .utf8) else {
            sendHTTPResponse(connection: connection, status: "400 Bad Request", body: "{\"error\":\"Invalid Encoding\"}", origin: nil)
            return
        }
        
        let lines = requestString.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            sendHTTPResponse(connection: connection, status: "400 Bad Request", body: "{\"error\":\"Missing Request Line\"}", origin: nil)
            return
        }
        
        let parts = requestLine.components(separatedBy: " ")
        guard parts.count >= 2 else {
            sendHTTPResponse(connection: connection, status: "400 Bad Request", body: "{\"error\":\"Malformed Request\"}", origin: nil)
            return
        }
        
        let method = parts[0].uppercased()
        let path = parts[1]
        
        let (originAllowed, origin) = Self.allowedOrigin(in: lines)
        guard originAllowed else {
            sendHTTPResponse(connection: connection, status: "403 Forbidden", body: "{\"error\":\"Origin not allowed\"}", origin: nil)
            return
        }
        
        // CORS Preflight
        if method == "OPTIONS" {
            sendHTTPResponse(connection: connection, status: "204 No Content", body: "", origin: origin)
            return
        }
        
        // Health Check
        if method == "GET" && (path == "/health" || path == "/status") {
            let json = "{\"status\":\"ok\",\"app\":\"OneWord\",\"version\":\"1.0.0\"}"
            sendHTTPResponse(connection: connection, status: "200 OK", body: json, origin: origin)
            return
        }
        
        // Recebe Texto / Artigo para Leitura Imediata
        if method == "POST" && (path == "/read" || path == "/import") {
            // Extrai o corpo JSON após "\r\n\r\n"
            guard let headerEndRange = data.range(of: Data("\r\n\r\n".utf8)) else {
                sendHTTPResponse(connection: connection, status: "400 Bad Request", body: "{\"error\":\"Missing Body\"}", origin: origin)
                return
            }
            
            let bodyData = data.subdata(in: headerEndRange.upperBound..<data.count)
            
            struct IncomingPayload: Decodable {
                let text: String?
                let title: String?
                let url: String?
            }
            
            do {
                let payload = try JSONDecoder().decode(IncomingPayload.self, from: bodyData)
                guard let rawText = payload.text, !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    sendHTTPResponse(connection: connection, status: "422 Unprocessable Entity", body: "{\"error\":\"Text is empty\"}", origin: origin)
                    return
                }
                
                let title = payload.title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                    ? payload.title!
                    : String(localized: "Artigo do Chrome")
                
                Task { @MainActor in
                    let parser = TextParser()
                    let (cleaned, words) = parser.parse(rawText: rawText)
                    
                    let document = Document(
                        title: title,
                        rawText: cleaned,
                        words: words
                    )
                    
                    if let ctx = self.modelContext {
                        ctx.insert(document)
                        try? ctx.save()
                    }
                    
                    self.onDocumentReceived?(document)
                }
                
                sendHTTPResponse(connection: connection, status: "200 OK", body: Self.successJSON(title: title), origin: origin)
            } catch {
                sendHTTPResponse(connection: connection, status: "400 Bad Request", body: "{\"error\":\"Invalid JSON payload: \(error.localizedDescription)\"}", origin: origin)
            }
            return
        }
        
        sendHTTPResponse(connection: connection, status: "404 Not Found", body: "{\"error\":\"Not Found\"}", origin: origin)
    }
    
    private nonisolated func sendHTTPResponse(connection: NWConnection, status: String, body: String, origin: String?) {
        let responseData = """
        HTTP/1.1 \(status)\r
        Content-Type: application/json; charset=utf-8\r
        Content-Length: \(body.utf8.count)\r
        Access-Control-Allow-Origin: \(origin ?? "null")\r
        Vary: Origin\r
        Access-Control-Allow-Methods: GET, POST, OPTIONS\r
        Access-Control-Allow-Headers: Content-Type, Authorization\r
        Connection: close\r
        \r
        \(body)
        """.data(using: .utf8) ?? Data()
        
        connection.send(content: responseData, completion: .contentProcessed({ _ in
            connection.cancel()
        }))
    }
}
