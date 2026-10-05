//
//  WPMBenchmarkView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI

/// Modal interativo para o Teste de Aferição de WPM e Compreensão de Leitura.
public struct WPMBenchmarkView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = WPMBenchmarkViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColorOrFallback: .systemBackground)
                    .ignoresSafeArea()
                
                switch viewModel.currentStage {
                case .intro:
                    introStageView
                case .reading:
                    readingStageView
                case .questions:
                    questionsStageView
                case .results:
                    resultsStageView
                }
            }
            .navigationTitle("Aferição de Velocidade")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        viewModel.engine.pause()
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - 1. Etapa de Introdução
    
    private var introStageView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "gauge.with.needle.fill")
                    .font(.system(size: 46))
                    .foregroundStyle(.blue)
            }
            
            VStack(spacing: 8) {
                Text("Teste de Aferição Foveal")
                    .font(.title2.bold())
                
                Text("Avalie sua velocidade em WPM e retenção real de conteúdo através de um texto científico calibrado.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Velocidade Inicial do Teste")
                        .font(.headline)
                    Spacer()
                    Text("\(viewModel.testWPM) WPM")
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(.blue)
                }
                
                Slider(value: Binding(
                    get: { Double(viewModel.testWPM) },
                    set: { viewModel.testWPM = Int($0) }
                ), in: 200...600, step: 25)
                
                HStack {
                    Text("200 WPM (Confortável)")
                    Spacer()
                    Text("600 WPM (Avançado)")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button {
                viewModel.startReading()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Iniciar Teste")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - 2. Etapa de Leitura RSVP
    
    private var readingStageView: some View {
        VStack(spacing: 30) {
            HStack {
                Text("Leia com atenção foveal máxima:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.testWPM) WPM")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            ProgressView(value: viewModel.engine.progress)
                .padding(.horizontal, 24)
            
            Spacer()
            
            // Display Central RSVP com ORP
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 1)
                    Rectangle()
                        .fill(Color.red.opacity(0.85))
                        .frame(width: 3, height: 12)
                        .clipShape(Capsule())
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 1)
                }
                .frame(maxWidth: .infinity)
                
                let split = viewModel.engine.currentSplitWord
                HStack(spacing: 0) {
                    Text(split.prefix)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    Text(String(split.focalCharacter))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text(split.suffix)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .frame(height: 80)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 1)
                    Rectangle()
                        .fill(Color.red.opacity(0.85))
                        .frame(width: 3, height: 12)
                        .clipShape(Capsule())
                    Rectangle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 1)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.secondary.opacity(0.04))
            )
            
            Spacer()
            
            Text("O teste avançará para as perguntas automaticamente ao término do texto.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
    }
    
    // MARK: - 3. Etapa de Perguntas de Compreensão
    
    private var questionsStageView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Perguntas de Retenção")
                    .font(.title3.bold())
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                ForEach(viewModel.questions) { question in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(question.id). \(question.text)")
                            .font(.subheadline.weight(.semibold))
                        
                        ForEach(0..<question.options.count, id: \.self) { idx in
                            let isSelected = viewModel.selectedAnswers[question.id] == idx
                            Button {
                                viewModel.selectAnswer(questionId: question.id, optionIndex: idx)
                            } label: {
                                HStack {
                                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                                        .foregroundStyle(isSelected ? .blue : .secondary)
                                    Text(question.options[idx])
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(isSelected ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                }
                
                Button {
                    viewModel.finishBenchmark()
                } label: {
                    Text("Ver Resultado e Diagnóstico")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(viewModel.isAllQuestionsAnswered ? Color.blue : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!viewModel.isAllQuestionsAnswered)
                .padding(.horizontal)
                .padding(.vertical, 16)
            }
        }
    }
    
    // MARK: - 4. Etapa de Resultados
    
    private var resultsStageView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            let classif = viewModel.readerClassification
            
            ZStack {
                Circle()
                    .fill(Color(hex: classif.color).opacity(0.15))
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: classif.color))
            }
            
            VStack(spacing: 4) {
                Text(classif.title)
                    .font(.title.bold())
                Text(classif.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // Cards de Métricas
            HStack(spacing: 12) {
                metricBox(
                    title: String(localized: "WPM Testado"),
                    value: "\(viewModel.testWPM)",
                    icon: "speedometer",
                    tint: .blue
                )
                
                metricBox(
                    title: String(localized: "Compreensão"),
                    value: "\(Int(viewModel.accuracyPercentage * 100))%",
                    icon: "brain.head.profile",
                    tint: .purple
                )
                
                metricBox(
                    title: String(localized: "WPM Efetivo"),
                    value: "\(viewModel.effectiveWPM)",
                    icon: "bolt.fill",
                    tint: .green
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    UserDefaults.standard.set(max(200, viewModel.effectiveWPM), forKey: "default_wpm")
                    dismiss()
                } label: {
                    Text("Aplicar WPM Recomendado (\(viewModel.effectiveWPM) WPM)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                Button("Concluir") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private func metricBox(title: String, value: String, icon: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private extension Color {
    init(uiColorOrFallback: UIColorType) {
        #if canImport(UIKit)
        switch uiColorOrFallback {
        case .systemBackground:
            self.init(uiColor: .systemBackground)
        }
        #else
        self.init(.windowBackgroundColor)
        #endif
    }
    
    enum UIColorType {
        case systemBackground
    }
}
