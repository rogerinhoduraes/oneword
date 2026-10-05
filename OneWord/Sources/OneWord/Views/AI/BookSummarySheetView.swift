//
//  BookSummarySheetView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
import SwiftData

/// Modal com Resumo Executivo gerado por IA no dispositivo.
/// Condensa os pontos principais do texto com métricas de tempo economizado e leitura RSVP direta.
public struct BookSummarySheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    public let title: String
    public let fullText: String
    
    @State private var summaryBulletPoints: [String] = []
    @State private var isSummarizing: Bool = true
    @State private var isShowingSummaryReader: Bool = false
    @State private var summaryDocument: Document?
    
    public init(title: String, fullText: String) {
        self.title = title
        self.fullText = fullText
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isSummarizing {
                    Spacer()
                    ProgressView("Processando inteligência de texto...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                } else if summaryBulletPoints.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Texto insuficiente para gerar um resumo.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                } else {
                    summaryContent
                }
            }
            .padding()
            .navigationTitle("Resumo Executivo (IA)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
            .onAppear {
                generateSummary()
            }
            #if os(iOS)
            .fullScreenCover(isPresented: $isShowingSummaryReader) {
                if let doc = summaryDocument {
                    RSVPReaderView(document: doc, modelContext: modelContext)
                }
            }
            #else
            .sheet(isPresented: $isShowingSummaryReader) {
                if let doc = summaryDocument {
                    RSVPReaderView(document: doc, modelContext: modelContext)
                }
            }
            #endif
        }
    }
    
    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header com Métricas
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Condensado em \(summaryBulletPoints.count) Pontos-Chave")
                        .font(.headline)
                    Text("Economia estimada de ~75% a 85% do tempo de leitura")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.purple.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            
            // Lista de Tópicos do Resumo
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(summaryBulletPoints.enumerated()), id: \.offset) { index, point in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Color.purple)
                                .clipShape(Circle())
                            
                            Text(point)
                                .font(.subheadline)
                                .lineSpacing(4)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Botão de Leitura Rápida RSVP do Resumo
            Button {
                let joinedSummary = summaryBulletPoints.joined(separator: " ")
                let doc = Document(title: "Resumo: \(title)", rawText: joinedSummary)
                self.summaryDocument = doc
                self.isShowingSummaryReader = true
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Ler Resumo no Leitor RSVP")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
    
    private func generateSummary() {
        Task {
            let summarizer = TextSummarizerService.shared
            let points = summarizer.summarize(text: fullText, maxSentences: 5)
            await MainActor.run {
                self.summaryBulletPoints = points
                self.isSummarizing = false
            }
        }
    }
}
