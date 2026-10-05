//
//  ReadingGuideView.swift
//  OneWord
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import SwiftUI

/// Central de Conhecimento e Manual Oficial do OneWord.
/// Explica em profundidade a neurociência e fundamentos das técnicas de leitura veloz (RSVP, ORP, Biônica, Priming, Bimodal, etc.)
/// e cataloga detalhadamente todos os recursos, ferramentas e integrações presentes no aplicativo,
/// incluindo um simulador interativo em tempo real para experimentação prática imediata.
public struct ReadingGuideView: View {
    @Environment(\.dismiss) private var dismiss
    
    public enum GuideSection: String, CaseIterable, Identifiable {
        case techniques = "Técnicas de Leitura"
        case features = "Recursos do App"
        case simulator = "Simulador Prático"
        
        public var id: String { rawValue }
        
        public var iconName: String {
            switch self {
            case .techniques: return "brain.head.profile"
            case .features: return "sparkles.rectangle.stack"
            case .simulator: return "play.circle.fill"
            }
        }
    }
    
    @State private var selectedSection: GuideSection = .techniques
    @State private var searchText: String = ""
    
    public init(initialSection: GuideSection = .techniques) {
        _selectedSection = State(initialValue: initialSection)
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Seletor de Categoria
                Picker("Seção do Guia", selection: $selectedSection) {
                    ForEach(GuideSection.allCases) { section in
                        Label(section.rawValue, systemImage: section.iconName)
                            .tag(section)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 12)
                
                // Conteúdo da Categoria
                ScrollView {
                    VStack(spacing: 24) {
                        heroHeaderView
                        
                        switch selectedSection {
                        case .techniques:
                            techniquesSectionView
                        case .features:
                            featuresSectionView
                        case .simulator:
                            interactiveSimulatorSectionView
                        }
                        
                        footerNoteView
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.guideGroupedBackground.ignoresSafeArea())
            .navigationTitle("Guia & Técnicas")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") {
                        dismiss()
                    }
                    .font(.body.bold())
                }
            }
            .searchable(text: $searchText, prompt: "Buscar conceitos, técnicas ou recursos...")
        }
    }
    
    // MARK: - Hero Header
    
    private var heroHeaderView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.85), Color.indigo.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: selectedSection.iconName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text(sectionHeaderTitle)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary)
            
            Text(sectionHeaderSubtitle)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(Color.guideCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    
    private var sectionHeaderTitle: String {
        switch selectedSection {
        case .techniques:
            return "A Ciência da Leitura Veloz"
        case .features:
            return "Catálogo Completo de Recursos"
        case .simulator:
            return "Laboratório Interativo"
        }
    }
    
    private var sectionHeaderSubtitle: String {
        switch selectedSection {
        case .techniques:
            return "Entenda os princípios de neurovisão, eliminação de movimentos sacádicos e fixação foveal que destravam até 1000+ WPM."
        case .features:
            return "Conheça cada motor, escaneador, ferramenta de IA e integração de hardware concebida para otimizar sua aprendizagem."
        case .simulator:
            return "Compare em tempo real a leitura convencional, a Leitura Biônica e o motor RSVP com ponto ótimo de reconhecimento (ORP)."
        }
    }
    
    // MARK: - 1. Seção de Técnicas de Leitura
    
    private var filteredTechniques: [ReadingTechniqueItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return allTechniques }
        return allTechniques.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.summary.localizedCaseInsensitiveContains(trimmed) ||
            $0.neuroscience.localizedCaseInsensitiveContains(trimmed)
        }
    }
    
    private var techniquesSectionView: some View {
        VStack(spacing: 16) {
            ForEach(filteredTechniques) { technique in
                TechniqueCardView(technique: technique)
            }
        }
    }
    
    // MARK: - 2. Seção de Recursos do App
    
    private var filteredFeatureCategories: [FeatureCategoryItem] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return allFeatureCategories }
        
        return allFeatureCategories.compactMap { category in
            let filteredFeatures = category.features.filter {
                $0.title.localizedCaseInsensitiveContains(trimmed) ||
                $0.description.localizedCaseInsensitiveContains(trimmed) ||
                category.title.localizedCaseInsensitiveContains(trimmed)
            }
            if filteredFeatures.isEmpty { return nil }
            return FeatureCategoryItem(
                title: category.title,
                iconName: category.iconName,
                tintColor: category.tintColor,
                features: filteredFeatures
            )
        }
    }
    
    private var featuresSectionView: some View {
        VStack(spacing: 20) {
            ForEach(filteredFeatureCategories) { category in
                FeatureCategoryCardView(category: category)
            }
        }
    }
    
    // MARK: - 3. Seção do Simulador Interativo
    
    private var interactiveSimulatorSectionView: some View {
        InteractiveReaderSimulatorCardView()
    }
    
    // MARK: - Rodapé de Informação
    
    private var footerNoteView: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundStyle(.blue)
            
            Text("OneWord Neuroscience & iOS Engineering")
                .font(.caption.bold())
                .foregroundStyle(Color.secondary)
            
            Text("Criado para transformar leitura passiva em alta produtividade cognitiva com suporte integral ao ecossistema Apple.")
                .font(.caption2)
                .foregroundStyle(Color.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.top, 12)
    }
}

// MARK: - Modelos de Dados do Guia

public struct ReadingTechniqueItem: Identifiable, Sendable {
    public var id: String { title }
    public let title: String
    public let subtitle: String
    public let badge: String
    public let iconName: String
    public let iconColor: Color
    public let summary: String
    public let neuroscience: String
    public let practicalImpact: String
    public let howToUseInApp: String
}

public struct FeatureDetailItem: Identifiable, Sendable {
    public var id: String { title }
    public let title: String
    public let iconName: String
    public let description: String
    public let proFeature: Bool
}

public struct FeatureCategoryItem: Identifiable, Sendable {
    public var id: String { title }
    public let title: String
    public let iconName: String
    public let tintColor: Color
    public let features: [FeatureDetailItem]
}

// MARK: - Coleção de Técnicas

private let allTechniques: [ReadingTechniqueItem] = [
    ReadingTechniqueItem(
        title: "RSVP (Rapid Serial Visual Presentation)",
        subtitle: "Apresentação Serial Visual Rápida",
        badge: "Núcleo Central",
        iconName: "speedometer",
        iconColor: .blue,
        summary: "Exibe palavras sucessivamente no mesmo ponto focal em frequência milimétrica, eliminando a necessidade de varrer os olhos pela linha.",
        neuroscience: "Na leitura tradicional, os olhos gastam até 80% do tempo executando movimentos sacádicos (saltos de 20 a 40ms) e regressões involuntárias (quando o olho retorna para reler trechos). O RSVP projeta o texto no centro exato da visão, reduzindo as sacadas a zero e atenuando a subvocalização mecânica (falar mentalmente cada sílaba).",
        practicalImpact: "Eleva a velocidade de leitura da média humana (180–230 WPM) para 400 a 800+ WPM com menor fadiga dos músculos oculomotores.",
        howToUseInApp: "Abra qualquer livro ou artigo e toque no Play. Ajuste a velocidade no velocímetro WPM em incrementos rápidos de 25 WPM."
    ),
    ReadingTechniqueItem(
        title: "ORP (Optimal Recognition Point)",
        subtitle: "Ponto Ótimo de Reconhecimento Foveal",
        badge: "Neurovisão",
        iconName: "scope",
        iconColor: .red,
        summary: "Identifica a letra âncora de cada palavra e a posiciona precisamente no centro óptico de foco, destacada em vermelho.",
        neuroscience: "Estudos oftalmológicos e de psicologia cognitiva revelam que a fóvea humana processa uma palavra com o menor esforço neural quando o olhar fixa ligeiramente à esquerda do centro geométrico (~30% a 35% do comprimento do vocábulo). Ao ancorar a letra exata sobre a mira óptica, o cérebro reconhece a palavra inteira em uma única fixação.",
        practicalImpact: "Elimina a microvarredura horizontal interna dentro da palavra, permitindo reconhecimento instantâneo mesmo em termos longos ou complexos.",
        howToUseInApp: "Ativo nativamente no display do RSVP. Você pode ligar ou desligar os marcadores de mira vertical (ORP Notches) no painel de ajustes."
    ),
    ReadingTechniqueItem(
        title: "Leitura Biônica (Bionic Reading)",
        subtitle: "Ancoragem Artificial em Texto Contínuo",
        badge: "Ergonomia Visual",
        iconName: "character.book.closed.fill",
        iconColor: .purple,
        summary: "Destaca em negrito as primeiras letras das palavras em um layout de parágrafos, guiando o olhar através do fluxo textual.",
        neuroscience: "O cérebro atua como uma máquina preditiva: ao capturar as primeiras consoantes e vogais proeminentes, ele recupera o termo do léxico mental e completa as letras restantes automaticamente. Isso reduz o tempo de fixação em cada vocábulo mantendo a referência espacial da página.",
        practicalImpact: "Excelente para quem prefere ler em formato de parágrafos tradicionais sem perder a velocidade acelerada e ideal para redução do estresse visual.",
        howToUseInApp: "Durante a leitura de qualquer documento, abra os Ajustes e selecione o 'Modo de Leitura: Biônica'. O app ativa a rolagem autônoma guiada."
    ),
    ReadingTechniqueItem(
        title: "Priming Cognitivo (Aquecimento Neural)",
        subtitle: "Pré-ativação Sináptica de Palavras-Chave",
        badge: "Retenção",
        iconName: "lightbulb.max.fill",
        iconColor: .orange,
        summary: "Apresenta os conceitos, termos técnicos e palavras-chave mais relevantes antes de iniciar a sessão de leitura acelerada.",
        neuroscience: "O cérebro compreende informação por associação em redes semânticas. Quando exposto previamente às entidades centrais de um texto (por 15 a 30 segundos), a memória de trabalho antecipa o contexto, minimizando tropeços cognitivos ao encontrar vocábulos raros em alta velocidade.",
        practicalImpact: "Aumenta o índice de retenção e compreensão em até 40% em textos técnicos, acadêmicos, ensaios ou literatura densa.",
        howToUseInApp: "Toque no ícone de lâmpada na barra superior do leitor ou ative a opção de aquecimento antes de iniciar um capítulo longo."
    ),
    ReadingTechniqueItem(
        title: "Leitura Bimodal (Áudio + Visual Sincronizado)",
        subtitle: "Coativação Cortical Dupla",
        badge: "Multissensorial",
        iconName: "headphones",
        iconColor: .teal,
        summary: "Sincroniza síntese de voz neural (Text-to-Speech) exatamente no ritmo da palavra exibida na tela pelo RSVP.",
        neuroscience: "Ao estimular simultaneamente o córtex visual occipital e o córtex auditivo temporal, cria-se uma barreira anti-distração impenetrável. Pensamentos intrusivos e divagações são bloqueados pela saturação sensorial coordenada.",
        practicalImpact: "Garante foco absoluto em ambientes barulhentos e proporciona benefícios expressivos para pessoas com TDAH, dislexia ou cansaço visual.",
        howToUseInApp: "Nos Ajustes do Leitor, ative 'Modo Bimodal (Áudio Sincronizado)'. Ajuste o volume diretamente nos botões físicos do dispositivo."
    ),
    ReadingTechniqueItem(
        title: "Rastreamento Ocular & Fadiga (Eye-Tracking)",
        subtitle: "Biofeedback Óptico com Câmera TrueDepth",
        badge: "Apple TrueDepth",
        iconName: "eye.fill",
        iconColor: .indigo,
        summary: "Monitora os olhos via ARKit para pausar automaticamente se você desviar o foco e vigia a taxa de piscadas para alertar sobre cansaço.",
        neuroscience: "A fadiga do músculo ciliar e o ressecamento da córnea diminuem dramaticamente a absorção de leitura. O algoritmo de pupilometria do OneWord detecta desvios atencionais e propõe micropausas restauradoras seguindo a regra 20-20-20.",
        practicalImpact: "Nunca perca o ponto de leitura ao olhar para os lados e preserve a saúde ocular mesmo em sessões diárias intensas.",
        howToUseInApp: "Ative a chave 'Eye-Tracking (Pausa por Desvio de Olhar)' nas configurações do leitor RSVP. Requer permissão da câmera frontal."
    ),
    ReadingTechniqueItem(
        title: "Repetição Espaçada (Spaced Repetition)",
        subtitle: "Cristalização em Memória de Longo Prazo",
        badge: "SuperMemo / Leitner",
        iconName: "rectangle.stack.badge.play.fill",
        iconColor: .green,
        summary: "Agenda revisões científicas de cartões e pontos-chave em intervalos progressivos calculados (1 dia, 3 dias, 7 dias, etc.).",
        neuroscience: "Combate a infame 'Curva do Esquecimento de Ebbinghaus', segundo a qual mais de 70% do conteúdo lido é esquecido em 48 horas se não houver recuperação ativa (*active recall*).",
        practicalImpact: "Converte o alto volume de leitura acelerada em repertório intelectual retido permanentemente na memória de longo prazo.",
        howToUseInApp: "Gere Flashcards automaticamente ao terminar uma leitura e revise os cartões pendentes no ícone de baralho da Biblioteca."
    ),
    ReadingTechniqueItem(
        title: "Chunking Visual (1 a 3 Palavras)",
        subtitle: "Agrupamento de Unidades de Informação",
        badge: "Velocidade Extrema",
        iconName: "rectangle.split.3x1.fill",
        iconColor: .pink,
        summary: "Projeta duas ou três palavras interligadas em um único flash na tela para leitores de ritmo avançado.",
        neuroscience: "Expande a largura da janela de apreensão foveal e para-foveal. Leitores experientes passam a ler ideias completas (blocos semânticos) em vez de palavras isoladas.",
        practicalImpact: "Permite atingir velocidades superiores a 700–1000 WPM mantendo cadência confortável e fluidez natural.",
        howToUseInApp: "Nos Ajustes do Leitor, configure 'Palavras por Quadro (Chunking)' selecionando 1, 2 ou 3 palavras."
    )
]

// MARK: - Coleção de Recursos do App

private let allFeatureCategories: [FeatureCategoryItem] = [
    FeatureCategoryItem(
        title: "Biblioteca Inteligente & Gestão de Livros",
        iconName: "books.vertical.fill",
        tintColor: .blue,
        features: [
            FeatureDetailItem(
                title: "Estante de Livros Físicos & Digitais",
                iconName: "book.closed.fill",
                description: "Organize seus livros completos com capa real fotografada ou gerada, contagem de páginas e acompanhamento percentual preciso.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Artigos Avulsos & Textos Rápidos",
                iconName: "doc.text.fill",
                description: "Seção isolada para artigos web, PDFs curtos, notas e textos avulsos para leitura sem compromisso de volume.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Controle de Progresso & Retomada",
                iconName: "arrow.uturn.forward.circle.fill",
                description: "O OneWord salva a palavra e página exatas onde você pausou, permitindo retomar instantaneamente em qualquer dispositivo.",
                proFeature: false
            )
        ]
    ),
    FeatureCategoryItem(
        title: "Importação Multiformato Ampla",
        iconName: "arrow.down.doc.fill",
        tintColor: .indigo,
        features: [
            FeatureDetailItem(
                title: "Livros Digitais (.epub e .txt)",
                iconName: "character.book.closed.fill",
                description: "Importe e-books com separação automática de capítulos, metadados de autor e paginação dinâmica adaptativa.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Documentos e Apostilas em PDF",
                iconName: "doc.richtext.fill",
                description: "Extração textual inteligente que remove cabeçalhos, rodapés e quebras de linha artificiais para uma leitura suave.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Artigos da Web via Link (URL)",
                iconName: "link.badge.plus",
                description: "Cole qualquer link HTTP/HTTPS para extrair o artigo limpo, livre de anúncios, popups, banners e rastreadores.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Leitor Rápido de Área de Transferência",
                iconName: "doc.on.clipboard.fill",
                description: "Copie um texto no iPhone ou Mac e inicie a leitura acelerada em menos de dois segundos com um toque.",
                proFeature: false
            )
        ]
    ),
    FeatureCategoryItem(
        title: "Scanner Físico com Apple Vision OCR",
        iconName: "camera.viewfinder",
        tintColor: .green,
        features: [
            FeatureDetailItem(
                title: "Escaneamento Contínuo com Câmera",
                iconName: "camera.fill",
                description: "Digitalize páginas de livros físicos em sequência rápida, alimentando um livro contínuo com ordenação automática.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Correção de Perspectiva & Filtros P&B",
                iconName: "slider.horizontal.below.rectangle",
                description: "Algoritmos de processamento de imagem que ajustam a inclinação da folha e aumentam o contraste tipográfico.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "100% Offline & Total Privacidade",
                iconName: "lock.shield.fill",
                description: "O reconhecimento de caracteres opera integralmente na Neural Engine do dispositivo via Apple Vision, sem enviar dados para a nuvem.",
                proFeature: false
            )
        ]
    ),
    FeatureCategoryItem(
        title: "Motor de Leitura RSVP & Pacer",
        iconName: "gauge.with.needle.fill",
        tintColor: .red,
        features: [
            FeatureDetailItem(
                title: "Ajuste Fino de Velocidade (100–1000+ WPM)",
                iconName: "speedometer",
                description: "Controle gradual com botões rápidos de ±25 WPM e menu de atalhos para velocidades de 200, 300, 450, 600 ou 800 WPM.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Smart WPM (Ritmo Adaptativo)",
                iconName: "brain.fill",
                description: "Calcula pausas inteligentes em vírgulas, pontos finais, quebras de parágrafo e palavras raras para garantir compreensão.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "5 Temas Visuais Ergonômicos",
                iconName: "paintpalette.fill",
                description: "OLED Preto Puro (para economizar bateria e conforto no escuro), Dark Slate, Sepia Vintage, Creme e Branco Clássico.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Tipografia e Dimensionamento Dinâmico",
                iconName: "textformat.size",
                description: "Escolha entre fontes Sans, Serif clássica, Monospaçada e Rounded com ajuste de tamanho de 34pt a 62pt.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Barra de Navegação Fina de Transporte",
                iconName: "forward.frame.fill",
                description: "Retroceda 10 palavras, volte ao início da frase ou pule para a próxima sentença com toques de precisão.",
                proFeature: false
            )
        ]
    ),
    FeatureCategoryItem(
        title: "Inteligência Artificial Integrada",
        iconName: "sparkles",
        tintColor: .purple,
        features: [
            FeatureDetailItem(
                title: "Resumo Inteligente & Pontos-Chave",
                iconName: "text.quote",
                description: "Extraia instantaneamente um sumário executivo com os principais argumentos de qualquer livro ou artigo.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Gerador Automático de Flashcards",
                iconName: "rectangle.stack.fill",
                description: "A IA analisa o conteúdo lido e cria perguntas e respostas dos fatos mais relevantes para revisão espaçada.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Quizzes Dinâmicos de Compreensão",
                iconName: "questionmark.app.fill",
                description: "Teste se sua velocidade de leitura manteve a retenção alta respondendo a perguntas de múltipla escolha pós-sessão.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Dicionário & Definições Contextuais",
                iconName: "character.book.closed.fill",
                description: "Pause a leitura e toque na palavra para ver sua etimologia, classe gramatical e definição completa.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Tradução de Idiomas Integrada",
                iconName: "translate",
                description: "Traduza páginas e obras inteiras usando a tecnologia nativa do Apple Translation framework.",
                proFeature: false
            )
        ]
    ),
    FeatureCategoryItem(
        title: "Estatísticas, Benchmark & Produtividade",
        iconName: "chart.bar.xaxis",
        tintColor: .orange,
        features: [
            FeatureDetailItem(
                title: "Teste Científico de WPM (Benchmark)",
                iconName: "stopwatch.fill",
                description: "Avalie sua velocidade de leitura basal e faça o teste de retenção pós-teste para descobrir seu WPM verdadeiro.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Cálculo de Tempo Economizado",
                iconName: "clock.badge.checkmark.fill",
                description: "Descubra com precisão quantas horas e minutos você poupou em relação à velocidade tradicional de 200 WPM.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Ofensiva Diária (Streak Habit Tracker)",
                iconName: "flame.fill",
                description: "Acompanhe seus dias consecutivos lendo e defina sua meta diária de palavras para construir um hábito sólido.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Gráficos Interativos (Swift Charts)",
                iconName: "chart.xyaxis.line",
                description: "Histórico detalhado por dia, semana ou mês com evolução de velocidade média e volume de leitura.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Conquistas e Gamificação",
                iconName: "trophy.fill",
                description: "Desbloqueie medalhas exclusivas à medida que atinge metas de volume, velocidade e sequência de hábitos.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Cartões de Compartilhamento Social",
                iconName: "square.and.arrow.up.fill",
                description: "Gere cartões visuais elegantes com seus números de leitura para compartilhar nos Stories e redes sociais.",
                proFeature: false
            )
        ]
    ),
    FeatureCategoryItem(
        title: "Ecossistema Apple & Engenharia de Hardware",
        iconName: "applelogo",
        tintColor: .teal,
        features: [
            FeatureDetailItem(
                title: "Live Activities & Ilha Dinâmica",
                iconName: "capsule.fill",
                description: "Acompanhe o tempo de sessão ativa e a contagem regressiva de metas na tela bloqueada e na Dynamic Island.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Apple Pencil Pro & 2ª Geração (iPad)",
                iconName: "pencil.and.scribble",
                description: "Controle a leitura no iPad apertando (*squeeze*) ou dando duplo toque (*double tap*) na lateral da caneta.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Taptic Engine de Precisão Háptica",
                iconName: "iphone.radiowaves.left.and.right",
                description: "Pulsos mecânicos de alta frequência sincronizados com a passagem de palavras e alterações de velocidade.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "Atalhos da Siri & App Intents",
                iconName: "waveform",
                description: "Inicie leituras pelo leitor RSVP diretamente por comandos de voz ou automações no app Atalhos.",
                proFeature: false
            ),
            FeatureDetailItem(
                title: "100% Gratuito & Ilimitado",
                iconName: "gift.fill",
                description: "Acesso irrestrito a todos os motores avançados, recursos de inteligência artificial e personalização máxima, sem taxas ou assinaturas.",
                proFeature: false
            )
        ]
    )
]

// MARK: - Subviews de Apresentação

private struct TechniqueCardView: View {
    let technique: ReadingTechniqueItem
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Cabeçalho do Card
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(technique.iconColor.opacity(0.14))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: technique.iconName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(technique.iconColor)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(technique.title)
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(technique.badge)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(technique.iconColor.opacity(0.15))
                            .foregroundStyle(technique.iconColor)
                            .clipShape(Capsule())
                    }
                    
                    Text(technique.subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
            
            // Resumo Rápido
            Text(technique.summary)
                .font(.subheadline)
                .foregroundStyle(Color.primary.opacity(0.9))
                .lineSpacing(3)
            
            // Seção Expandida com Detalhes Científicos
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Fundamento Neurocientífico", systemImage: "brain.head.profile")
                            .font(.caption.bold())
                            .foregroundStyle(technique.iconColor)
                        
                        Text(technique.neuroscience)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                            .lineSpacing(3)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Impacto na Velocidade & Retenção", systemImage: "bolt.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.orange)
                        
                        Text(technique.practicalImpact)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                            .lineSpacing(3)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Como Utilizar no OneWord", systemImage: "hand.tap.fill")
                            .font(.caption.bold())
                            .foregroundStyle(.blue)
                        
                        Text(technique.howToUseInApp)
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                            .lineSpacing(3)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Botão de Expandir / Recolher
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Text(isExpanded ? "Ocultar detalhes científicos" : "Ver ciência e instruções")
                        .font(.caption.bold())
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2.bold())
                }
                .foregroundStyle(technique.iconColor)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.guideCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(technique.iconColor.opacity(0.15), lineWidth: 1)
        )
    }
}

private struct FeatureCategoryCardView: View {
    let category: FeatureCategoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Título da Categoria
            HStack(spacing: 8) {
                Image(systemName: category.iconName)
                    .font(.headline)
                    .foregroundStyle(category.tintColor)
                
                Text(category.title)
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                
                Spacer()
                
                Text("\(category.features.count) recursos")
                    .font(.caption2.bold())
                    .foregroundStyle(Color.secondary)
            }
            
            Divider()
            
            // Lista de Recursos
            VStack(spacing: 12) {
                ForEach(category.features) { feature in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(category.tintColor.opacity(0.12))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: feature.iconName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(category.tintColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text(feature.title)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(Color.primary)
                                
                                if feature.proFeature {
                                    Text("PRO")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.orange)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            Text(feature.description)
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                                .lineSpacing(2)
                        }
                        
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.guideCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Simulador Interativo em Tempo Real

private struct InteractiveReaderSimulatorCardView: View {
    public enum SimulatorMode: String, CaseIterable, Identifiable {
        case rsvp = "RSVP + ORP"
        case bionic = "Modo Biônico"
        case standard = "Tradicional"
        
        public var id: String { rawValue }
    }
    
    @State private var mode: SimulatorMode = .rsvp
    @State private var wpm: Double = 350
    @State private var isPlaying: Bool = false
    @State private var currentWordIndex: Int = 0
    @State private var timer: Timer? = nil
    
    private let sampleText: String = """
    A neurociência comprova que o cérebro humano processa ideias muito mais rápido do que a fala física consegue articular. Ao eliminar movimentos sacádicos e fixar o ponto foveal ótimo no leitor RSVP, você destrava foco profundo e absorve conhecimento em velocidade extraordinária.
    """
    
    private var words: [String] {
        sampleText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }
    
    var body: some View {
        VStack(spacing: 18) {
            // Cabeçalho do Simulador
            VStack(spacing: 4) {
                Text("Experimente as Técnicas na Prática")
                    .font(.headline)
                    .foregroundStyle(Color.primary)
                
                Text("Alterne os modos e veja como a percepção visual do texto muda instantaneamente.")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Seletor de Modo do Simulador
            Picker("Modo do Simulador", selection: $mode) {
                ForEach(SimulatorMode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            
            // Área de Visualização Dinâmica
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.simulatorScreenBackground)
                    .frame(height: 180)
                
                switch mode {
                case .rsvp:
                    rsvpDisplay
                case .bionic:
                    bionicDisplay
                case .standard:
                    standardDisplay
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            
            // Controles de Velocidade (para modo RSVP)
            if mode == .rsvp {
                VStack(spacing: 8) {
                    HStack {
                        Text("Velocidade do Fluxo:")
                            .font(.caption.bold())
                            .foregroundStyle(Color.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(wpm)) WPM")
                            .font(.subheadline.bold().monospacedDigit())
                            .foregroundStyle(.blue)
                    }
                    
                    Slider(value: $wpm, in: 150...700, step: 25)
                        .tint(.blue)
                        .onChange(of: wpm) { _, _ in
                            if isPlaying {
                                restartTimer()
                            }
                        }
                    
                    // Botão de Play/Pause
                    Button {
                        togglePlayPause()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            Text(isPlaying ? "Pausar Demonstração" : "Iniciar Projeção RSVP")
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isPlaying ? Color.red : Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text(mode == .bionic ? "Repare como as letras em negrito ancoram o olho e aceleram a leitura sem esforço." : "Modo tradicional com texto contínuo sem realces de fixação.")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .background(Color.guideCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onDisappear {
            stopTimer()
        }
    }
    
    // Display RSVP com Marcador ORP
    private var rsvpDisplay: some View {
        let currentWord = words[safe: currentWordIndex] ?? words.first ?? "OneWord"
        let split = ORPHelper.splitWord(currentWord)
        
        return VStack(spacing: 12) {
            // Mira Óptica Superior
            Rectangle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 2, height: 12)
            
            // Palavra com letra ORP destacada
            HStack(spacing: 0) {
                Text(split.prefix)
                    .foregroundStyle(Color.primary)
                
                Text(String(split.focalCharacter))
                    .foregroundStyle(Color.red)
                    .bold()
                
                Text(split.suffix)
                    .foregroundStyle(Color.primary)
            }
            .font(.system(size: 34, weight: .medium, design: .serif))
            
            // Mira Óptica Inferior
            Rectangle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 2, height: 12)
        }
    }
    
    // Display Bionic
    private var bionicDisplay: some View {
        ScrollView {
            Text(BionicReadingHelper.formatToAttributedString(sampleText, textColor: .primary))
                .font(.system(size: 15, design: .serif))
                .lineSpacing(5)
                .padding(14)
        }
    }
    
    // Display Tradicional
    private var standardDisplay: some View {
        ScrollView {
            Text(sampleText)
                .font(.system(size: 15, design: .serif))
                .lineSpacing(5)
                .padding(14)
                .foregroundStyle(Color.primary)
        }
    }
    
    private func togglePlayPause() {
        if isPlaying {
            stopTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        isPlaying = true
        restartTimer()
    }
    
    private func restartTimer() {
        timer?.invalidate()
        let interval = 60.0 / wpm
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                if currentWordIndex + 1 < words.count {
                    currentWordIndex += 1
                } else {
                    currentWordIndex = 0
                }
            }
        }
    }
    
    private func stopTimer() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }
}

// Extensão utilitária para acesso seguro por índice
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// Cores adaptativas para modo claro / escuro
private extension Color {
    static var guideGroupedBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .systemGroupedBackground)
        #else
        return Color(.windowBackgroundColor)
        #endif
    }
    
    static var guideCardBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .secondarySystemGroupedBackground)
        #else
        return Color(.controlBackgroundColor)
        #endif
    }
    
    static var simulatorScreenBackground: Color {
        #if canImport(UIKit)
        return Color(uiColor: .tertiarySystemGroupedBackground)
        #else
        return Color(.underPageBackgroundColor)
        #endif
    }
}

#Preview {
    ReadingGuideView()
}
