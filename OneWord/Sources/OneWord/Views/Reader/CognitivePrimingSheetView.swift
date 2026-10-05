//
//  CognitivePrimingSheetView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

private extension Color {
    static var primingBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGroupedBackground)
        #else
        return Color(.windowBackgroundColor)
        #endif
    }
    
    static var primingCardBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #else
        return Color(.controlBackgroundColor)
        #endif
    }
}

/// Modal de Priming Neurocognitivo (Pré-leitura Ativa).
/// Ativa esquemas conceituais no córtex pré-frontal e temporal anterior antes do fluxo foveal no RSVP,
/// orientando a atenção seletiva e amplificando a retenção de longo prazo.
public struct CognitivePrimingSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    public let context: CognitivePrimingContext
    public let onStartReading: () -> Void
    
    public init(
        context: CognitivePrimingContext,
        onStartReading: @escaping () -> Void
    ) {
        self.context = context
        self.onStartReading = onStartReading
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Visual
                    headerSection
                    
                    // Card 1: Pergunta Norteadora (Pre-questioning Effect)
                    focusQuestionCard
                    
                    // Card 2: Conceitos-Âncora (Ativação Semântica)
                    if !context.anchorConcepts.isEmpty {
                        anchorConceptsCard
                    }
                    
                    // Card 3: Visão Panorâmica Rápida
                    keyInsightsCard
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(Color.primingBackground)
            .navigationTitle("Ativação Cognitiva")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Pular") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .safeAreaInset(edge: .bottom) {
                actionFooter
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 70, height: 70)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36))
                    .foregroundStyle(.purple)
            }
            
            Text(context.title)
                .font(.headline)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text("Pré-ativação de esquemas mentais baseada em neurociência cognitiva para maximizar a retenção no RSVP.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Pergunta Norteadora
    
    private var focusQuestionCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "target")
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
                Text("Pergunta-Gatilho de Atenção")
                    .font(.subheadline.bold())
                    .foregroundStyle(.purple)
            }
            
            Text(context.focusQuestion)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Seu cérebro filtrará e fixará as palavras do RSVP em busca desta resposta.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.primingCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Conceitos-Âncora
    
    private var anchorConceptsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
                Text("Conceitos-Âncora")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
            }
            
            FlowLayout(spacing: 8) {
                ForEach(context.anchorConcepts, id: \.self) { concept in
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                        Text(concept)
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.primingCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Visão Panorâmica
    
    private var keyInsightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.rectangle.portrait.fill")
                    .font(.subheadline.bold())
                    .foregroundStyle(.indigo)
                Text("Visão Panorâmica (30 seg)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.indigo)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(context.keyInsights.enumerated()), id: \.offset) { index, insight in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.indigo)
                            .clipShape(Circle())
                        
                        Text(insight)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.primingCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    // MARK: - Rodapé de Ação
    
    private var actionFooter: some View {
        VStack(spacing: 8) {
            Button {
                dismiss()
                onStartReading()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                    Text("Iniciar Leitura Focada")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Color.purple.opacity(0.3), radius: 8, y: 4)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}
