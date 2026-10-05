//
//  OneWordTests.swift
//  OneWordTests
//
//  Created for OneWord - RSVP Reader iOS MVP
//

import XCTest
import SwiftData
@testable import OneWord

final class OneWordTests: XCTestCase {
    
    // MARK: - Testes da Fase 1: Modelos SwiftData
    
    @MainActor
    func testDocumentCreationAndRelationships() throws {
        let sampleWords = ["A", "leitura", "rápida", "transforma", "o", "aprendizado."]
        let sampleRaw = "A leitura rápida transforma o aprendizado."
        
        let doc = Document(
            title: "Capítulo 1",
            rawText: sampleRaw,
            words: sampleWords,
            initialWordIndex: 0
        )
        
        XCTAssertEqual(doc.title, "Capítulo 1")
        XCTAssertEqual(doc.totalWords, 6)
        XCTAssertEqual(doc.currentWordIndex, 0)
        XCTAssertEqual(doc.currentWord, "A")
        XCTAssertEqual(doc.progressPercentage, 0.0)
        XCTAssertFalse(doc.isCompleted)
        
        // Verifica relacionamentos
        XCTAssertNotNil(doc.content)
        XCTAssertEqual(doc.content?.rawText, sampleRaw)
        XCTAssertEqual(doc.content?.words.count, 6)
        XCTAssertNotNil(doc.progress)
    }
    
    @MainActor
    func testReadingProgressUpdatesAndClamping() {
        let words = ["Um", "dois", "três", "quatro", "cinco."]
        let doc = Document(title: "Contagem", rawText: "Um dois três quatro cinco.", words: words)
        
        // Atualiza progresso
        doc.updateProgress(to: 2)
        XCTAssertEqual(doc.currentWordIndex, 2)
        XCTAssertEqual(doc.currentWord, "três")
        XCTAssertEqual(doc.progressPercentage, 0.4) // 2 / 5
        
        // Testa seek relativo
        doc.seekWord(by: 2)
        XCTAssertEqual(doc.currentWordIndex, 4)
        XCTAssertEqual(doc.currentWord, "cinco.")
        
        // Testa avanço além do limite superior (clamp)
        doc.seekWord(by: 10)
        XCTAssertEqual(doc.currentWordIndex, 5)
        XCTAssertTrue(doc.isCompleted)
        XCTAssertNil(doc.currentWord) // Finalizou o texto
        
        // Testa recuo além do limite inferior (clamp)
        doc.seekWord(by: -20)
        XCTAssertEqual(doc.currentWordIndex, 0)
        XCTAssertEqual(doc.currentWord, "Um")
    }
    
    @MainActor
    func testSentenceNavigation() {
        let raw = "Primeira frase aqui. Segunda frase começa agora! Terceira pergunta final?"
        let words = [
            "Primeira", "frase", "aqui.",
            "Segunda", "frase", "começa", "agora!",
            "Terceira", "pergunta", "final?"
        ]
        
        let doc = Document(title: "Frases", rawText: raw, words: words)
        XCTAssertEqual(doc.currentWordIndex, 0)
        
        // Avança frase: deve parar na primeira palavra da segunda frase
        doc.advanceSentence()
        XCTAssertEqual(doc.currentWordIndex, 3)
        XCTAssertEqual(doc.currentWord, "Segunda")
        
        // Avança mais uma frase: primeira palavra da terceira frase
        doc.advanceSentence()
        XCTAssertEqual(doc.currentWordIndex, 7)
        XCTAssertEqual(doc.currentWord, "Terceira")
        
        // Retrocede frase: volta para o início da frase atual ou anterior
        doc.rewindSentence()
        XCTAssertEqual(doc.currentWordIndex, 3)
        XCTAssertEqual(doc.currentWord, "Segunda")
        
        doc.rewindSentence()
        XCTAssertEqual(doc.currentWordIndex, 0)
        XCTAssertEqual(doc.currentWord, "Primeira")
    }
    
    @MainActor
    func testEstimatedReadingTimes() {
        let words = Array(repeating: "palavra", count: 600)
        let doc = Document(title: "600 Palavras", rawText: "", words: words)
        
        // A 300 WPM, 600 palavras devem levar exatamente 2.0 minutos
        XCTAssertEqual(doc.estimatedTotalReadingTimeMinutes(wpm: 300), 2.0, accuracy: 0.001)
        
        doc.updateProgress(to: 300)
        // Restam 300 palavras: 1.0 minuto
        XCTAssertEqual(doc.remainingReadingTimeMinutes(wpm: 300), 1.0, accuracy: 0.001)
    }
    
    @MainActor
    func testSwiftDataContainerPersistence() throws {
        let schema = Schema([Document.self, DocumentContent.self, ReadingProgress.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext
        
        let doc = Document(
            title: "Doc Persistido",
            rawText: "Texto de teste para persistência.",
            words: ["Texto", "de", "teste", "para", "persistência."]
        )
        context.insert(doc)
        try context.save()
        
        let descriptor = FetchDescriptor<Document>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Doc Persistido")
        XCTAssertEqual(fetched.first?.content?.words.count, 5)
    }
    
    // MARK: - Testes da Fase 2: OCR Parser e Tratamento de Texto
    
    func testTextParserDehyphenation() {
        let parser = TextParser()
        let hyphenatedRaw = """
        Este é um texto com desen-
        volvimento de software e carac-
        terísticas importantes.
        """
        
        let (cleaned, words) = parser.parse(rawText: hyphenatedRaw)
        
        XCTAssertTrue(cleaned.contains("desenvolvimento"))
        XCTAssertTrue(cleaned.contains("características"))
        XCTAssertFalse(cleaned.contains("desen-"))
        XCTAssertFalse(cleaned.contains("carac-"))
        XCTAssertTrue(words.contains("desenvolvimento"))
        XCTAssertTrue(words.contains("características"))
    }
    
    func testTextParserArtificialLineBreaks() {
        let parser = TextParser()
        let bookPageRaw = """
        A leitura RSVP projeta palavras no centro
        da tela para eliminar movimentos sacádicos dos olhos.
        
        Este é um segundo parágrafo independente que deve
        manter sua separação do anterior.
        """
        
        let (cleaned, words) = parser.parse(rawText: bookPageRaw)
        
        // Verifica que os dois parágrafos foram preservados com \n\n
        let paragraphs = cleaned.components(separatedBy: "\n\n")
        XCTAssertEqual(paragraphs.count, 2)
        
        // O primeiro parágrafo deve ter suas linhas unidas com espaço
        XCTAssertEqual(paragraphs[0], "A leitura RSVP projeta palavras no centro da tela para eliminar movimentos sacádicos dos olhos.")
        
        // Pontuações finais devem ser preservadas nas palavras para o motor RSVP
        XCTAssertTrue(words.contains("olhos."))
        XCTAssertTrue(words.contains("anterior."))
    }
    
    func testTextParserNoiseFiltering() {
        let parser = TextParser()
        let dirtyRaw = """
        Palavra um — •
        -
        Palavra dois!
        """
        
        let (_, words) = parser.parse(rawText: dirtyRaw)
        
        // Ruídos soltos como '•' ou '-' isolados devem ser descartados
        XCTAssertFalse(words.contains("•"))
        XCTAssertFalse(words.contains("-"))
        XCTAssertEqual(words, ["Palavra", "um", "Palavra", "dois!"])
    }
    
    func testOCRResultSuggestedTitle() {
        let result = OCRResult(
            rawText: "O Princípio da Relatividade Geral de Albert Einstein...",
            cleanedText: "O Princípio da Relatividade Geral de Albert Einstein...",
            words: ["O", "Princípio", "da", "Relatividade", "Geral", "de", "Albert", "Einstein."],
            averageConfidence: 0.98
        )
        
        XCTAssertEqual(result.wordCount, 8)
        XCTAssertEqual(result.suggestedTitle, "O Princípio da Relatividade Geral de")
    }
    
    func testOCRErrorDescriptions() {
        let err = OCRError.noTextDetected
        XCTAssertNotNil(err.errorDescription)
        XCTAssertNotNil(err.recoverySuggestion)
        XCTAssertEqual(err, OCRError.noTextDetected)
    }
    
    // MARK: - Testes da Fase 3: Motor RSVP e Pausas Dinâmicas
    
    func testRSVPConfigurationDurations() {
        var config = RSVPConfiguration(wpm: 300) // Base: 60 / 300 = 0.200s (200ms)
        XCTAssertEqual(config.baseInterval, 0.200, accuracy: 0.001)
        
        // Palavra normal sem pontuação: duração base (200ms)
        let normalWordDuration = config.duration(for: "leitura")
        XCTAssertEqual(normalWordDuration, 0.200, accuracy: 0.001)
        
        // Palavra terminada em vírgula: base + 120ms = 320ms (Requisito: ~100-150ms)
        let commaWordDuration = config.duration(for: "atenção,")
        XCTAssertEqual(commaWordDuration, 0.320, accuracy: 0.001)
        
        // Palavra curta terminada em ponto final: base (200ms) + 250ms = 450ms (Requisito: ~200-300ms)
        let shortPeriodDuration = config.duration(for: "fim.")
        XCTAssertEqual(shortPeriodDuration, 0.450, accuracy: 0.001)
        
        // Palavra longa (>10 letras) terminada em ponto final: base (200ms) + 250ms + 50ms bônus = 500ms
        let longPeriodDuration = config.duration(for: "compreensão.")
        XCTAssertEqual(longPeriodDuration, 0.500, accuracy: 0.001)
        
        // Palavra terminada em exclamação
        let exclamationWordDuration = config.duration(for: "rápido!")
        XCTAssertEqual(exclamationWordDuration, 0.450, accuracy: 0.001)
        
        // Palavra terminada em interrogação
        let questionWordDuration = config.duration(for: "entendeu?")
        XCTAssertEqual(questionWordDuration, 0.450, accuracy: 0.001)
        
        // Com pausas dinâmicas desativadas: sempre retorna baseInterval
        config.enableDynamicPauses = false
        XCTAssertEqual(config.duration(for: "entendeu?"), 0.200, accuracy: 0.001)
    }
    
    func testORPHelper() {
        // Palavra de 1 caractere: ORP no índice 0
        let singleChar = ORPHelper.splitWord("a")
        XCTAssertEqual(singleChar.prefix, "")
        XCTAssertEqual(singleChar.focalCharacter, "a")
        XCTAssertEqual(singleChar.suffix, "")
        
        // Palavra de 7 caracteres ("leitura"): ORP no índice 2 ('i')
        let word = ORPHelper.splitWord("leitura")
        XCTAssertEqual(word.prefix, "le")
        XCTAssertEqual(word.focalCharacter, "i")
        XCTAssertEqual(word.suffix, "tura")
        XCTAssertEqual(word.focalIndex, 2)
    }
    
    @MainActor
    func testRSVPEnginePlaybackControlsAndSeeking() {
        let engine = RSVPEngine(config: RSVPConfiguration(wpm: 300))
        let sampleWords = [
            "O", "método", "RSVP", "funciona.",
            "Ele", "projeta", "palavras", "sequenciais,",
            "permitindo", "leitura", "veloz!"
        ]
        
        engine.load(words: sampleWords, initialIndex: 0)
        XCTAssertEqual(engine.state, .idle)
        XCTAssertEqual(engine.currentIndex, 0)
        XCTAssertEqual(engine.currentWord, "O")
        XCTAssertFalse(engine.isCompleted)
        
        // Avança 1 palavra
        engine.stepForward()
        XCTAssertEqual(engine.currentIndex, 1)
        XCTAssertEqual(engine.currentWord, "método")
        
        // Salta frase: deve parar em "Ele" (após "funciona.")
        engine.advanceSentence()
        XCTAssertEqual(engine.currentIndex, 4)
        XCTAssertEqual(engine.currentWord, "Ele")
        
        // Salta para a próxima frase: deve parar em "permitindo" (após pontuação ou fim)
        engine.advanceSentence()
        XCTAssertEqual(engine.currentIndex, 11) // Foi até o final
        XCTAssertTrue(engine.isCompleted)
        
        // Retrocede frase
        engine.rewindSentence()
        XCTAssertEqual(engine.currentIndex, 4)
        XCTAssertEqual(engine.currentWord, "Ele")
        
        // Botão -10 palavras: como está no índice 4, deve dar clamp em 0
        engine.stepBackward(count: 10)
        XCTAssertEqual(engine.currentIndex, 0)
        XCTAssertEqual(engine.currentWord, "O")
    }
    
    // MARK: - Testes da Fase 4 & Evoluções: Telemetria, Estatísticas e Speed Ramp
    
    func testReadingSessionMetrics() {
        let session = ReadingSession(
            durationSeconds: 120.0, // 2 minutos
            wordsRead: 800,        // 400 WPM
            averageWPM: 400,
            documentTitle: "Teste"
        )
        
        // Linha de base a 200 WPM: 800 palavras levariam 4 minutos (240s)
        XCTAssertEqual(session.baselineDurationSeconds, 240.0, accuracy: 0.001)
        // Tempo economizado: 240 - 120 = 120 segundos
        XCTAssertEqual(session.timeSavedSeconds, 120.0, accuracy: 0.001)
    }
    
    @MainActor
    func testStatsViewModelCalculations() {
        let vm = StatsViewModel()
        
        let now = Date()
        let calendar = Calendar.current
        
        let s1 = ReadingSession(
            date: now,
            durationSeconds: 60.0,
            wordsRead: 400,
            averageWPM: 400,
            documentTitle: "Doc 1"
        )
        let s2 = ReadingSession(
            date: calendar.date(byAdding: .day, value: -1, to: now)!,
            durationSeconds: 60.0,
            wordsRead: 300,
            averageWPM: 300,
            documentTitle: "Doc 2"
        )
        let sessions = [s1, s2]
        
        XCTAssertEqual(vm.totalWords(from: sessions), 700)
        XCTAssertEqual(vm.totalMinutesRead(from: sessions), 2.0, accuracy: 0.001)
        // s1 economizou 60s, s2 economizou 30s. Total: 90s = 1.5 minutos
        XCTAssertEqual(vm.totalMinutesSaved(from: sessions), 1.5, accuracy: 0.001)
        // 700 palavras em 120 segundos = 350 WPM médio
        XCTAssertEqual(vm.averageWPM(from: sessions), 350)
        // Ofensiva: 2 dias consecutivos
        XCTAssertEqual(vm.readingStreak(from: sessions), 2)
        
        // Métricas diárias para Swift Charts
        let daily = vm.dailyMetrics(from: sessions)
        XCTAssertEqual(daily.count, 7)
        let totalWordsInChart = daily.reduce(0) { $0 + $1.words }
        XCTAssertEqual(totalWordsInChart, 700)
    }
    
    func testSpeedRampConfiguration() {
        let config = RSVPConfiguration(
            wpm: 300,
            speedRampEnabled: true,
            speedRampIntervalWords: 20,
            speedRampDeltaWPM: 25,
            speedRampMaxWPM: 600
        )
        
        XCTAssertTrue(config.speedRampEnabled)
        XCTAssertEqual(config.speedRampIntervalWords, 20)
        XCTAssertEqual(config.speedRampDeltaWPM, 25)
        XCTAssertEqual(config.speedRampMaxWPM, 600)
    }
    
    // MARK: - Testes da Biblioteca de Livros (Multi-Páginas, Capas e RSVP Híbrido)
    
    @MainActor
    func testBookCreationAndPageOffsets() {
        let book = Book(
            title: "Dom Casmurro",
            author: "Machado de Assis",
            coverThemeColor: "#881337"
        )
        
        XCTAssertEqual(book.title, "Dom Casmurro")
        XCTAssertEqual(book.author, "Machado de Assis")
        XCTAssertEqual(book.coverThemeColor, "#881337")
        XCTAssertNil(book.coverImageData)
        XCTAssertEqual(book.totalPages, 0)
        XCTAssertEqual(book.totalWords, 0)
        
        // Adiciona Página 1 (3 palavras)
        let p1 = book.addPage(rawText: "Uma noite destas,", words: ["Uma", "noite", "destas,"])
        XCTAssertEqual(p1.pageNumber, 1)
        XCTAssertEqual(p1.wordCount, 3)
        
        // Adiciona Página 2 (4 palavras)
        let p2 = book.addPage(rawText: "vindo da cidade para", words: ["vindo", "da", "cidade", "para"])
        XCTAssertEqual(p2.pageNumber, 2)
        XCTAssertEqual(p2.wordCount, 4)
        
        // Adiciona Página 3 (3 palavras)
        let p3 = book.addPage(rawText: "o Engenho Novo.", words: ["o", "Engenho", "Novo."])
        XCTAssertEqual(p3.pageNumber, 3)
        XCTAssertEqual(p3.wordCount, 3)
        
        XCTAssertEqual(book.totalPages, 3)
        XCTAssertEqual(book.totalWords, 10)
        XCTAssertEqual(book.allWords.count, 10)
        
        // Testa offsets das páginas: Página 1 inicia em 0, Página 2 em 3, Página 3 em 7
        XCTAssertEqual(book.pageOffsets, [0, 3, 7])
        
        // Testa salto para página específica (Modo Híbrido)
        XCTAssertEqual(book.globalWordIndex(forPageNumber: 1), 0)
        XCTAssertEqual(book.globalWordIndex(forPageNumber: 2), 3)
        XCTAssertEqual(book.globalWordIndex(forPageNumber: 3), 7)
        
        // Testa cálculo de página atual conforme o índice avança
        book.updateProgress(to: 0)
        XCTAssertEqual(book.currentPageNumber, 1)
        
        book.updateProgress(to: 2)
        XCTAssertEqual(book.currentPageNumber, 1)
        
        book.updateProgress(to: 3) // Primeira palavra da página 2
        XCTAssertEqual(book.currentPageNumber, 2)
        
        book.updateProgress(to: 6) // Última palavra da página 2
        XCTAssertEqual(book.currentPageNumber, 2)
        
        book.updateProgress(to: 7) // Primeira palavra da página 3
        XCTAssertEqual(book.currentPageNumber, 3)
        
        book.updateProgress(to: 10) // Concluído
        XCTAssertEqual(book.currentPageNumber, 3)
        XCTAssertTrue(book.isCompleted)
        XCTAssertEqual(book.progressPercentage, 1.0)
    }
    
    @MainActor
    func testRSVPReaderViewModelWithBookAndPageJump() {
        let book = Book(title: "Manual de Astrofísica", author: "Carl Sagan")
        book.addPage(rawText: "O cosmos é tudo.", words: ["O", "cosmos", "é", "tudo."]) // 4 palavras (idx 0..3)
        book.addPage(rawText: "Somos poeira estelar.", words: ["Somos", "poeira", "estelar."]) // 3 palavras (idx 4..6)
        
        // Inicia leitura saltando diretamente para a Página 2 (Modo Híbrido)
        let vm = RSVPReaderViewModel(book: book, startPageNumber: 2, initialWPM: 300)
        XCTAssertEqual(vm.currentIndex, 4)
        XCTAssertEqual(vm.currentWord, "Somos")
        XCTAssertEqual(vm.title, "Manual de Astrofísica")
        XCTAssertEqual(vm.subtitle, "Página 2 de 2")
        
        // Avança uma palavra
        vm.stepForward()
        XCTAssertEqual(vm.currentIndex, 5)
        XCTAssertEqual(vm.currentWord, "poeira")
        XCTAssertEqual(book.currentGlobalWordIndex, 5)
    }
    
    // MARK: - Testes de Tradução e Idiomas Internacionais
    
    func testLanguageDetection() {
        let service = BookTranslationService()
        
        let enText = "Deep work is the ability to focus without distraction on a cognitively demanding task."
        XCTAssertEqual(service.detectLanguage(for: enText), "en")
        
        let ptText = "A técnica RSVP permite leitura dinâmica e foco cognitivo cirúrgico."
        XCTAssertEqual(service.detectLanguage(for: ptText), "pt")
        
        let infoEN = BookTranslationService.languageInfo(for: "en")
        XCTAssertEqual(infoEN.name, "Inglês")
        XCTAssertEqual(infoEN.flag, "🇺🇸")
        XCTAssertFalse(infoEN.isPortuguese)
        
        let infoPT = BookTranslationService.languageInfo(for: "pt")
        XCTAssertEqual(infoPT.name, "Português")
        XCTAssertEqual(infoPT.flag, "🇧🇷")
        XCTAssertTrue(infoPT.isPortuguese)
    }
    
    @MainActor
    func testBookPageTranslationAndActiveWords() {
        let page = BookPage(
            pageNumber: 1,
            rawText: "Focus is power.",
            words: ["Focus", "is", "power."],
            originalLanguage: "en"
        )
        
        XCTAssertEqual(page.activeWords, ["Focus", "is", "power."])
        XCTAssertFalse(page.isShowingTranslation)
        
        // Aplica tradução
        page.setTranslation(
            text: "Foco é poder.",
            words: ["Foco", "é", "poder."]
        )
        
        XCTAssertTrue(page.isShowingTranslation)
        XCTAssertEqual(page.activeWords, ["Foco", "é", "poder."])
        XCTAssertEqual(page.activeRawText, "Foco é poder.")
        
        // Limpa tradução
        page.clearTranslation()
        XCTAssertFalse(page.isShowingTranslation)
        XCTAssertEqual(page.activeWords, ["Focus", "is", "power."])
    }
    
    @MainActor
    func testBookTranslationToggleAndWordAggregation() {
        let book = Book(title: "Deep Work", author: "Cal Newport", detectedLanguageCode: "en")
        let p1 = book.addPage(rawText: "Deep work matters.", words: ["Deep", "work", "matters."])
        
        XCTAssertTrue(book.isForeignLanguage)
        XCTAssertEqual(book.detectedLanguageInfo.name, "Inglês")
        XCTAssertFalse(book.hasTranslation)
        XCTAssertEqual(book.allWords, ["Deep", "work", "matters."])
        
        // Aplica tradução à página 1
        p1.setTranslation(text: "Trabalho focado importa.", words: ["Trabalho", "focado", "importa."])
        XCTAssertTrue(book.hasTranslation)
        
        // Ativa tradução no livro
        book.toggleTranslation(active: true)
        XCTAssertTrue(book.isTranslationActive)
        XCTAssertEqual(book.allWords, ["Trabalho", "focado", "importa."])
        
        // Desativa para voltar ao original
        book.toggleTranslation(active: false)
        XCTAssertFalse(book.isTranslationActive)
        XCTAssertEqual(book.allWords, ["Deep", "work", "matters."])
    }
    
    @MainActor
    func testRSVPReaderViewModelTranslationToggle() {
        let book = Book(title: "The Art of Focus", author: "Author", detectedLanguageCode: "en")
        let page = book.addPage(rawText: "Focus creates clarity.", words: ["Focus", "creates", "clarity."])
        page.setTranslation(text: "O foco cria clareza.", words: ["O", "foco", "cria", "clareza."])
        
        // Inicia leitor com texto original
        let vm = RSVPReaderViewModel(book: book, initialWPM: 300)
        XCTAssertTrue(vm.hasTranslation)
        XCTAssertFalse(vm.isTranslationActive)
        XCTAssertEqual(vm.currentWord, "Focus")
        
        // Alterna tradução para Português em tempo real
        vm.toggleTranslation()
        XCTAssertTrue(vm.isTranslationActive)
        XCTAssertEqual(vm.currentWord, "O")
        
        // Alterna de volta para Inglês
        vm.toggleTranslation()
        XCTAssertFalse(vm.isTranslationActive)
        XCTAssertEqual(vm.currentWord, "Focus")
    }
    
    @MainActor
    func testDocumentTranslationAndLanguageDetection() {
        let englishText = "The ability to perform deep work is becoming increasingly rare at exactly the same time it is becoming increasingly valuable in our economy."
        let words = englishText.split(separator: " ").map(String.init)
        
        let doc = Document(title: "Deep Work Article", rawText: englishText, words: words)
        
        XCTAssertTrue(doc.isForeignLanguage)
        XCTAssertEqual(doc.detectedLanguageCode, "en")
        XCTAssertEqual(doc.detectedLanguageInfo.name, "Inglês")
        XCTAssertEqual(doc.detectedLanguageInfo.flag, "🇺🇸")
        XCTAssertFalse(doc.hasTranslation)
        XCTAssertFalse(doc.isTranslationActive)
        XCTAssertEqual(doc.totalWords, words.count)
        
        // Aplica tradução
        let portugueseText = "A habilidade de realizar trabalho focado está se tornando cada vez mais rara exatamente no mesmo momento em que se torna mais valiosa."
        let ptWords = portugueseText.split(separator: " ").map(String.init)
        doc.applyTranslation(text: portugueseText, words: ptWords)
        
        XCTAssertTrue(doc.hasTranslation)
        XCTAssertTrue(doc.isTranslationActive)
        XCTAssertEqual(doc.totalWords, ptWords.count)
        XCTAssertEqual(doc.activeWords.first, "A")
        
        // Desativa tradução
        doc.toggleTranslation(active: false)
        XCTAssertFalse(doc.isTranslationActive)
        XCTAssertEqual(doc.totalWords, words.count)
        XCTAssertEqual(doc.activeWords.first, "The")
    }
    
    @MainActor
    func testRSVPReaderViewModelDocumentAutoTranslation() {
        let englishText = "Focus is the new superpower."
        let words = ["Focus", "is", "the", "new", "superpower."]
        let doc = Document(title: "Superpower Article", rawText: englishText, words: words)
        
        let vm = RSVPReaderViewModel(document: doc, initialWPM: 300)
        XCTAssertTrue(vm.isForeignLanguage)
        XCTAssertEqual(vm.originalLanguageFlag, "🇺🇸")
        XCTAssertFalse(vm.hasTranslation)
        XCTAssertFalse(vm.isTranslationActive)
        
        // Dispara tradução instantânea via toggle
        vm.toggleTranslation()
        XCTAssertTrue(vm.hasTranslation)
        XCTAssertTrue(vm.isTranslationActive)
        XCTAssertEqual(vm.currentWord, "Foco")
        
        // Alterna de volta para o original
        vm.toggleTranslation()
        XCTAssertFalse(vm.isTranslationActive)
        XCTAssertEqual(vm.currentWord, "Focus")
    }
    
    @MainActor
    func testSeedArticleTranslationAndActiveWordsInReader() {
        let seedText = """
        If you want to do great work, the most important thing is to choose a problem you have a natural aptitude for and a deep interest in.
        There is an immense amount of ambition in the world, but focused effort directed toward meaningful problems is exceptionally rare.
        By cultivating consistent habits and eliminating peripheral noise, your ability to create lasting value expands exponentially.
        """
        let parser = TextParser()
        let (_, words) = parser.parse(rawText: seedText)
        let doc = Document(title: "How to Do Great Work", rawText: seedText, words: words, originalLanguage: "en")
        
        XCTAssertTrue(doc.isForeignLanguage)
        XCTAssertEqual(doc.detectedLanguageInfo.code, "en")
        XCTAssertEqual(doc.detectedLanguageInfo.flag, "🇺🇸")
        XCTAssertFalse(doc.hasTranslation)
        XCTAssertTrue(doc.previewSnippet().contains("If you want to do great work"))
        
        // Aplica tradução do fallback
        let translated = BookTranslationFallback.translate(text: seedText, from: "en")
        let (_, translatedWords) = parser.parse(rawText: translated)
        doc.applyTranslation(text: translated, words: translatedWords)
        
        XCTAssertTrue(doc.hasTranslation)
        XCTAssertTrue(doc.isTranslationActive)
        // Snippet deve refletir o texto ativo em português
        XCTAssertTrue(doc.previewSnippet().contains("Se você deseja realizar um grande trabalho"))
        
        // Abre o leitor com a tradução já ativada no documento
        let vm = RSVPReaderViewModel(document: doc, initialWPM: 300)
        XCTAssertTrue(vm.isTranslationActive)
        XCTAssertEqual(vm.subtitle, "🇧🇷 Português (Traduzido)")
        XCTAssertEqual(vm.currentWord, "Se")
        XCTAssertEqual(vm.totalWords, translatedWords.count)
        
        // Desativa a tradução e confirma retorno para o original em inglês
        vm.toggleTranslation()
        XCTAssertFalse(vm.isTranslationActive)
        XCTAssertEqual(vm.subtitle, "🇺🇸 Inglês (Original)")
        XCTAssertEqual(vm.currentWord, "If")
        XCTAssertEqual(vm.totalWords, words.count)
    }
    
    // MARK: - Testes da Fase 4: Ingestão de Novos Formatos (ePub & Web)
    
    func testEPUBParserHTMLCleaningAndEntityDecoding() {
        let parser = EPUBParser()
        let sampleHTML = """
        <html>
        <head><title>Capítulo Teste</title><style>.hidden { display: none; }</style></head>
        <body>
            <script>console.log('ignored');</script>
            <h1>O Poder do Hábito</h1>
            <p>Ler &amp; aprender &mdash; um processo cont&iacute;nuo.</p>
            <p>Palavra &quot;chave&quot; no RSVP.</p>
        </body>
        </html>
        """
        
        let cleaned = parser.extractCleanText(fromHTML: sampleHTML)
        XCTAssertFalse(cleaned.contains("<script>"))
        XCTAssertFalse(cleaned.contains("<style>"))
        XCTAssertFalse(cleaned.contains("&amp;"))
        XCTAssertTrue(cleaned.contains("Ler & aprender — um processo contínuo."))
        XCTAssertTrue(cleaned.contains("Palavra \"chave\" no RSVP."))
    }
    
    @MainActor
    func testEPUBImportServicePlainTextImport() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Book.self, BookPage.self, ReadingSession.self, configurations: config)
        let context = container.mainContext
        
        let sampleText = """
        Capítulo Primeiro.
        Este é um texto importado com sucesso para a biblioteca do OneWord.
        Cada capítulo gera páginas foveais confortáveis para o motor RSVP.
        """
        
        let book = try EPUBImportService().importPlainText(text: sampleText, title: "Ensaio Foveal", author: "Pesquisador", context: context)
        
        XCTAssertEqual(book.title, "Ensaio Foveal")
        XCTAssertEqual(book.author, "Pesquisador")
        XCTAssertFalse(book.pages.isEmpty)
        XCTAssertGreaterThan(book.totalWords, 0)
    }
    
    func testWebArticleExtractorFromHTML() {
        let extractor = WebArticleExtractor()
        let articleHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta property="og:title" content="A Revolução da Atenção Foveal" />
            <meta name="author" content="Dr. Silveira" />
        </head>
        <body>
            <nav><a href="/home">Home</a></nav>
            <article>
                <h1>A Revolução da Atenção Foveal</h1>
                <p>A fóvea representa o ponto crítico de acuidade da retina humana.</p>
                <p>Eliminando a dispersão sacádica, a velocidade de leitura dispara.</p>
            </article>
            <footer>Copyright 2026</footer>
        </body>
        </html>
        """
        
        let article = extractor.extract(fromHTML: articleHTML)
        XCTAssertEqual(article.title, "A Revolução da Atenção Foveal")
        XCTAssertEqual(article.author, "Dr. Silveira")
        XCTAssertTrue(article.words.contains("fóvea"))
        XCTAssertTrue(article.words.contains("retina"))
        XCTAssertFalse(article.words.contains("Copyright"))
        XCTAssertGreaterThan(article.wordCount, 10)
    }
    
    // MARK: - Testes da Fase 4: Ergonomia Cognitiva & Smart WPM
    
    func testAdaptiveReadingPacerCognitiveLoad() {
        let pacer = AdaptiveReadingPacer()
        
        // Palavra curta comum ("de") vs palavra longa ("extraordinariamente")
        let shortWordFactor = pacer.cognitiveLoadMultiplier(for: "de")
        let longWordFactor = pacer.cognitiveLoadMultiplier(for: "extraordinariamente")
        XCTAssertLessThan(shortWordFactor, longWordFactor)
        
        // Pontuação forte (ponto final) vs palavra intermediária
        let commaFactor = pacer.cognitiveLoadMultiplier(for: "pausa,")
        let periodFactor = pacer.cognitiveLoadMultiplier(for: "conclusão.")
        XCTAssertGreaterThan(periodFactor, commaFactor)
        
        // Número com dígitos
        let numberFactor = pacer.cognitiveLoadMultiplier(for: "2026")
        XCTAssertGreaterThan(numberFactor, 1.0)
        
        // Duração adaptativa calculada
        let durShort = pacer.duration(for: "o", baseWPM: 300, isSmartWPMEnabled: true)
        let durLong = pacer.duration(for: "extraordinariamente.", baseWPM: 300, isSmartWPMEnabled: true)
        XCTAssertLessThan(durShort, durLong)
    }
    
    @MainActor
    func testRSVPEngineMultiWordChunking() {
        var config = RSVPConfiguration(wpm: 300)
        config.chunkSize = 2
        
        let engine = RSVPEngine(config: config)
        let words = ["A", "leitura", "acelerada", "amplia", "o", "foco."]
        engine.load(words: words)
        
        XCTAssertEqual(engine.currentChunkWords, ["A", "leitura"])
        XCTAssertEqual(engine.currentChunkText, "A leitura")
        
        // Avança 2 palavras (tamanho do chunk)
        engine.seek(to: 2)
        XCTAssertEqual(engine.currentChunkWords, ["acelerada", "amplia"])
        
        // Avança para o final
        engine.seek(to: 4)
        XCTAssertEqual(engine.currentChunkWords, ["o", "foco."])
    }
    
    // MARK: - Testes da Fase 4: Hábitos, Streaks & Benchmark
    
    @MainActor
    func testReadingHabitTrackerStreakCalculation() {
        let tracker = ReadingHabitTracker()
        
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        let session1 = ReadingSession(date: today, durationSeconds: 300, wordsRead: 1500, averageWPM: 300, documentTitle: "Doc 1")
        let session2 = ReadingSession(date: yesterday, durationSeconds: 240, wordsRead: 1200, averageWPM: 300, documentTitle: "Doc 2")
        let session3 = ReadingSession(date: twoDaysAgo, durationSeconds: 180, wordsRead: 900, averageWPM: 300, documentTitle: "Doc 3")
        
        let streak = tracker.calculateStreak(from: [session1, session2, session3])
        XCTAssertEqual(streak, 3)
        
        let wordsToday = tracker.wordsReadToday(from: [session1, session2, session3])
        XCTAssertEqual(wordsToday, 1500)
    }
    
    @MainActor
    func testReadingHabitTrackerAchievements() {
        let tracker = ReadingHabitTracker()
        
        let session = ReadingSession(date: Date(), durationSeconds: 600, wordsRead: 6000, averageWPM: 400, documentTitle: "Livro 1")
        let achievements = tracker.evaluateAchievements(sessions: [session])
        
        let firstFocus = achievements.first(where: { $0.id == "first_focus" })
        XCTAssertEqual(firstFocus?.isUnlocked, true)
        
        let barrier350 = achievements.first(where: { $0.id == "barrier_350" })
        XCTAssertEqual(barrier350?.isUnlocked, true)
        
        let words5k = achievements.first(where: { $0.id == "words_5k" })
        XCTAssertEqual(words5k?.isUnlocked, true)
    }
    
    @MainActor
    func testWPMBenchmarkScoringAndEffectiveWPM() {
        let vm = WPMBenchmarkViewModel(initialWPM: 400)
        
        // Responde todas as 4 perguntas corretamente
        vm.selectAnswer(questionId: 1, optionIndex: 0)
        vm.selectAnswer(questionId: 2, optionIndex: 1)
        vm.selectAnswer(questionId: 3, optionIndex: 0)
        vm.selectAnswer(questionId: 4, optionIndex: 0)
        
        XCTAssertTrue(vm.isAllQuestionsAnswered)
        XCTAssertEqual(vm.correctAnswersCount, 4)
        XCTAssertEqual(vm.accuracyPercentage, 1.0)
        XCTAssertEqual(vm.effectiveWPM, 400)
        
        vm.finishBenchmark()
        XCTAssertEqual(vm.currentStage, .results)
        
        // Simula 2 acertos de 4 (50%)
        let vmPartial = WPMBenchmarkViewModel(initialWPM: 400)
        vmPartial.selectAnswer(questionId: 1, optionIndex: 0)
        vmPartial.selectAnswer(questionId: 2, optionIndex: 0) // Errada
        vmPartial.selectAnswer(questionId: 3, optionIndex: 0)
        vmPartial.selectAnswer(questionId: 4, optionIndex: 1) // Errada
        
        XCTAssertEqual(vmPartial.correctAnswersCount, 2)
        XCTAssertEqual(vmPartial.accuracyPercentage, 0.5)
        XCTAssertEqual(vmPartial.effectiveWPM, 200)
    }
    
    // MARK: - Testes das Novas Frentes: Leitura Biônica, IA no Dispositivo & StoreKit 2
    
    func testBionicReadingHelperSplitting() {
        // Palavra curta de 1 caractere: todo em negrito
        let oneChar = BionicReadingHelper.splitWord("a")
        XCTAssertEqual(oneChar.prefix, "a")
        XCTAssertEqual(oneChar.suffix, "")
        
        // Palavra de 3 caracteres: 1 caractere em negrito
        let threeChars = BionicReadingHelper.splitWord("que")
        XCTAssertEqual(threeChars.prefix, "q")
        XCTAssertEqual(threeChars.suffix, "ue")
        
        // Palavra de 6 caracteres: 2 caracteres em negrito (regra 4...6)
        let sixChars = BionicReadingHelper.splitWord("rápida")
        XCTAssertEqual(sixChars.prefix.count, 2)
        XCTAssertEqual(sixChars.prefix + sixChars.suffix, "rápida")
        
        // Palavra com pontuação no final
        let withPunct = BionicReadingHelper.splitWord("atenção.")
        XCTAssertEqual(withPunct.prefix + withPunct.suffix, "atenção.")
        XCTAssertFalse(withPunct.prefix.contains("."))
    }
    
    func testBionicReadingAttributedFormatting() {
        let text = "A leitura rápida transforma o foco."
        let attributed = BionicReadingHelper.formatToAttributedString(text)
        XCTAssertFalse(attributed.characters.isEmpty)
    }
    
    func testTextSummarizerExecutiveSummary() {
        let sample = """
        A neuroplasticidade é a capacidade do sistema nervoso de mudar sua atividade em resposta a estímulos intrínsecos ou extrínsecos.
        Isso é feito através da reorganização de sua estrutura, funções ou conexões neuronais.
        Durante a leitura com o método RSVP, o cérebro elimina o esforço muscular dos movimentos sacádicos.
        Com isso, a retenção de conceitos densos pode ser mantida com menor fadiga cognitiva.
        A prática constante de leitura acelerada treina a fóvea ocular e amplia o processamento semântico.
        """
        
        let summarizer = TextSummarizerService.shared
        let summary = summarizer.summarize(text: sample, maxSentences: 3)
        
        XCTAssertLessThanOrEqual(summary.count, 3)
        XCTAssertGreaterThanOrEqual(summary.count, 1)
        // Deve selecionar frases significativas
        XCTAssertTrue(summary.contains { $0.contains("RSVP") || $0.contains("neuroplasticidade") || $0.contains("leitura") })
    }
    
    func testFlashcardSM2Progression() {
        var card = Flashcard(
            front: "O que é RSVP?",
            back: "Rapid Serial Visual Presentation, método de leitura rápida serial.",
            sourceTitle: "Guia de Leitura"
        )
        
        XCTAssertEqual(card.repetitionCount, 0)
        XCTAssertEqual(card.intervalDays, 1)
        XCTAssertEqual(card.easeFactor, 2.5, accuracy: 0.001)
        
        // 1ª Avaliação: Good
        card.review(rating: .good)
        XCTAssertEqual(card.repetitionCount, 1)
        XCTAssertEqual(card.intervalDays, 1)
        XCTAssertEqual(card.easeFactor, 2.5, accuracy: 0.001)
        
        // 2ª Avaliação: Good
        card.review(rating: .good)
        XCTAssertEqual(card.repetitionCount, 2)
        XCTAssertEqual(card.intervalDays, 4)
        
        // 3ª Avaliação: Again -> reinicia contagem
        card.review(rating: .again)
        XCTAssertEqual(card.repetitionCount, 0)
        XCTAssertEqual(card.intervalDays, 1)
    }
    
    func testDynamicQuizGeneration() {
        let sampleText = """
        A velocidade média de leitura convencional gira em torno de 200 a 250 palavras por minuto.
        O método RSVP projeta uma palavra de cada vez no ponto óptico de reconhecimento.
        Com essa técnica, a taxa de fixação visual é otimizada e o tempo gasto em saltos sacádicos é eliminado.
        Estudos demonstram que a compreensão de textos técnicos pode atingir mais de 500 palavras por minuto.
        """
        
        let quizService = DynamicQuizService()
        let questions = quizService.generateQuiz(from: sampleText, title: "Teste RSVP", count: 2)
        
        XCTAssertEqual(questions.count, 2)
        for question in questions {
            XCTAssertEqual(question.options.count, 3)
            XCTAssertGreaterThanOrEqual(question.correctIndex, 0)
            XCTAssertLessThan(question.correctIndex, 3)
            XCTAssertTrue(question.text.contains("Complete o sentido"))
        }
    }
    
    @MainActor
    func testEyeTrackingFatigueDismissal() {
        let manager = EyeTrackingManager.shared
        manager.isFatigueRestSuggested = true
        XCTAssertTrue(manager.isFatigueRestSuggested)
        
        manager.dismissFatigueSuggestion()
        XCTAssertFalse(manager.isFatigueRestSuggested)
    }
    
    // MARK: - Testes de Neurociência Cognitiva da Leitura
    
    func testAdaptiveReadingPacerSynapticPauses() {
        let pacer = AdaptiveReadingPacer()
        let baseWPM = 300 // base duration = 0.200s
        
        let normalDuration = pacer.duration(for: "leitura", baseWPM: baseWPM, isSmartWPMEnabled: true)
        let sentenceEndDuration = pacer.duration(for: "aprendizado.", baseWPM: baseWPM, isSmartWPMEnabled: true)
        let paragraphEndDuration = pacer.duration(for: "conclusão.", baseWPM: baseWPM, isSmartWPMEnabled: true, isEndOfParagraph: true)
        let ellipsisDuration = pacer.duration(for: "continua...", baseWPM: baseWPM, isSmartWPMEnabled: true)
        
        // Pausa sináptica de fim de oração deve ser significativamente maior que palavra intermediária
        XCTAssertGreaterThan(sentenceEndDuration, normalDuration * 1.5)
        // Pausa sináptica de parágrafo deve ser ainda maior para consolidação do modelo de situação
        XCTAssertGreaterThan(paragraphEndDuration, sentenceEndDuration)
        // Reticências demandam suspensão reflexiva
        XCTAssertGreaterThan(ellipsisDuration, normalDuration)
    }
    
    @MainActor
    func testStatsViewModelEffectiveWPM() {
        let habit = ReadingHabitTracker.shared
        habit.recordBenchmarkResult(wpm: 400, scorePercentage: 0.75)
        
        XCTAssertEqual(habit.lastBenchmarkWPM, 400)
        XCTAssertEqual(habit.lastBenchmarkScore, 0.75)
        XCTAssertEqual(habit.lastEffectiveWPM, 300) // 400 * 0.75 = 300 eWPM
        
        let statsVM = StatsViewModel()
        XCTAssertEqual(statsVM.benchmarkEffectiveWPM, 300)
        XCTAssertEqual(statsVM.calibratedRetentionRate, 0.75)
        
        // Sessões simuladas com média de 400 WPM
        let sessions = [
            ReadingSession(durationSeconds: 60, wordsRead: 400, averageWPM: 400)
        ]
        let avgEff = statsVM.averageEffectiveWPM(from: sessions)
        XCTAssertEqual(avgEff, 300)
    }
    
    func testCognitivePrimingGeneration() {
        let text = """
        A neuroplasticidade cerebral permite a adaptação constante dos circuitos visuais e fonológicos.
        O córtex visual recicla neurônios para reconhecer grafemas e conectá-los ao léxico mental.
        Estudos demonstram que a atenção prévia e o foco atencional amplificam a retenção da leitura.
        """
        
        let priming = TextSummarizerService.shared.generatePrimingContext(from: text, title: "Neurociência")
        
        XCTAssertEqual(priming.title, "Neurociência")
        XCTAssertFalse(priming.anchorConcepts.isEmpty)
        XCTAssertFalse(priming.keyInsights.isEmpty)
        XCTAssertFalse(priming.focusQuestion.isEmpty)
        XCTAssertGreaterThan(priming.estimatedReadingSeconds, 0)
    }
    
    // MARK: - Testes do Guia de Técnicas e Recursos
    
    func testReadingGuideViewInitialization() {
        let defaultGuide = ReadingGuideView()
        XCTAssertNotNil(defaultGuide)
        
        let techniquesGuide = ReadingGuideView(initialSection: .techniques)
        XCTAssertNotNil(techniquesGuide)
        
        let featuresGuide = ReadingGuideView(initialSection: .features)
        XCTAssertNotNil(featuresGuide)
        
        let simulatorGuide = ReadingGuideView(initialSection: .simulator)
        XCTAssertNotNil(simulatorGuide)
        
        XCTAssertEqual(ReadingGuideView.GuideSection.techniques.iconName, "brain.head.profile")
        XCTAssertEqual(ReadingGuideView.GuideSection.features.iconName, "sparkles.rectangle.stack")
        XCTAssertEqual(ReadingGuideView.GuideSection.simulator.iconName, "play.circle.fill")
    }
    
    // MARK: - Testes de Deep Link e Integração Chrome
    
    @MainActor
    func testDeepLinkManagerReadAction() async throws {
        let container = ModelContainer.preview
        let context = container.mainContext
        
        let testText = "OneWord conecta o Chrome ao leitor veloz."
        let escapedText = testText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let escapedTitle = "Artigo de Teste".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: "oneword://read?text=\(escapedText)&title=\(escapedTitle)")!
        
        let doc = try await DeepLinkManager.shared.handle(url: url, context: context)
        XCTAssertNotNil(doc)
        XCTAssertEqual(doc?.title, "Artigo de Teste")
        XCTAssertEqual(doc?.totalWords, 7)
        XCTAssertEqual(doc?.activeWords.first, "OneWord")
    }
    
    @MainActor
    func testOneWordLocalServerConfiguration() {
        let server = OneWordLocalServer.shared
        XCTAssertEqual(server.defaultPort, 8765)
        XCTAssertFalse(server.isRunning)
    }
}



