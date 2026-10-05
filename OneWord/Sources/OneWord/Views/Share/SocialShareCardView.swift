//
//  SocialShareCardView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI

/// Cartão visual de conquista de leitura formatado para compartilhamento em redes sociais (Instagram Stories / X).
public struct SocialShareCardView: View {
    @Environment(\.dismiss) private var dismiss
    
    public let documentTitle: String
    public let wordsRead: Int
    public let averageWPM: Int
    public let timeSavedMinutes: Double
    
    public init(
        documentTitle: String,
        wordsRead: Int,
        averageWPM: Int,
        timeSavedMinutes: Double
    ) {
        self.documentTitle = documentTitle
        self.wordsRead = wordsRead
        self.averageWPM = averageWPM
        self.timeSavedMinutes = timeSavedMinutes
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                shareCard
                    .padding(.horizontal, 20)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                
                Spacer()
                
                #if os(iOS)
                ShareLink(
                    item: shareCardText,
                    preview: SharePreview(documentTitle, image: Image(systemName: "bolt.fill"))
                ) {
                    Label("Compartilhar Conquista", systemImage: "square.and.arrow.up.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                #endif
                
                Button("Concluir") {
                    dismiss()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)
            }
            .background(Color(uiColorOrFallback: .systemBackground))
            .navigationTitle("Compartilhar Foco")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }
    
    private var shareCardText: String {
        "Acabei de ler \(wordsRead) palavras a \(averageWPM) WPM no @OneWordApp e economizei \(Int(max(1, timeSavedMinutes))) minutos com leitura rápida foveal! 🚀📖"
    }
    
    // MARK: - Cartão Gráfico
    
    private var shareCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Top Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("OneWord")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                Text("RSVP Speed Reader")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.2))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("CONCLUÍDO HOJE")
                    .font(.caption2.bold())
                    .foregroundStyle(.white.opacity(0.7))
                Text(documentTitle)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(.top, 10)
            
            Divider()
                .overlay(.white.opacity(0.2))
            
            // Grid de Métricas
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(averageWPM)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Palavras / min (WPM)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(wordsRead)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Total de Palavras")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            // Banner de Tempo Economizado
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.yellow)
                Text(String(format: "+%.0f minutos economizados", max(1, timeSavedMinutes)))
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.white.opacity(0.15))
            .clipShape(Capsule())
            .padding(.top, 6)
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [Color(hex: "#1E3A8A"), Color(hex: "#0F172A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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
