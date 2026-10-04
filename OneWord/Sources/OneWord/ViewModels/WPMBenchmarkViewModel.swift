//
//  WPMBenchmarkViewModel.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import Observation

/// Pergunta de aferição de retenção e compreensão de leitura.
public struct BenchmarkQuestion: Identifiable, Sendable {
    public let id: Int
    public let text: String
    public let options: [String]
    public let correctIndex: Int
    
    public init(id: Int, text: String, options: [String], correctIndex: Int) {
        self.id = id
        self.text = text
        self.options = options
        self.correctIndex = correctIndex
    }
}

/// ViewModel para conduzir o Teste Interativo de Velocidade e Retenção Cognitiva.
@Observable
@MainActor
public final class WPMBenchmarkViewModel {
    public enum Stage {
        case intro
        case reading
        case questions
        case results
    }
    
    public var currentStage: Stage = .intro
    public var testWPM: Int = 350
    
    // Motor RSVP isolado para a leitura do benchmark
    public let engine: RSVPEngine
    
    // Texto padronizado de calibração foveal
    public static let benchmarkText = """
    A leitura tradicional impõe uma barreira biológica mecânica: os movimentos sacádicos dos olhos.
    A cada fração de segundo, os músculos oculares saltam de uma palavra para a outra, consumindo cerca de oitenta por cento do tempo total apenas reposicionando o foco na página.
    A técnica RSVP resolve essa limitação física ao projetar cada palavra diretamente sobre a fóvea central da retina, a região de máxima acuidade visual humana.
    Com a eliminação dos saltos sacádicos, a subvocalização involuntária diminui progressivamente e o córtex cerebral passa a sintetizar parágrafos inteiros com maior clareza e muito menor fadiga óptica.
    """
    
    public let questions: [BenchmarkQuestion] = [
        BenchmarkQuestion(
            id: 1,
            text: "O que são os movimentos sacádicos descritos no texto?",
            options: [
                "Saltos mecânicos dos olhos entre palavras na página",
                "Movimentos articulatórios dos lábios",
                "Contrações involuntárias das pálpebras"
            ],
            correctIndex: 0
        ),
        BenchmarkQuestion(
            id: 2,
            text: "Quanto do tempo total da leitura tradicional é consumido apenas reposicionando a visão?",
            options: [
                "Cerca de 20%",
                "Cerca de 80%",
                "Menos de 10%"
            ],
            correctIndex: 1
        ),
        BenchmarkQuestion(
            id: 3,
            text: "Por que a projeção foveal na retina é fundamental no RSVP?",
            options: [
                "Porque é a região anatômica de máxima acuidade visual",
                "Para evitar que a tela emita luz azul",
                "Para forçar o movimento constante do globo ocular"
            ],
            correctIndex: 0
        ),
        BenchmarkQuestion(
            id: 4,
            text: "Qual dos benefícios abaixo é diretamente citado no texto?",
            options: [
                "Diminuição da subvocalização e menor fadiga óptica",
                "Aumento obrigatório no esforço muscular",
                "Necessidade de piscar duas vezes mais"
            ],
            correctIndex: 0
        )
    ]
    
    public var selectedAnswers: [Int: Int] = [:]
    
    public init(initialWPM: Int = 350) {
        self.testWPM = initialWPM
        let words = Self.benchmarkText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let config = RSVPConfiguration(wpm: initialWPM, smartWPMEnabled: true)
        self.engine = RSVPEngine(config: config)
        self.engine.load(words: words)
        
        self.engine.onIndexChanged = { [weak self] index in
            guard let self else { return }
            if self.engine.isCompleted {
                self.currentStage = .questions
            }
        }
    }
    
    public func startReading() {
        engine.config.wpm = testWPM
        currentStage = .reading
        engine.play()
    }
    
    public func selectAnswer(questionId: Int, optionIndex: Int) {
        selectedAnswers[questionId] = optionIndex
    }
    
    public var isAllQuestionsAnswered: Bool {
        selectedAnswers.count == questions.count
    }
    
    public func finishBenchmark() {
        currentStage = .results
        ReadingHabitTracker.shared.recordBenchmarkResult(wpm: testWPM, scorePercentage: accuracyPercentage)
    }
    
    public var correctAnswersCount: Int {
        var count = 0
        for q in questions {
            if selectedAnswers[q.id] == q.correctIndex {
                count += 1
            }
        }
        return count
    }
    
    public var accuracyPercentage: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(correctAnswersCount) / Double(questions.count)
    }
    
    public var effectiveWPM: Int {
        Int(Double(testWPM) * accuracyPercentage)
    }
    
    public var readerClassification: (title: String, subtitle: String, color: String) {
        let eff = effectiveWPM
        if eff >= 450 {
            return ("Mestre do RSVP", "Velocidade e retenção em nível de alta performance.", "#10B981")
        } else if eff >= 300 {
            return ("Leitor Acelerado", "Ótima compreensão foveal com cadência acima da média.", "#3B82F6")
        } else if eff >= 200 {
            return ("Leitor Eficiente", "Ritmo consistente com excelente equilíbrio de assimilação.", "#8B5CF6")
        } else {
            return ("Em Calibração", "Foque na fixação confortável antes de acelerar o ritmo.", "#F59E0B")
        }
    }
}
