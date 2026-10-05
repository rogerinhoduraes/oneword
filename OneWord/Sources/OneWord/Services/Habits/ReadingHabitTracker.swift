//
//  ReadingHabitTracker.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import Observation

/// Gerenciador de hábitos de leitura, cálculo de ofensivas diárias (Streaks), metas e conquistas.
@Observable
@MainActor
public final class ReadingHabitTracker {
    public static let shared = ReadingHabitTracker()
    
    // MARK: - Chaves de Persistência
    private let kDailyWordGoal = "habit_daily_word_goal"
    private let kBestStreak = "habit_best_streak"
    private let kBenchmarkWPM = "habit_benchmark_wpm"
    private let kBenchmarkScore = "habit_benchmark_score"
    private let kBenchmarkDate = "habit_benchmark_date"
    private let kUnlockedAchievementIDs = "habit_unlocked_achievement_ids"
    
    public var dailyWordGoal: Int {
        didSet {
            UserDefaults.standard.set(dailyWordGoal, forKey: kDailyWordGoal)
        }
    }
    
    public var bestStreak: Int {
        didSet {
            UserDefaults.standard.set(bestStreak, forKey: kBestStreak)
        }
    }
    
    public init() {
        let storedGoal = UserDefaults.standard.integer(forKey: kDailyWordGoal)
        self.dailyWordGoal = storedGoal > 0 ? storedGoal : 2000
        self.bestStreak = UserDefaults.standard.integer(forKey: kBestStreak)
    }
    
    // MARK: - Cálculo de Ofensiva (Streak)
    
    /// Calcula a ofensiva atual (dias seguidos) a partir das datas das sessões de leitura.
    public func calculateStreak(from sessions: [ReadingSession]) -> Int {
        guard !sessions.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sessionDays = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
        let sortedDays = sessionDays.sorted(by: >)
        
        guard let mostRecentDay = sortedDays.first else { return 0 }
        
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Se a última sessão não foi nem hoje nem ontem, a ofensiva zerou
        if mostRecentDay < yesterday {
            return 0
        }
        
        var currentStreak = 0
        var checkDay = mostRecentDay
        
        for day in sortedDays {
            if day == checkDay {
                currentStreak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDay) else { break }
                checkDay = previousDay
            } else if day < checkDay {
                break
            }
        }
        
        if currentStreak > bestStreak {
            self.bestStreak = currentStreak
        }
        
        return currentStreak
    }
    
    /// Total de palavras lidas hoje.
    public func wordsReadToday(from sessions: [ReadingSession]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return sessions
            .filter { calendar.startOfDay(for: $0.startedAt) == today }
            .reduce(0) { $0 + $1.wordsRead }
    }
    
    /// Progresso normalizado da meta diária de palavras (0.0 a 1.0).
    public func dailyGoalProgress(from sessions: [ReadingSession]) -> Double {
        guard dailyWordGoal > 0 else { return 1.0 }
        let read = wordsReadToday(from: sessions)
        return min(max(Double(read) / Double(dailyWordGoal), 0.0), 1.0)
    }
    
    // MARK: - Benchmark Salvo
    
    public var lastBenchmarkWPM: Int? {
        let val = UserDefaults.standard.integer(forKey: kBenchmarkWPM)
        return val > 0 ? val : nil
    }
    
    public var lastBenchmarkScore: Double? {
        if UserDefaults.standard.object(forKey: kBenchmarkScore) != nil {
            return UserDefaults.standard.double(forKey: kBenchmarkScore)
        }
        return nil
    }
    
    /// WPM Efetivo (eWPM = WPM × Taxa de Retenção/Compreensão)
    public var lastEffectiveWPM: Int? {
        guard let wpm = lastBenchmarkWPM, let score = lastBenchmarkScore else { return nil }
        return Int(Double(wpm) * score)
    }
    
    public func recordBenchmarkResult(wpm: Int, scorePercentage: Double) {
        UserDefaults.standard.set(wpm, forKey: kBenchmarkWPM)
        UserDefaults.standard.set(scorePercentage, forKey: kBenchmarkScore)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: kBenchmarkDate)
    }
    
    // MARK: - Conquistas (Achievements)
    
    public func evaluateAchievements(sessions: [ReadingSession]) -> [Achievement] {
        var unlockedSet = Set(UserDefaults.standard.stringArray(forKey: kUnlockedAchievementIDs) ?? [])
        
        let streak = calculateStreak(from: sessions)
        let totalWords = sessions.reduce(0) { $0 + $1.wordsRead }
        let maxWPM = sessions.map { $0.wpm }.max() ?? 0
        let benchmarkScore = lastBenchmarkScore ?? 0.0
        
        let list: [Achievement] = [
            Achievement(
                id: "first_focus",
                title: "Primeiro Foco",
                subtitle: "Conclua a primeira sessão de leitura rápida.",
                iconName: "target",
                category: "Início",
                isUnlocked: !sessions.isEmpty,
                progress: sessions.isEmpty ? 0.0 : 1.0
            ),
            Achievement(
                id: "barrier_350",
                title: "Quebrando a Barreira",
                subtitle: "Leia em velocidade de 350 WPM ou superior.",
                iconName: "bolt.fill",
                category: "Velocidade",
                isUnlocked: maxWPM >= 350,
                progress: min(1.0, Double(maxWPM) / 350.0)
            ),
            Achievement(
                id: "hyper_speed_500",
                title: "Hiper-Velocidade",
                subtitle: "Domine a leitura a 500 WPM no RSVP.",
                iconName: "hare.fill",
                category: "Velocidade",
                isUnlocked: maxWPM >= 500,
                progress: min(1.0, Double(maxWPM) / 500.0)
            ),
            Achievement(
                id: "words_5k",
                title: "Devorador de Páginas",
                subtitle: "Leia mais de 5.000 palavras no OneWord.",
                iconName: "book.fill",
                category: "Volume",
                isUnlocked: totalWords >= 5000,
                progress: min(1.0, Double(totalWords) / 5000.0)
            ),
            Achievement(
                id: "words_20k",
                title: "Biblioteca Viva",
                subtitle: "Acumule 20.000 palavras lidas.",
                iconName: "books.vertical.fill",
                category: "Volume",
                isUnlocked: totalWords >= 20000,
                progress: min(1.0, Double(totalWords) / 20000.0)
            ),
            Achievement(
                id: "streak_3",
                title: "Chama Constante",
                subtitle: "Mantenha uma ofensiva de 3 dias consecutivos.",
                iconName: "flame.fill",
                category: "Hábito",
                isUnlocked: streak >= 3,
                progress: min(1.0, Double(streak) / 3.0)
            ),
            Achievement(
                id: "streak_7",
                title: "Mestre do Hábito",
                subtitle: "Mantenha uma ofensiva de 7 dias consecutivos.",
                iconName: "crown.fill",
                category: "Hábito",
                isUnlocked: streak >= 7,
                progress: min(1.0, Double(streak) / 7.0)
            ),
            Achievement(
                id: "perfect_retention",
                title: "Retenção Perfeita",
                subtitle: "Obtenha 100% de acertos no Teste de Compreensão.",
                iconName: "brain.head.profile",
                category: "Cognição",
                isUnlocked: benchmarkScore >= 0.99,
                progress: benchmarkScore
            )
        ]
        
        // Salva novas conquistas desbloqueadas
        for achievement in list where achievement.isUnlocked {
            unlockedSet.insert(achievement.id)
        }
        UserDefaults.standard.set(Array(unlockedSet), forKey: kUnlockedAchievementIDs)
        
        return list
    }
}
