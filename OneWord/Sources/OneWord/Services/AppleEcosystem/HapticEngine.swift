//
//  HapticEngine.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Motor de transdução háptica calibrado segundo os princípios do Apple Taptic Engine (LRA).
/// Fornece perfis de resposta tátil para modulação de WPM, quebra de parágrafos,
/// marcos de capítulo e celebração de ofensivas/streaks.
@MainActor
public final class HapticEngine: Sendable {
    public static let shared = HapticEngine()
    
    #if canImport(UIKit)
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    #endif
    
    public init() {
        #if canImport(UIKit)
        lightImpact.prepare()
        selectionFeedback.prepare()
        #endif
    }
    
    /// Micro-pulso sutil para transição de parágrafo ou final de sentença (acoplamento transitório).
    public func tickWordBoundary() {
        #if canImport(UIKit)
        lightImpact.impactOccurred(intensity: 0.6)
        #endif
    }
    
    /// Clique mecânico calibrado para alteração de velocidade (slider ou stepper de WPM).
    public func tickSpeedChange() {
        #if canImport(UIKit)
        selectionFeedback.selectionChanged()
        #endif
    }
    
    /// Impulso ressonante de transição de página física ou capítulo concluído.
    public func milestonePageCompleted() {
        #if canImport(UIKit)
        mediumImpact.impactOccurred()
        #endif
    }
    
    /// Notificação de sucesso para conclusão integral de livro ou documento.
    public func celebrationCompleted() {
        #if canImport(UIKit)
        notificationFeedback.notificationOccurred(.success)
        #endif
    }
    
    /// Padrão duplo de impacto para desbloqueio de novas conquistas e metas de ofensiva diária.
    public func celebrationStreakUnlocked() {
        #if canImport(UIKit)
        heavyImpact.impactOccurred()
        Task {
            try? await Task.sleep(nanoseconds: 120_000_000)
            await MainActor.run {
                self.notificationFeedback.notificationOccurred(.success)
            }
        }
        #endif
    }
    
    /// Feedback de advertência (ex: velocidade máxima ou início de documento).
    public func boundaryWarning() {
        #if canImport(UIKit)
        notificationFeedback.notificationOccurred(.warning)
        #endif
    }
}
