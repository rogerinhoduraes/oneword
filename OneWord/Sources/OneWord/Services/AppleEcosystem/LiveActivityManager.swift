//
//  LiveActivityManager.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
#if canImport(ActivityKit) && os(iOS)
import ActivityKit
#endif

/// Gerenciador unificado de Live Activities para projeção na tela de bloqueio e Dynamic Island.
@MainActor
public final class LiveActivityManager: Sendable {
    public static let shared = LiveActivityManager()
    
    #if canImport(ActivityKit) && os(iOS)
    private var currentActivity: Activity<OneWordReadingActivityAttributes>?
    #endif
    
    public init() {}
    
    /// Inicia uma nova Live Activity com o livro/documento atual.
    public func startSession(
        title: String,
        author: String? = nil,
        currentWord: String,
        wordsRead: Int,
        totalWords: Int,
        remainingMinutes: Double,
        wpm: Int,
        isPlaying: Bool
    ) {
        #if canImport(ActivityKit) && os(iOS)
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        // Finaliza sessão anterior se houver
        endSession()
        
        let attributes = OneWordReadingActivityAttributes(title: title, author: author)
        let state = OneWordReadingActivityAttributes.ContentState(
            currentWord: currentWord,
            wordsRead: wordsRead,
            totalWords: totalWords,
            remainingMinutes: remainingMinutes,
            wpm: wpm,
            isPlaying: isPlaying
        )
        
        do {
            let activity = try Activity<OneWordReadingActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil)
            )
            self.currentActivity = activity
        } catch {
            // Silencioso se indisponível no ambiente
        }
        #endif
    }
    
    /// Atualiza o estado da Live Activity e da Ilha Dinâmica.
    public func updateSession(
        currentWord: String,
        wordsRead: Int,
        totalWords: Int,
        remainingMinutes: Double,
        wpm: Int,
        isPlaying: Bool
    ) {
        #if canImport(ActivityKit) && os(iOS)
        guard let activity = currentActivity else { return }
        let state = OneWordReadingActivityAttributes.ContentState(
            currentWord: currentWord,
            wordsRead: wordsRead,
            totalWords: totalWords,
            remainingMinutes: remainingMinutes,
            wpm: wpm,
            isPlaying: isPlaying
        )
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
        #endif
    }
    
    /// Encerra a Live Activity ao terminar ou fechar a tela de leitura.
    public func endSession() {
        #if canImport(ActivityKit) && os(iOS)
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.currentActivity = nil
        #endif
    }
}
