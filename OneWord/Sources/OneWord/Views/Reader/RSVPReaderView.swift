//
//  RSVPReaderView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI
import SwiftData

/// Tela minimalista e imersiva do leitor RSVP (Rapid Serial Visual Presentation).
/// Projeta uma palavra por vez no centro visual da tela com guias ópticas (ORP),
/// pausas cognitivas dinâmicas por pontuação e controle fino de WPM.
public struct RSVPReaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var viewModel: RSVPReaderViewModel
    
    /// Inicializa a tela de leitura diretamente com um RSVPReaderViewModel configurado.
    public init(viewModel: RSVPReaderViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    /// Inicializa a tela de leitura a partir de um documento persistido.
    /// - Parameters:
    ///   - document: Documento da biblioteca.
    ///   - modelContext: Contexto SwiftData para auto-save contínuo.
    public init(document: Document, modelContext: ModelContext? = nil) {
        _viewModel = State(initialValue: RSVPReaderViewModel(document: document, modelContext: modelContext))
    }
    
    /// Inicializa a tela de leitura a partir de um livro multi-páginas da biblioteca.
    /// - Parameters:
    ///   - book: Livro da biblioteca.
    ///   - startPageNumber: Página específica para início (opcional, para modo híbrido).
    ///   - modelContext: Contexto SwiftData para auto-save contínuo.
    public init(book: Book, startPageNumber: Int? = nil, modelContext: ModelContext? = nil) {
        _viewModel = State(initialValue: RSVPReaderViewModel(book: book, startPageNumber: startPageNumber, modelContext: modelContext))
    }
    
    public var body: some View {
        ZStack {
            // Fundo imersivo minimalista com suporte ao tema selecionado
            viewModel.settings.theme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topNavigationBar
                
                Spacer()
                
                rsvpCenterDisplay
                
                Spacer()
                
                bottomControlsPanel
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .sheet(isPresented: $viewModel.isShowingSettings) {
            readerSettingsSheet
                .presentationDetents([.medium])
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden(viewModel.isPlaying)
        #endif
        .onDisappear {
            viewModel.onDisappear()
        }
    }
    
    // MARK: - Barra Superior
    
    private var topNavigationBar: some View {
        HStack {
            Button {
                viewModel.onDisappear()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(viewModel.title)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if !viewModel.subtitle.isEmpty {
                        Text(viewModel.subtitle)
                        Text("•")
                    }
                    Text(viewModel.remainingTimeFormatted)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 10) {
                // Badge com WPM atual
                Text("\(Int(viewModel.wpmBinding)) WPM")
                    .font(.caption.bold().monospacedDigit())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
                
                // Botão de personalização visual (tema e tipografia)
                Button {
                    viewModel.isShowingSettings = true
                } label: {
                    Image(systemName: "textformat.size")
                        .font(.subheadline.bold())
                        .foregroundStyle(viewModel.settings.theme.textColor)
                        .padding(6)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Display Central RSVP (Palavra e Ponto Óptico de Reconhecimento)
    
    private var rsvpCenterDisplay: some View {
        VStack(spacing: 18) {
            if viewModel.isCompleted {
                completedStateView
            } else {
                VStack(spacing: 8) {
                    // Marcador visual superior do ORP (Notch focal)
                    if viewModel.settings.showORPNotch {
                        HStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.accentColor.opacity(0.4))
                                .frame(width: 2.5, height: 12)
                            Spacer()
                        }
                    }
                    
                    // Exibição da palavra com destaque focal no ORP
                    HStack(spacing: 0) {
                        let split = viewModel.currentSplitWord
                        
                        Text(split.prefix)
                            .foregroundColor(viewModel.settings.theme.textColor)
                        
                        Text(String(split.focalCharacter))
                            .foregroundColor(.red) // Ponto focal ORP em vermelho (estilo Spritz)
                        
                        Text(split.suffix)
                            .foregroundColor(viewModel.settings.theme.textColor)
                    }
                    .font(viewModel.settings.font.font(size: viewModel.settings.fontSize))
                    .multilineTextAlignment(.center)
                    .frame(height: 75)
                    .contentTransition(.identity)
                    
                    // Marcador visual inferior do ORP
                    if viewModel.settings.showORPNotch {
                        HStack {
                            Spacer()
                            Rectangle()
                                .fill(Color.accentColor.opacity(0.4))
                                .frame(width: 2.5, height: 12)
                            Spacer()
                        }
                    }
                }
                .padding(.vertical, 16)
                .contentShape(Rectangle())
                .onTapGesture {
                    triggerHapticFeedback()
                    viewModel.togglePlayPause()
                }
            }
        }
    }
    
    /// Visualização ao concluir a leitura do texto.
    private var completedStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            
            Text("Leitura Concluída!")
                .font(.title2.bold())
            
            Button {
                viewModel.reset()
            } label: {
                Label("Ler Novamente", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
    }
    
    // MARK: - Painel Inferior de Controles
    
    private var bottomControlsPanel: some View {
        VStack(spacing: 18) {
            // 1. Barra de progresso e estatísticas
            VStack(spacing: 6) {
                HStack {
                    Text("Palavra \(min(viewModel.currentIndex + 1, viewModel.totalWords)) de \(viewModel.totalWords)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.progressPercentageFormatted)
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                
                Slider(
                    value: Binding(
                        get: { viewModel.scrubberBinding },
                        set: { viewModel.scrubberBinding = $0 }
                    ),
                    in: 0...Double(max(1, viewModel.totalWords))
                )
                .tint(.accentColor)
            }
            
            // 2. Controle de Velocidade (WPM)
            HStack(spacing: 12) {
                Button {
                    adjustWPM(by: -25)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                
                Slider(
                    value: Binding(
                        get: { viewModel.wpmBinding },
                        set: { viewModel.wpmBinding = $0 }
                    ),
                    in: 150...800,
                    step: 25
                )
                .tint(.accentColor)
                
                Button {
                    adjustWPM(by: 25)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            
            // 3. Barra de Transporte Principal
            HStack(spacing: 28) {
                // Retroceder Frase
                Button {
                    triggerHapticFeedback()
                    viewModel.rewindSentence()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "backward.end.alt.fill")
                            .font(.title3)
                        Text("Frase")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.primary)
                }
                
                // Retroceder 10 Palavras (Requisito de UX)
                Button {
                    triggerHapticFeedback()
                    viewModel.rewind10Words()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "gobackward.10")
                            .font(.title2)
                        Text("-10 pal.")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.primary)
                }
                
                // Botão Play / Pause de Alta Proeminência
                Button {
                    triggerHapticFeedback()
                    viewModel.togglePlayPause()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                // Avançar Frase
                Button {
                    triggerHapticFeedback()
                    viewModel.advanceSentence()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "forward.end.alt.fill")
                            .font(.title3)
                        Text("Frase")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.primary)
                }
                
                // Reiniciar
                Button {
                    triggerHapticFeedback()
                    viewModel.reset()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.title3)
                        Text("Início")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Painel Modal de Configurações Visuais
    
    private var readerSettingsSheet: some View {
        NavigationStack {
            Form {
                Section("Tema Visual") {
                    Picker("Tema", selection: $viewModel.settings.theme) {
                        ForEach(ReaderTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Tipografia") {
                    Picker("Estilo de Fonte", selection: $viewModel.settings.font) {
                        ForEach(ReaderFont.allCases) { font in
                            Text(font.rawValue).tag(font)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tamanho da Fonte")
                            Spacer()
                            Text("\(Int(viewModel.settings.fontSize)) pt")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $viewModel.settings.fontSize, in: 34...62, step: 2)
                    }
                }
                
                Section("Auxílio de Fixação Óptica") {
                    Toggle("Exibir Marcadores de Fixação (ORP)", isOn: $viewModel.settings.showORPNotch)
                }
            }
            .navigationTitle("Ajustes de Leitura")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluir") {
                        viewModel.isShowingSettings = false
                    }
                }
            }
        }
    }
    
    // MARK: - Ações e Feedback Háptico
    
    private func adjustWPM(by delta: Int) {
        triggerHapticFeedback()
        let current = Int(viewModel.wpmBinding)
        viewModel.wpmBinding = Double(current + delta)
    }
    
    private func triggerHapticFeedback() {
        #if canImport(UIKit)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        #endif
    }
}

// Extensão utilitária para compatibilidade de cores
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
