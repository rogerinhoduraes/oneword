//
//  ReadingSession.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftData

/// Registra uma sessão de leitura concluída ou parcial no OneWord.
/// Alimenta a telemetria, gráficos de produtividade no Swift Charts e cálculo de tempo economizado.
@Model
public final class ReadingSession {
    /// Identificador único universal da sessão.
    public var id: UUID
    
    /// Data e hora em que a sessão ocorreu.
    public var date: Date
    
    /// Duração da sessão em segundos.
    public var durationSeconds: Double
    
    /// Quantidade de palavras lidas durante esta sessão.
    public var wordsRead: Int
    
    /// Velocidade média de leitura em WPM atingida na sessão.
    public var averageWPM: Int
    
    /// Título do documento lido.
    public var documentTitle: String
    
    /// Documento associado opcional.
    public var document: Document?
    
    /// Livro associado opcional.
    public var book: Book?
    
    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        durationSeconds: Double = 0.0,
        wordsRead: Int = 0,
        averageWPM: Int = 300,
        documentTitle: String = "",
        document: Document? = nil,
        book: Book? = nil
    ) {
        self.id = id
        self.date = date
        self.durationSeconds = durationSeconds
        self.wordsRead = wordsRead
        self.averageWPM = averageWPM
        self.documentTitle = documentTitle
        self.document = document
        self.book = book
    }
    
    /// Tempo que uma pessoa média (lendo a 200 WPM) levaria para ler essas mesmas palavras.
    public var baselineDurationSeconds: Double {
        let baselineWPM = 200.0
        return (Double(wordsRead) / baselineWPM) * 60.0
    }
    
    /// Tempo economizado em segundos nesta sessão graças ao método RSVP.
    public var timeSavedSeconds: Double {
        max(0.0, baselineDurationSeconds - durationSeconds)
    }
}
