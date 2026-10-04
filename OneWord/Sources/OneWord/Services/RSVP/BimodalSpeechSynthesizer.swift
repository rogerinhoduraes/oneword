//
//  BimodalSpeechSynthesizer.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import Foundation
import AVFoundation

/// Gerenciador de síntese de voz para o Modo Bimodal (áudio-assistido) do leitor RSVP.
/// Sincroniza a reprodução fônica com a velocidade de apresentação visual, aumentando a retenção.
@MainActor
public final class BimodalSpeechSynthesizer: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    public private(set) var isSpeaking: Bool = false
    public private(set) var isPaused: Bool = false
    
    public override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .spokenAudio, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Silencioso se indisponível em simulador ou preview
        }
        #endif
    }
    
    /// Pronuncia uma palavra ou sentença respeitando o ritmo WPM desejado.
    /// - Parameters:
    ///   - text: Texto a ser falado.
    ///   - languageCode: Código de idioma BCP-47 (padrão: "pt-BR").
    ///   - wpm: Velocidade alvo do leitor.
    public func speak(text: String, languageCode: String = "pt-BR", wpm: Int = 300) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: trimmed)
        
        // Calibra a taxa do AVSpeechUtterance (faixa 0.0 a 1.0; 0.5 costuma ser ~180-200 WPM)
        let normalizedRate = Float(wpm) / 600.0
        utterance.rate = min(max(normalizedRate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
        utterance.pitchMultiplier = 1.0
        utterance.volume = 0.95
        
        // Seleciona voz do idioma solicitado ou fallback para voz nativa brasileira
        if let voice = AVSpeechSynthesisVoice(language: languageCode) {
            utterance.voice = voice
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: "pt-BR")
        }
        
        isSpeaking = true
        isPaused = false
        synthesizer.speak(utterance)
    }
    
    /// Pausa a fala corrente.
    public func pause() {
        if synthesizer.isSpeaking && !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: .immediate)
            isPaused = true
        }
    }
    
    /// Retoma a fala pausada.
    public func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPaused = false
        }
    }
    
    /// Interrompe a fala imediatamente.
    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        isPaused = false
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
        }
    }
    
    public nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
        }
    }
}
