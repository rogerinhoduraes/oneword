//
//  QuickClipboardReaderView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI

/// Leitor RSVP minimalista otimizado para navegação por atalhos de teclado (macOS / iPad com Magic Keyboard).
public struct QuickClipboardReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var engine: RSVPEngine
    @State private var textInput: String
    
    public init(initialText: String = "") {
        let text = initialText.isEmpty ? "Selecione e copie qualquer texto para ler instantaneamente com foco total no OneWord." : initialText
        _textInput = State(initialValue: text)
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let config = RSVPConfiguration(wpm: 350, smartWPMEnabled: true)
        let rsvp = RSVPEngine(config: config)
        rsvp.load(words: words)
        _engine = State(initialValue: rsvp)
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Barra Superior
            HStack {
                Text("\(engine.config.wpm) WPM")
                    .font(.caption.bold().monospacedDigit())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
                
                Spacer()
                
                Button {
                    engine.pause()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
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
                
                let split = engine.currentSplitWord
                HStack(spacing: 0) {
                    Text(split.prefix)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    Text(String(split.focalCharacter))
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    Text(split.suffix)
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
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
            .contentShape(Rectangle())
            .onTapGesture {
                engine.togglePlayPause()
            }
            
            Spacer()
            
            // Guia de Atalhos de Teclado
            HStack(spacing: 16) {
                keyboardShortcutHint(key: "Espaço", action: engine.isPlaying ? "Pausar" : "Iniciar")
                keyboardShortcutHint(key: "← / →", action: "-10 / +10")
                keyboardShortcutHint(key: "↑ / ↓", action: "WPM")
            }
            .padding(.bottom, 14)
        }
        .frame(minWidth: 420, minHeight: 280)
        .background(Color(uiColorOrFallback: .systemBackground))
        #if os(macOS)
        .onKeyPress(.space) {
            engine.togglePlayPause()
            return .handled
        }
        .onKeyPress(.leftArrow) {
            engine.stepBackward(count: 10)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            engine.stepForward(count: 10)
            return .handled
        }
        .onKeyPress(.upArrow) {
            engine.setWPM(min(engine.config.wpm + 25, 1000))
            return .handled
        }
        .onKeyPress(.downArrow) {
            engine.setWPM(max(engine.config.wpm - 25, 100))
            return .handled
        }
        #endif
    }
    
    private func keyboardShortcutHint(key: String, action: String) -> some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.caption2.bold().monospaced())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(action)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
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
