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
}

