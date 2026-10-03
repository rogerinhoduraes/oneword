//
//  RSVPEngineProtocol.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation

/// Estados operacionais da máquina de estados do leitor RSVP.
public enum RSVPPlaybackState: Sendable, Equatable {
    /// O leitor está parado no início ou sem conteúdo carregado.
    case idle
    /// A reprodução sequencial de palavras está ativa em tempo real.
    case playing
    /// A leitura foi pausada manualmente pelo usuário.
    case paused
    /// O motor atingiu a última palavra do documento.
    case completed
}

/// Contrato formal para motores de apresentação serial rápida (RSVP).
@MainActor
public protocol RSVPEngineProtocol: AnyObject {
    var state: RSVPPlaybackState { get }
    var words: [String] { get }
    var currentIndex: Int { get }
    var currentWord: String { get }
    var config: RSVPConfiguration { get set }
    var isPlaying: Bool { get }
    var isCompleted: Bool { get }
    var progress: Double { get }
    
    func load(words: [String], initialIndex: Int)
    func play()
    func pause()
    func togglePlayPause()
    func seek(to index: Int)
    func stepForward(count: Int)
    func stepBackward(count: Int)
    func advanceSentence()
    func rewindSentence()
    func reset()
}
