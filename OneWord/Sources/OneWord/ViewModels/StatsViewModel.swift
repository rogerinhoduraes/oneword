//
//  StatsViewModel.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import SwiftUI
import Observation

/// Métrica diária agregada para exibição em gráficos com Swift Charts.
public struct DailyReadingMetric: Identifiable, Sendable {
    public var id: String { dayLabel }
    public let date: Date
    public let dayLabel: String
    public let words: Int
    public let minutesRead: Double
    public let timeSavedMinutes: Double
    public let averageWPM: Int
    
    public init(
        date: Date,
        dayLabel: String,
        words: Int,
        minutesRead: Double,
        timeSavedMinutes: Double,
        averageWPM: Int
    ) {
        self.date = date
        self.dayLabel = dayLabel
        self.words = words
        self.minutesRead = minutesRead
        self.timeSavedMinutes = timeSavedMinutes
        self.averageWPM = averageWPM
    }
}

/// ViewModel para a tela de métricas e produtividade de leitura do OneWord.
@Observable
@MainActor
public final class StatsViewModel {
    
    public enum Timeframe: String, CaseIterable, Identifiable {
        case week = "7 Dias"
        case month = "30 Dias"
        case all = "Tudo"
        
        public var id: String { rawValue }
    }
    
    public var selectedTimeframe: Timeframe = .week
    
    public init() {}
    
    // MARK: - Aggregations
    
    /// Total de palavras lidas no período selecionado.
    public func totalWords(from sessions: [ReadingSession]) -> Int {
        filteredSessions(sessions).reduce(0) { $0 + $1.wordsRead }
    }
    
    /// Tempo total de leitura no leitor RSVP (em minutos).
    public func totalMinutesRead(from sessions: [ReadingSession]) -> Double {
        let seconds = filteredSessions(sessions).reduce(0.0) { $0 + $1.durationSeconds }
        return seconds / 60.0
    }
    
    /// Total de tempo economizado em comparação à velocidade convencional (200 WPM) em minutos.
    public func totalMinutesSaved(from sessions: [ReadingSession]) -> Double {
        let seconds = filteredSessions(sessions).reduce(0.0) { $0 + $1.timeSavedSeconds }
        return seconds / 60.0
    }
    
    /// WPM médio ponderado de todas as sessões do período.
    public func averageWPM(from sessions: [ReadingSession]) -> Int {
        let filtered = filteredSessions(sessions)
        let totalWords = filtered.reduce(0) { $0 + $1.wordsRead }
        let totalSeconds = filtered.reduce(0.0) { $0 + $1.durationSeconds }
        guard totalSeconds > 0, totalWords > 0 else {
            return filtered.isEmpty ? 0 : filtered.reduce(0) { $0 + $1.averageWPM } / filtered.count
        }
        return Int((Double(totalWords) / totalSeconds) * 60.0)
    }
    
    /// Sequência atual de dias consecutivos de leitura (Streak).
    public func readingStreak(from sessions: [ReadingSession]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let uniqueDays = Set(sessions.map { calendar.startOfDay(for: $0.date) })
        guard !uniqueDays.isEmpty else { return 0 }
        
        var streak = 0
        var checkDate = uniqueDays.contains(today) ? today : calendar.date(byAdding: .day, value: -1, to: today)!
        
        while uniqueDays.contains(checkDate) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = previous
        }
        
        return streak
    }
    
    /// Agrega métricas diárias para alimentação do Swift Charts.
    public func dailyMetrics(from sessions: [ReadingSession]) -> [DailyReadingMetric] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let daysCount = (selectedTimeframe == .week) ? 7 : (selectedTimeframe == .month ? 30 : 14)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "pt_BR")
        dateFormatter.dateFormat = (daysCount <= 7) ? "EEE" : "dd/MM"
        
        var metrics: [DailyReadingMetric] = []
        
        for i in (0..<daysCount).reversed() {
            guard let targetDate = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let nextDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
            
            let daySessions = sessions.filter { $0.date >= targetDate && $0.date < nextDate }
            let dayWords = daySessions.reduce(0) { $0 + $1.wordsRead }
            let daySeconds = daySessions.reduce(0.0) { $0 + $1.durationSeconds }
            let daySaved = daySessions.reduce(0.0) { $0 + $1.timeSavedSeconds }
            let avgWPM = daySeconds > 0 ? Int((Double(dayWords) / daySeconds) * 60.0) : 0
            
            let label = dateFormatter.string(from: targetDate).capitalized
            
            metrics.append(DailyReadingMetric(
                date: targetDate,
                dayLabel: daysCount <= 7 ? "\(label) \(calendar.component(.day, from: targetDate))" : label,
                words: dayWords,
                minutesRead: daySeconds / 60.0,
                timeSavedMinutes: daySaved / 60.0,
                averageWPM: avgWPM
            ))
        }
        
        return metrics
    }
    
    // MARK: - Private Helpers
    
    private func filteredSessions(_ sessions: [ReadingSession]) -> [ReadingSession] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeframe {
        case .week:
            guard let startDate = calendar.date(byAdding: .day, value: -7, to: now) else { return sessions }
            return sessions.filter { $0.date >= startDate }
        case .month:
            guard let startDate = calendar.date(byAdding: .day, value: -30, to: now) else { return sessions }
            return sessions.filter { $0.date >= startDate }
        case .all:
            return sessions
        }
    }
}
