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
    @State private var chartMetric: ChartMetric = .words
    
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
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Hero Card: Tempo Economizado
                    heroTimeSavedCard
                    
                    // Grid de Métricas Secundárias
                    metricsGrid
                    
                    // Gráfico de Desempenho (Swift Charts)
                    performanceChartSection
                    
                    // Histórico Recente de Sessões
                    recentSessionsSection
                }
                .padding(.vertical)
            }
            .background(Color.statsBackground)
            .navigationTitle("Estatísticas")
        }
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
        let streak = viewModel.readingStreak(from: sessions)
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricCard(
                title: "Palavras",
                value: "\(totalWords)",
                icon: "character.book.closed.fill",
                accentColor: .blue
            )
            
            MetricCard(
                title: "WPM Médio",
                value: "\(avgWPM)",
                icon: "speedometer",
                accentColor: .orange
            )
            
            MetricCard(
                title: "Ofensiva",
                value: "\(streak) \(streak == 1 ? "dia" : "dias")",
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
                        Text(metric.rawValue).tag(metric)
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
                                Text(session.documentTitle.isEmpty ? "Sem Título" : session.documentTitle)
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
