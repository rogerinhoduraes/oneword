//
//  DynamicQuizSheetView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI

/// Modal interativo de Questionário de Compreensão e Retenção gerado dinamicamente para o livro.
public struct DynamicQuizSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    public let title: String
    public let fullText: String
    
    @State private var questions: [BenchmarkQuestion] = []
    @State private var currentQuestionIndex: Int = 0
    @State private var selectedOptionIndex: Int? = nil
    @State private var isAnswerSubmitted: Bool = false
    @State private var correctAnswersCount: Int = 0
    @State private var isCompleted: Bool = false
    @State private var isLoading: Bool = true
    
    public init(title: String, fullText: String) {
        self.title = title
        self.fullText = fullText
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isLoading {
                    Spacer()
                    ProgressView("Extraindo perguntas com inteligência natural...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else if questions.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "questionmark.bubble")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Texto insuficiente para gerar perguntas.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else if isCompleted {
                    quizCompletedView
                } else {
                    quizQuestionView
                }
            }
            .padding()
            .navigationTitle("Teste de Retenção")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
            .onAppear {
                loadQuiz()
            }
        }
    }
    
    // MARK: - Pergunta Ativa
    
    private var quizQuestionView: some View {
        let question = questions[currentQuestionIndex]
        
        return VStack(alignment: .leading, spacing: 18) {
            // Barra de Progresso
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Questão \(currentQuestionIndex + 1) de \(questions.count)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(correctAnswersCount) acertos")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.green)
                }
                ProgressView(value: Double(currentQuestionIndex), total: Double(questions.count))
            }
            
            // Enunciado
            Text(question.text)
                .font(.body.weight(.medium))
                .lineSpacing(4)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            // Opções de Múltipla Escolha
            VStack(spacing: 10) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                    Button {
                        guard !isAnswerSubmitted else { return }
                        selectedOptionIndex = index
                    } label: {
                        HStack {
                            Text(option)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(optionTextColor(for: index, correctIndex: question.correctIndex))
                            
                            Spacer()
                            
                            if isAnswerSubmitted {
                                if index == question.correctIndex {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else if index == selectedOptionIndex {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            } else if selectedOptionIndex == index {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding()
                        .background(optionBackgroundColor(for: index, correctIndex: question.correctIndex))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(isAnswerSubmitted)
                }
            }
            
            Spacer()
            
            // Botão de Avanço / Confirmação
            if !isAnswerSubmitted {
                Button {
                    guard let selected = selectedOptionIndex else { return }
                    isAnswerSubmitted = true
                    if selected == question.correctIndex {
                        correctAnswersCount += 1
                        HapticEngine.shared.successMilestone()
                    } else {
                        HapticEngine.shared.pauseToggle()
                    }
                } label: {
                    Text("Confirmar Resposta")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedOptionIndex != nil ? Color.accentColor : Color.secondary.opacity(0.3))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(selectedOptionIndex == nil)
            } else {
                Button {
                    if currentQuestionIndex + 1 < questions.count {
                        currentQuestionIndex += 1
                        selectedOptionIndex = nil
                        isAnswerSubmitted = false
                    } else {
                        isCompleted = true
                    }
                } label: {
                    Text(currentQuestionIndex + 1 < questions.count ? "Próxima Pergunta" : "Ver Resultado")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
    
    // MARK: - Conclusão do Quiz
    
    private var quizCompletedView: some View {
        let percentage = Int((Double(correctAnswersCount) / Double(max(1, questions.count))) * 100)
        
        return VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: percentage >= 75 ? "star.circle.fill" : "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(percentage >= 75 ? .yellow : .blue)
            
            VStack(spacing: 8) {
                Text("Avaliação Concluída!")
                    .font(.title2.bold())
                
                Text("Você acertou \(correctAnswersCount) de \(questions.count) perguntas (\(percentage)%)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text(percentage >= 75 ? "Excelente retenção cognitiva! Sua taxa de fixação durante a leitura foi de alto nível." : "Bom treino de foco! A prática contínua de RSVP acelera a absorção natural de conceitos.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 12) {
                Button {
                    loadQuiz()
                } label: {
                    Label("Tentar Novamente", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.secondary.opacity(0.15))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                
                Button("Concluir") {
                    dismiss()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
    
    private func optionBackgroundColor(for index: Int, correctIndex: Int) -> Color {
        if isAnswerSubmitted {
            if index == correctIndex {
                return Color.green.opacity(0.18)
            } else if index == selectedOptionIndex {
                return Color.red.opacity(0.18)
            }
        } else if selectedOptionIndex == index {
            return Color.accentColor.opacity(0.15)
        }
        return Color.secondary.opacity(0.08)
    }
    
    private func optionTextColor(for index: Int, correctIndex: Int) -> Color {
        if isAnswerSubmitted {
            if index == correctIndex {
                return .green
            } else if index == selectedOptionIndex {
                return .red
            }
        }
        return .primary
    }
    
    private func loadQuiz() {
        isLoading = true
        isCompleted = false
        currentQuestionIndex = 0
        selectedOptionIndex = nil
        isAnswerSubmitted = false
        correctAnswersCount = 0
        
        Task {
            let service = DynamicQuizService()
            let generated = service.generateQuiz(from: fullText, title: title, count: 4)
            await MainActor.run {
                self.questions = generated
                self.isLoading = false
            }
        }
    }
}
