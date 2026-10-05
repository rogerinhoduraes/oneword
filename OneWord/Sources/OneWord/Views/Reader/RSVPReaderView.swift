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
    @State private var isShowingReadingGuide: Bool = false
    
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
                
                if EyeTrackingManager.shared.isFatigueRestSuggested {
                    fatigueRestBanner
                }
                
                if viewModel.readerMode == .bionic {
                    BionicPacerView(viewModel: viewModel)
                } else {
                    Spacer()
                    rsvpCenterDisplay
                    Spacer()
                }
                
                bottomControlsPanel
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .sheet(isPresented: $viewModel.isShowingSettings) {
            readerSettingsSheet
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.isShowingWordDefinition) {
            WordDefinitionSheetView(word: viewModel.wordToDefine)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.isShowingShareCard) {
            SocialShareCardView(
                documentTitle: viewModel.title,
                wordsRead: max(1, viewModel.currentIndex),
                averageWPM: viewModel.engine.config.wpm,
                timeSavedMinutes: viewModel.engine.remainingMinutes
            )
        }
        .sheet(isPresented: $viewModel.isShowingPrimingSheet) {
            if let primingContext = viewModel.primingContext {
                CognitivePrimingSheetView(context: primingContext) {
                    viewModel.startReadingFromPriming()
                }
                .presentationDetents([.medium, .large])
            }
        }
        .sheet(isPresented: $isShowingReadingGuide) {
            ReadingGuideView()
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        .statusBarHidden(true)
        #endif
        .onDisappear {
            viewModel.onDisappear()
        }
    }
    
    // MARK: - Barra Superior
    
    private var topNavigationBar: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.onDisappear()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Fechar leitor")
            
            VStack(spacing: 2) {
                Text(viewModel.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(viewModel.settings.theme.textColor)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if !viewModel.subtitle.isEmpty {
                        Text(viewModel.subtitle)
                        Text("•")
                    }
                    Text(viewModel.remainingTimeFormatted)
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 2) {
                // Alternância Rápida de Modo (RSVP vs Biônico)
                Button {
                    triggerHapticFeedback()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.readerMode = (viewModel.readerMode == .rsvp) ? .bionic : .rsvp
                    }
                } label: {
                    Image(systemName: viewModel.readerMode == .rsvp ? "bolt.fill" : "text.alignleft")
                        .font(.caption.bold())
                        .foregroundStyle(viewModel.settings.theme.textColor)
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Circle())
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.readerMode == .rsvp ? "Mudar para modo Biônico" : "Mudar para modo RSVP foveal")
                
                // Menu de Ações Secundárias (Decluttering da barra superior)
                Menu {
                    // Tradução Rápida
                    if viewModel.hasTranslation || viewModel.isForeignLanguage {
                        Button {
                            triggerHapticFeedback()
                            viewModel.toggleTranslation()
                        } label: {
                            if viewModel.isTranslationActive {
                                Label("Ver Texto Original (\(viewModel.originalLanguageName))", systemImage: "globe")
                            } else if viewModel.hasTranslation {
                                Label("Ver Tradução em Português", systemImage: "character.book.closed")
                            } else {
                                Label("Traduzir para Português", systemImage: "translate")
                            }
                        }
                    }
                    
                    // Priming Neurocognitivo
                    Button {
                        triggerHapticFeedback()
                        viewModel.presentPriming()
                    } label: {
                        Label("Priming Cognitivo (Resumo Prévio)", systemImage: "brain.head.profile")
                    }
                    
                    // Compartilhamento Social
                    Button {
                        viewModel.isShowingShareCard = true
                    } label: {
                        Label("Compartilhar Progresso", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.caption.bold())
                        .foregroundStyle(viewModel.settings.theme.textColor)
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Circle())
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Mais opções de leitura")
                
                // Botão de Ajustes Visuais e Tipografia
                Button {
                    viewModel.isShowingSettings = true
                } label: {
                    Image(systemName: "textformat.size")
                        .font(.caption.bold())
                        .foregroundStyle(viewModel.settings.theme.textColor)
                        .frame(width: 32, height: 32)
                        .background(Color.secondary.opacity(0.15))
                        .clipShape(Circle())
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .accessibilityLabel("Ajustes visuais e tipografia")
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 4)
    }
    
    // MARK: - Banner de Descanso 20-20-20
    
    private var fatigueRestBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye.trianglebadge.exclamationmark")
                .font(.title3)
                .foregroundStyle(.orange)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Regra 20-20-20: Descanse seus Olhos")
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
                Text("Olhe para 6 metros por 20 segundos.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button("Dispensar") {
                EyeTrackingManager.shared.dismissFatigueSuggestion()
            }
            .font(.caption2.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.orange.opacity(0.2))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.top, 4)
    }
    
    // MARK: - Display Central RSVP (Palavra e Ponto Óptico de Reconhecimento)
    
    private var rsvpCenterDisplay: some View {
        VStack(spacing: 20) {
            if viewModel.isCompleted {
                completedStateView
            } else {
                // Caixa Óptica de Fixação Focal (Estilo Spritz / Outread)
                VStack(spacing: 0) {
                    // Marcador e Guia Superior do ORP
                    if viewModel.settings.showORPNotch {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(viewModel.settings.theme.textColor.opacity(0.12))
                                .frame(height: 1)
                            
                            Rectangle()
                                .fill(Color.red.opacity(0.9))
                                .frame(width: 3, height: 12)
                                .clipShape(Capsule())
                            
                            Rectangle()
                                .fill(viewModel.settings.theme.textColor.opacity(0.12))
                                .frame(height: 1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Exibição da palavra com ponto focal ancorado no centro horizontal exato
                    ZStack {
                        if viewModel.settings.chunkSize > 1 {
                            let chunk = viewModel.engine.currentChunkWords
                            HStack(spacing: 8) {
                                ForEach(Array(chunk.enumerated()), id: \.offset) { index, word in
                                    if index == 0 {
                                        let split = ORPHelper.splitWord(word)
                                        HStack(spacing: 0) {
                                            Text(split.prefix)
                                                .foregroundColor(viewModel.settings.theme.textColor)
                                            Text(String(split.focalCharacter))
                                                .foregroundColor(.red)
                                                .fontWeight(.bold)
                                            Text(split.suffix)
                                                .foregroundColor(viewModel.settings.theme.textColor)
                                        }
                                    } else {
                                        Text(word)
                                            .foregroundColor(viewModel.settings.theme.textColor.opacity(0.85))
                                    }
                                }
                            }
                            .font(viewModel.settings.font.font(size: max(22, viewModel.settings.fontSize - CGFloat(viewModel.settings.chunkSize * 4))))
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                            .multilineTextAlignment(.center)
                        } else {
                            // Alinhamento geométrico perfeito do Ponto Óptico de Reconhecimento (ORP):
                            // O semiplano esquerdo (prefixo) termina exatamente onde o caractere focal começa,
                            // e o semiplano direito (sufixo) começa onde o caractere focal termina.
                            // Como ambos têm maxWidth: .infinity, o caractere vermelho fica sempre a 50% da tela!
                            let split = viewModel.currentSplitWord
                            
                            HStack(spacing: 0) {
                                Text(split.prefix)
                                    .foregroundColor(viewModel.settings.theme.textColor)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                
                                Text(String(split.focalCharacter))
                                    .foregroundColor(.red)
                                    .fontWeight(.bold)
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                                
                                Text(split.suffix)
                                    .foregroundColor(viewModel.settings.theme.textColor)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(viewModel.settings.font.font(size: viewModel.settings.fontSize))
                            .lineLimit(1)
                            .minimumScaleFactor(0.65)
                        }
                    }
                    .frame(height: max(88, viewModel.settings.fontSize * 1.55))
                    .contentTransition(.identity)
                    
                    // Marcador e Guia Inferior do ORP
                    if viewModel.settings.showORPNotch {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(viewModel.settings.theme.textColor.opacity(0.12))
                                .frame(height: 1)
                            
                            Rectangle()
                                .fill(Color.red.opacity(0.9))
                                .frame(width: 3, height: 12)
                                .clipShape(Capsule())
                            
                            Rectangle()
                                .fill(viewModel.settings.theme.textColor.opacity(0.12))
                                .frame(height: 1)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(viewModel.settings.theme.textColor.opacity(0.03))
                )
                .contentShape(Rectangle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(viewModel.isPlaying ? viewModel.currentWord : "Palavra atual: \(viewModel.currentWord)")
                .accessibilityValue("Palavra \(min(viewModel.currentIndex + 1, viewModel.totalWords)) de \(viewModel.totalWords), \(viewModel.progressPercentageFormatted)")
                .accessibilityHint("Toque duas vezes para \(viewModel.isPlaying ? "pausar" : "iniciar") a leitura")
                .accessibilityAddTraits(.isButton)
                .onTapGesture {
                    triggerHapticFeedback()
                    viewModel.togglePlayPause()
                }
                
                // Ações contextuais rápidas exibidas quando pausado
                if !viewModel.isPlaying && !viewModel.currentWord.isEmpty {
                    HStack(spacing: 10) {
                        Button {
                            viewModel.showDefinitionForCurrentWord()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "character.book.closed.fill")
                                Text("Dicionário: \(viewModel.currentWord)")
                                    .lineLimit(1)
                            }
                            .font(.caption2.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.12))
                            .foregroundStyle(viewModel.settings.theme.textColor.opacity(0.85))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        if viewModel.currentIndex == 0 {
                            Button {
                                triggerHapticFeedback()
                                viewModel.presentPriming()
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "brain.head.profile")
                                    Text("Priming Cognitivo")
                                }
                                .font(.caption2.bold())
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.18))
                                .foregroundStyle(.purple)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
    }
    
    /// Visualização ao concluir a leitura do texto.
    private var completedStateView: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 58))
                .foregroundStyle(.green)
            
            Text("Leitura Concluída!")
                .font(.title2.bold())
                .foregroundStyle(viewModel.settings.theme.textColor)
            
            Button {
                viewModel.reset()
            } label: {
                Label("Ler Novamente", systemImage: "arrow.counterclockwise")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
    }
    
    // MARK: - Painel Inferior de Controles
    
    private var bottomControlsPanel: some View {
        VStack(spacing: 14) {
            // 1. Barra de progresso interativa e contadores
            VStack(spacing: 6) {
                HStack {
                    Text("Palavra \(min(viewModel.currentIndex + 1, viewModel.totalWords)) de \(viewModel.totalWords)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("\(viewModel.progressPercentageFormatted) • \(viewModel.remainingTimeFormatted)")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                
                // Barra de progresso interativa sem o overhead de sliders com thumb saltitante
                GeometryReader { geometry in
                    let total = max(1, viewModel.totalWords)
                    let currentRatio = min(1.0, max(0.0, Double(viewModel.currentIndex) / Double(total)))
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 6)
                        
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * currentRatio, height: 6)
                    }
                    .frame(height: 24)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let fraction = max(0.0, min(1.0, value.location.x / geometry.size.width))
                                viewModel.scrubberBinding = fraction * Double(total)
                            }
                    )
                }
                .frame(height: 14)
            }
            
            // 2. Controle Compacto de Velocidade (WPM)
            HStack(spacing: 14) {
                Button {
                    adjustWPM(by: -25)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityLabel("Reduzir velocidade em 25 palavras por minuto")
                
                Menu {
                    Text("Velocidade de Leitura")
                    Divider()
                    ForEach([200, 250, 300, 350, 400, 450, 500, 600], id: \.self) { speed in
                        Button("\(speed) WPM") {
                            viewModel.wpmBinding = Double(speed)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "speedometer")
                            .font(.caption)
                        Text("\(Int(viewModel.wpmBinding)) WPM")
                            .font(.subheadline.bold().monospacedDigit())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())
                }
                .accessibilityLabel("Velocidade atual: \(Int(viewModel.wpmBinding)) palavras por minuto")
                .accessibilityHint("Toque para escolher uma velocidade predefinida")
                
                Button {
                    adjustWPM(by: 25)
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityLabel("Aumentar velocidade em 25 palavras por minuto")
            }
            
            // 3. Barra de Transporte Principal com Distribuição Fluida
            HStack {
                // Reiniciar
                Button {
                    triggerHapticFeedback()
                    viewModel.reset()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityLabel("Reiniciar leitura do início")
                
                Spacer()
                
                // Retroceder Frase
                Button {
                    triggerHapticFeedback()
                    viewModel.rewindSentence()
                } label: {
                    Image(systemName: "backward.end.alt.fill")
                        .font(.title3)
                        .foregroundStyle(viewModel.settings.theme.textColor)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityLabel("Voltar para frase anterior")
                
                Spacer()
                
                // Retroceder 10 Palavras
                Button {
                    triggerHapticFeedback()
                    viewModel.rewind10Words()
                } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title2)
                        .foregroundStyle(viewModel.settings.theme.textColor)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityLabel("Voltar 10 palavras")
                
                Spacer()
                
                // Botão Play / Pause de Alta Proeminência
                Button {
                    triggerHapticFeedback()
                    viewModel.togglePlayPause()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 62))
                        .foregroundStyle(Color.accentColor)
                        .shadow(color: Color.accentColor.opacity(0.25), radius: 8, x: 0, y: 3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(viewModel.isPlaying ? "Pausar leitura" : "Iniciar leitura")
                
                Spacer()
                
                // Avançar Frase
                Button {
                    triggerHapticFeedback()
                    viewModel.advanceSentence()
                } label: {
                    Image(systemName: "forward.end.alt.fill")
                        .font(.title3)
                        .foregroundStyle(viewModel.settings.theme.textColor)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityLabel("Avançar para próxima frase")
            }
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Painel Modal de Configurações Visuais
    
    private var readerSettingsSheet: some View {
        NavigationStack {
            Form {
                Section("Tema Visual") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ReaderTheme.allCases) { theme in
                                Button {
                                    viewModel.settings.theme = theme
                                } label: {
                                    VStack(spacing: 6) {
                                        ZStack {
                                            Circle()
                                                .fill(theme.backgroundColor)
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                                )
                                            
                                            Text("Aa")
                                                .font(.headline.bold())
                                                .foregroundColor(theme.textColor)
                                            
                                            if viewModel.settings.theme == theme {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.caption)
                                                    .foregroundColor(Color.accentColor)
                                                    .offset(x: 16, y: -16)
                                            }
                                        }
                                        
                                        Text(theme.rawValue)
                                            .font(.caption2)
                                            .foregroundStyle(viewModel.settings.theme == theme ? Color.primary : Color.secondary)
                                            .lineLimit(1)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
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
                
                Section("Modos de Leitura & Ergonomia") {
                    Picker("Modo de Leitura", selection: $viewModel.readerMode) {
                        ForEach(RSVPReaderViewModel.ReaderMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    
                    Toggle("Smart WPM (Ritmo Adaptativo)", isOn: $viewModel.settings.smartWPMEnabled)
                    
                    Toggle("Eye-Tracking (Pausa por Desvio de Olhar)", isOn: $viewModel.isEyeTrackingEnabled)
                    
                    if viewModel.readerMode == .rsvp {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Palavras por Quadro (Chunking)")
                            Picker("Palavras por Quadro", selection: $viewModel.settings.chunkSize) {
                                Text("1 Palavra").tag(1)
                                Text("2 Palavras").tag(2)
                                Text("3 Palavras").tag(3)
                            }
                            .pickerStyle(.segmented)
                        }
                    }
                    
                    Toggle("Modo Bimodal (Áudio Sincronizado)", isOn: $viewModel.settings.bimodalAudioEnabled)
                }
                
                Section("Auxílio de Fixação Óptica") {
                    Toggle("Exibir Marcadores de Fixação (ORP)", isOn: $viewModel.settings.showORPNotch)
                }
                
                Section("Aprendizado & Neurociência") {
                    Button {
                        isShowingReadingGuide = true
                    } label: {
                        Label("Entenda as Técnicas & Recursos", systemImage: "brain.head.profile")
                    }
                }
            }
            .navigationTitle("Ajustes de Leitura")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluir") {
                        viewModel.applySettings()
                        viewModel.isShowingSettings = false
                    }
                }
            }
        }
    }
    
    // MARK: - Ações e Feedback Háptico
    
    private func adjustWPM(by delta: Int) {
        HapticEngine.shared.tickSpeedChange()
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
