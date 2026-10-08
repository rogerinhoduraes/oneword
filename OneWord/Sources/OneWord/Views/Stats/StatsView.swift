//
//  StatsView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
import SwiftData
import Charts
#if canImport(UIKit)
import UIKit
#endif

private extension Color {
    static var statsBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGroupedBackground)
        #else
        return Color(.windowBackgroundColor)
        #endif
    }
    
    static var statsCardBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #else
        return Color(.controlBackgroundColor)
        #endif
    }
}

/// Tela de Estatísticas e Produtividade de Leitura do OneWord.
/// Exibe métricas chave de eficiência, tempo economizado e evolução através do Swift Charts.
public struct StatsView: View {
    @Query(sort: \ReadingSession.date, order: .reverse) private var sessions: [ReadingSession]
    @State private var viewModel = StatsViewModel()
    @State private var habitTracker = ReadingHabitTracker.shared
    @State private var chartMetric: ChartMetric = .words
    @State private var isShowingBenchmark: Bool = false
    @State private var isShowingReadingGuide: Bool = false
    
    public enum ChartMetric: String, CaseIterable, Identifiable {
        case words = "Palavras"
        case timeSaved = "Tempo Economizado"
        
        public var id: String { rawValue }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Timeframe Picker
                    Picker("Período", selection: $viewModel.selectedTimeframe) {
                        ForEach(StatsViewModel.Timeframe.allCases) { timeframe in
                            Text(LocalizedStringKey(timeframe.rawValue)).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // 1. Ofensiva Diária (Streak) e Meta
                    streakAndHabitCard
                    
                    // 2. Card de Aferição de WPM e Compreensão Cognitiva
                    wpmBenchmarkCard
                    
                    // Card Educativo: Guia de Técnicas & Recursos
                    readingGuidePromoCard
                    
                    // 3. Hero Card: Tempo Economizado
                    heroTimeSavedCard
                    
                    // 4. Grid de Métricas Secundárias
                    metricsGrid
                    
                    // 5. Gráfico de Desempenho (Swift Charts)
                    performanceChartSection
                    
                    // 6. Conquistas & Medalhas Desbloqueáveis
                    achievementsSection
                    
                    // 7. Histórico Recente de Sessões
                    recentSessionsSection
                }
                .padding(.vertical)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .adBannerInset(unitID: AdConfig.statsBannerUnitID)
            .background(Color.statsBackground)
            .navigationTitle("Estatísticas")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isShowingReadingGuide = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .help("Guia: Técnicas de Leitura & Recursos")
                }
            }
            .sheet(isPresented: $isShowingBenchmark) {
                WPMBenchmarkView()
            }
            .sheet(isPresented: $isShowingReadingGuide) {
                ReadingGuideView()
            }
        }
    }
    
    // MARK: - 1. Ofensiva Diária (Streak) e Metas
    
    private var streakAndHabitCard: some View {
        let currentStreak = habitTracker.calculateStreak(from: sessions)
        let wordsToday = habitTracker.wordsReadToday(from: sessions)
        let goalProgress = habitTracker.dailyGoalProgress(from: sessions)
        
        return VStack(spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .font(.title2)
                    Text("\(currentStreak) \(currentStreak == 1 ? String(localized: "Dia") : String(localized: "Dias"))")
                        .font(.title2.bold())
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Recorde: \(habitTracker.bestStreak) dias")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Ofensiva de Foco")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                }
            }
            
            Divider()
            
            VStack(spacing: 8) {
                HStack {
                    Text("Meta Diária: \(wordsToday) / \(habitTracker.dailyWordGoal) palavras")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text("\(Int(goalProgress * 100))%")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(goalProgress >= 1.0 ? .green : .blue)
                }
                
                ProgressView(value: goalProgress)
                    .tint(goalProgress >= 1.0 ? .green : .blue)
            }
        }
        .padding(18)
        .background(Color.statsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
    }
    
    // MARK: - 2. Card de Aferição de WPM
    
    private var wpmBenchmarkCard: some View {
        let lastWPM = habitTracker.lastBenchmarkWPM
        let lastScore = habitTracker.lastBenchmarkScore
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Aferição de Velocidade & Retenção", systemImage: "brain.head.profile")
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
                
                Spacer()
                
                Button {
                    isShowingBenchmark = true
                } label: {
                    Text(lastWPM != nil ? String(localized: "Refazer Teste") : String(localized: "Iniciar Teste"))
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.purple.opacity(0.15))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                }
            }
            
            if let wpm = lastWPM, let score = lastScore {
                let effWPM = habitTracker.lastEffectiveWPM ?? Int(Double(wpm) * score)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(wpm)")
                                .font(.title3.bold().monospacedDigit())
                            Text("WPM Bruto")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(score * 100))%")
                                .font(.title3.bold().monospacedDigit())
                                .foregroundStyle(.purple)
                            Text("Retenção")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 3) {
                                Text("\(effWPM)")
                                    .font(.title3.bold().monospacedDigit())
                                    .foregroundStyle(.green)
                                Image(systemName: "bolt.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }
                            Text("eWPM Efetivo")
                                .font(.caption2.bold())
                                .foregroundStyle(.green)
                        }
                        
                        Spacer()
                    }
                    
                    Text("eWPM = Velocidade × Retenção. Métro neurocognitivo que elimina a ilusão de fluência.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Calibre sua velocidade ideal com um texto padronizado e teste de compreensão foveal para desbloquear seu eWPM.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color.statsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
    }
    
    // MARK: - Card Educativo do Guia
    
    private var readingGuidePromoCard: some View {
        Button {
            isShowingReadingGuide = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Guia de Técnicas & Recursos")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.primary)
                    
                    Text("Aprenda a neurociência do RSVP, ORP, Leitura Biônica e conheça todos os recursos do app.")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                        .lineLimit(2)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color.secondary)
            }
            .padding(14)
            .background(Color.statsCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.blue.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Hero Card
    
    private var heroTimeSavedCard: some View {
        let minutesSaved = viewModel.totalMinutesSaved(from: sessions)
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Tempo Economizado", systemImage: "bolt.badge.clock.fill")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white.opacity(0.85))
                
                Spacer()
                
                Text("vs. 200 WPM")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if minutesSaved >= 60 {
                    let hours = Int(minutesSaved) / 60
                    let mins = Int(minutesSaved) % 60
                    Text("\(hours)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("h")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.8))
                    Text("\(mins)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.leading, 8)
                    Text("min")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    Text(String(format: "%.1f", minutesSaved))
                        .font(.system(size: 46, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("minutos")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            
            Text("Você lê significativamente mais rápido sem cansaço visual graças à apresentação serial centralizada.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.blue, Color.indigo, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.blue.opacity(0.3), radius: 10, y: 5)
        .padding(.horizontal)
    }
    
    // MARK: - Metrics Grid
    
    private var metricsGrid: some View {
        let totalWords = viewModel.totalWords(from: sessions)
        let avgWPM = viewModel.averageWPM(from: sessions)
        let avgEffWPM = viewModel.averageEffectiveWPM(from: sessions)
        let streak = viewModel.readingStreak(from: sessions)
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: String(localized: "Palavras"),
                value: "\(totalWords)",
                icon: "character.book.closed.fill",
                accentColor: .blue
            )
            
            MetricCard(
                title: String(localized: "WPM Médio"),
                value: "\(avgWPM)",
                icon: "speedometer",
                accentColor: .orange
            )
            
            MetricCard(
                title: String(localized: "eWPM Efetivo"),
                value: "\(avgEffWPM)",
                icon: "brain.head.profile",
                accentColor: .purple
            )
            
            MetricCard(
                title: String(localized: "Ofensiva"),
                value: "\(streak) \(streak == 1 ? String(localized: "dia") : String(localized: "dias"))",
                icon: "flame.fill",
                accentColor: .red
            )
        }
        .padding(.horizontal)
    }
    
    // MARK: - Performance Chart
    
    private var performanceChartSection: some View {
        let metrics = viewModel.dailyMetrics(from: sessions)
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Evolução Diária")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Picker("Métrica", selection: $chartMetric) {
                    ForEach(ChartMetric.allCases) { metric in
                        Text(LocalizedStringKey(metric.rawValue)).tag(metric)
                    }
                }
                .pickerStyle(.menu)
                .font(.subheadline)
            }
            
            if metrics.allSatisfy({ $0.words == 0 }) {
                ContentUnavailableView(
                    "Sem leituras registradas no período",
                    systemImage: "chart.bar.xaxis",
                    description: Text("Leia documentos no leitor RSVP para visualizar seu gráfico de rendimento.")
                )
                .frame(height: 180)
            } else {
                Chart(metrics) { item in
                    if chartMetric == .words {
                        BarMark(
                            x: .value("Dia", item.dayLabel),
                            y: .value("Palavras", item.words)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(6)
                    } else {
                        BarMark(
                            x: .value("Dia", item.dayLabel),
                            y: .value("Minutos Economizados", item.timeSavedMinutes)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .indigo],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(6)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding(18)
        .background(Color.statsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal)
    }
    
    // MARK: - Conquistas e Medalhas
    
    private var achievementsSection: some View {
        let achievements = habitTracker.evaluateAchievements(sessions: sessions)
        let unlockedCount = achievements.filter { $0.isUnlocked }.count
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Conquistas & Foco", systemImage: "trophy.fill")
                    .font(.headline)
                    .foregroundStyle(.yellow)
                Spacer()
                Text("\(unlockedCount) de \(achievements.count) desbloqueadas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(achievements) { item in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(item.isUnlocked ? Color.yellow.opacity(0.18) : Color.secondary.opacity(0.1))
                                .frame(width: 42, height: 42)
                            
                            Image(systemName: item.iconName)
                                .font(.headline)
                                .foregroundStyle(item.isUnlocked ? .yellow : .secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(item.isUnlocked ? .primary : .secondary)
                                .lineLimit(1)
                            
                            Text(item.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.statsCardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(item.isUnlocked ? Color.yellow.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Recent Sessions
    
    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Últimas Leituras")
                .font(.headline)
                .padding(.horizontal)
            
            if sessions.isEmpty {
                VStack(spacing: 8) {
                    Text("Nenhuma sessão recente")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(sessions.prefix(5)) { session in
                        HStack(spacing: 12) {
                            Image(systemName: "book.pages.fill")
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .frame(width: 36, height: 36)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(session.documentTitle.isEmpty ? String(localized: "Sem Título") : session.documentTitle)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                
                                Text("\(session.wordsRead) palavras • \(session.date.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("\(session.averageWPM) WPM")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                
                                if session.timeSavedSeconds > 0 {
                                    Text("+\(Int(session.timeSavedSeconds))s eco")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.statsCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Subcomponents

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(accentColor)
                .padding(6)
                .background(accentColor.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.statsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview {
    StatsView()
        .modelContainer(ModelContainer.preview)
}
