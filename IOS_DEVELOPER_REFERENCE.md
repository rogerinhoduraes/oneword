# 🍎 Guia Definitivo e Referência Completa de Desenvolvimento iOS (Apple Developer)

> **Documento de Referência Permanente para Projetos iOS**  
> *Versão de Compatibilidade:* iOS 17 / iOS 18+ | Swift 5.9 / Swift 6 | Xcode 15 / 16+  
> *Última Atualização:* Outubro de 2026

---

## 📑 Índice Geral

1. [Visão Geral & Ciclo de Vida da Aplicação](#1-visão-geral--ciclo-de-vida-da-aplicação)
2. [Linguagem Swift Moderna (Swift 6 & Concurrency)](#2-linguagem-swift-moderna-swift-6--concurrency)
3. [Interface Declarativa com SwiftUI](#3-interface-declarativa-com-swiftui)
4. [Arquitetura & Padrões de Projeto (MVVM, Navigation, DI)](#4-arquitetura--padrões-de-projeto)
5. [Persistência de Dados & Cache](#5-persistência-de-dados--cache)
   - SwiftData
   - Core Data & CloudKit
   - Keychain & UserDefaults
   - FileSystem & Sandboxing
6. [Rede & Conectividade](#6-rede--conectividade)
   - URLSession Moderna (Async/Await)
   - Network.framework & NWPathMonitor
   - WebSockets & Streaming
   - MultipeerConnectivity & Bluetooth (BLE)
7. [Hardware, Sensores & Mídia](#7-hardware-sensores--mídia)
   - Câmera e Captura com AVFoundation
   - Áudio (AVAudioEngine, AVPlayer)
   - CoreLocation & MapKit
   - CoreMotion & Sensores Inerciais
   - CoreNFC & Haptics (CoreHaptics)
8. [Inteligência Artificial, ML & Visão Computacional](#8-inteligência-artificial-ml--visão-computacional)
   - Apple Intelligence & Foundation Models
   - CoreML & Create ML
   - Vision Framework (OCR, Face & Object Detection)
   - Speech Recognition & Natural Language
9. [Integrações do Sistema Operacional](#9-integrações-do-sistema-operacional)
   - WidgetKit (Home Screen & Lock Screen)
   - ActivityKit & Dynamic Island (Live Activities)
   - App Intents, Siri & Spotlight
   - Control Center Controls (iOS 18+)
   - Push Notifications (APNs & UserNotifications)
   - Background Tasks & Processamento em Segundo Plano
10. [Segurança, Autenticação & Privacidade](#10-segurança-autenticação--privacidade)
    - Face ID / Touch ID (LocalAuthentication)
    - Sign in with Apple & Passkeys
    - Privacy Manifests (`PrivacyInfo.xcprivacy`) & Required Reason APIs
    - App Tracking Transparency (ATT)
11. [Monetização & Serviços do Ecossistema](#11-monetização--serviços-do-ecossistema)
    - StoreKit 2 (In-App Purchases & Assinaturas)
    - Apple Pay & PassKit
    - HealthKit
    - GameKit (Game Center)
12. [Qualidade, Testes, Profiling & Publicação](#12-qualidade-testes-profiling--publicação)
    - Swift Testing Framework vs XCTest
    - Instruments (Time Profiler, Leaks, Energy Log)
    - TestFlight, CI/CD e Fastlane
    - Checklist de Submissão na App Store

---

## 1. Visão Geral & Ciclo de Vida da Aplicação

### 1.1 Estrutura do App em SwiftUI Puro
O ciclo de vida moderno elimina a necessidade de `AppDelegate` / `SceneDelegate` na maioria dos casos, utilizando o protocolo `App`.

```swift
import SwiftUI

@main
struct MeuApp: App {
    // Injeção de dependências no escopo global
    @State private var appState = AppStateManager()
    
    // Suporte a AppDelegate legado ou callbacks avançados quando necessário
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}

// Quando você ainda precisa de APIs de baixo nível (Push, Lifecycle legado)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Configurações de terceiros, APNs, etc.
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let tokenParts = deviceToken.map { String(format: "%02.2hhx", $0) }
        let token = tokenParts.joined()
        print("Device Token APNs: \(token)")
    }
}
```

### 1.2 Monitoramento do Estado da Aplicação (ScenePhase)
```swift
struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Text("Meu App")
            .onChange(of: scenePhase) { oldPhase, newPhase in
                switch newPhase {
                case .active:
                    print("App ativo em primeiro plano")
                case .inactive:
                    print("App em transição (multitarefa, central de controle)")
                case .background:
                    print("App em background - salvar rascunhos, pausar tarefas pesadas")
                @unknown default:
                    break
                }
            }
    }
}
```

---

## 2. Linguagem Swift Moderna (Swift 6 & Concurrency)

### 2.1 Concorrência Estruturada: `async/await`, `Task` e `TaskGroup`
Evite closures de conclusão (`completionHandler`) e locks manuais.

```swift
// Execução paralela com TaskGroup
func carregarDashboard() async throws -> (Perfil, [Item]) {
    try await withThrowingTaskGroup(of: DashboardData.self) { group in
        group.addTask {
            let perfil = try await ServicoUsuario.buscarPerfil()
            return .perfil(perfil)
        }
        
        group.addTask {
            let itens = try await ServicoCatalogo.buscarItens()
            return .itens(itens)
        }
        
        var perfil: Perfil?
        var itens: [Item] = []
        
        for try await resultado in group {
            switch resultado {
            case .perfil(let p): perfil = p
            case .itens(let i): itens = i
            }
        }
        
        guard let perfil else { throw AppError.dadosIncompletos }
        return (perfil, itens)
    }
}
```

### 2.2 Isolamento de Dados: `actor` e `@MainActor`
Elimine Race Conditions em tempo de compilação:

```swift
// Actor para sincronização thread-safe
actor CacheDeImagens {
    private var cache: [URL: Data] = [:]
    
    func imagem(para url: URL) -> Data? {
        return cache[url]
    }
    
    func armazenar(_ data: Data, para url: URL) {
        cache[url] = data
    }
}

// Garantir execução na Thread Principal (UI)
@MainActor
class ViewModel: ObservableObject {
    @Published var titulo: String = ""
    
    func atualizarUI(com novoTitulo: String) {
        self.titulo = novoTitulo
    }
}
```

### 2.3 Streams Assíncronos: `AsyncStream`
Perfeito para converter delegates tradicionais em sequências assíncronas:

```swift
func monitorarLocalizacao() -> AsyncStream<CLLocation> {
    AsyncStream { continuation in
        let listener = LocationTracker { loc in
            continuation.yield(loc)
        }
        continuation.onTermination = { _ in
            listener.parar()
        }
    }
}
```

---

## 3. Interface Declarativa com SwiftUI

### 3.1 O Novo Framework Observation (`@Observable` - iOS 17+)
Substitui `ObservableObject`, `@Published` e `@StateObject` com performance superior (renderiza apenas quem lê o campo).

```swift
import SwiftUI
import Observation

@Observable
final class CarrinhoModel {
    var itens: [String] = []
    var valorTotal: Double = 0.0
    
    // Propriedade derivada monitorada automaticamente
    var quantidadeTotal: Int {
        itens.count
    }
    
    func adicionar(_ item: String, preco: Double) {
        itens.append(item)
        valorTotal += preco
    }
}

struct CarrinhoView: View {
    @State private var carrinho = CarrinhoModel()
    
    var body: some View {
        VStack {
            Text("Itens: \(carrinho.quantidadeTotal)")
            Text("Total: R$ \(carrinho.valorTotal, specifier: "%.2f")")
            
            Button("Adicionar Item") {
                carrinho.adicionar("Produto A", preco: 49.90)
            }
        }
    }
}
```

### 3.2 Navegação Moderna: `NavigationStack` com Path Orientado a Dados
```swift
enum DestinoApp: Hashable {
    case detalhe(id: String)
    case configuracoes
    case checkout(total: Double)
}

struct RootNavigation: View {
    @State private var navigationPath: [DestinoApp] = []

    var body: some View {
        NavigationStack(path: $navigationPath) {
            List {
                Button("Ir para Detalhes") {
                    navigationPath.append(.detalhe(id: "XYZ-123"))
                }
            }
            .navigationTitle("Início")
            .navigationDestination(for: DestinoApp.self) { destino in
                switch destino {
                case .detalhe(let id):
                    DetalheView(id: id)
                case .configuracoes:
                    ConfiguracoesView()
                case .checkout(let total):
                    CheckoutView(total: total)
                }
            }
        }
    }
}
```

### 3.3 Animações Avançadas: `PhaseAnimator` e `KeyframeAnimator`
```swift
struct CoracaoAnimado: View {
    @State private var animar = false

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 80))
            .foregroundStyle(.red)
            .phaseAnimator([1.0, 1.3, 0.9, 1.0], trigger: animar) { view, escala in
                view.scaleEffect(escala)
            } animation: { _ in
                .spring(response: 0.3, dampingFraction: 0.5)
            }
            .onTapGesture {
                animar.toggle()
            }
    }
}
```

---

## 4. Arquitetura & Padrões de Projeto

### 4.1 Padrão MVVM com Concurrency e Injeção de Dependências
```swift
// 1. Contrato do Repositório (Protocol-oriented)
protocol ProdutoRepositoryProtocol: Sendable {
    func buscarProdutos() async throws -> [Produto]
}

// 2. ViewModel isolado na MainActor
@Observable
@MainActor
final class CatalogoViewModel {
    private let repository: ProdutoRepositoryProtocol
    
    var produtos: [Produto] = []
    var carregando = false
    var mensagemErro: String?
    
    init(repository: ProdutoRepositoryProtocol) {
        self.repository = repository
    }
    
    func carregar() async {
        carregando = true
        mensagemErro = nil
        defer { carregando = false }
        
        do {
            produtos = try await repository.buscarProdutos()
        } catch {
            mensagemErro = error.localizedDescription
        }
    }
}
```

---

## 5. Persistência de Dados & Cache

### 5.1 SwiftData (Substituto Moderno do Core Data)
Integrado nativamente com a sintaxe de Macros do Swift.

```swift
import SwiftData
import SwiftUI

// Definição da Entidade
@Model
final class Tarefa {
    @Attribute(.unique) var id: UUID
    var titulo: String
    var concluida: Bool
    var dataCriacao: Date
    
    @Relationship(deleteRule: .cascade) 
    var subtarefas: [Subtarefa] = []
    
    init(titulo: String, concluida: Bool = false) {
        self.id = UUID()
        self.titulo = titulo
        self.concluida = concluida
        self.dataCriacao = Date()
    }
}

@Model
final class Subtarefa {
    var descricao: String
    var feito: Bool
    
    init(descricao: String, feito: Bool = false) {
        self.descricao = descricao
        self.feito = feito
    }
}

// Configuração no App:
@main
struct ListaApp: App {
    var body: some Scene {
        WindowGroup {
            TarefasView()
        }
        .modelContainer(for: [Tarefa.self, Subtarefa.self])
    }
}

// Uso na View com @Query e ModelContext:
struct TarefasView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tarefa.dataCriacao, order: .reverse) private var tarefas: [Tarefa]
    
    var body: some View {
        List {
            ForEach(tarefas) { tarefa in
                Toggle(tarefa.titulo, isOn: Bindable(tarefa).concluida)
            }
            .onDelete(perform: apagarTarefas)
        }
        .toolbar {
            Button("Nova Tarefa") {
                let nova = Tarefa(titulo: "Nova Tarefa")
                modelContext.insert(nova)
            }
        }
    }
    
    private func apagarTarefas(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tarefas[index])
        }
    }
}
```

### 5.2 Armazenamento Seguro: Keychain Services
Para tokens de autenticação, senhas e dados sensíveis:

```swift
import Security

struct KeychainManager {
    static func salvar(chave: String, valor: String) -> Bool {
        guard let dados = valor.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: chave,
            kSecValueData as String: dados,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemDelete(query as CFDictionary) // Remove duplicata prévia
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func obter(chave: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: chave,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
```

### 5.3 UserDefaults & @AppStorage
Uso apenas para preferências de interface, flags booleanas simples e preferências não críticas:
```swift
struct PreferenciasView: View {
    @AppStorage("modoNoturnoAtivo") private var modoNoturnoAtivo: Bool = false
    @AppStorage("idiomaSelecionado") private var idioma: String = "pt-BR"
    
    var body: some View {
        Toggle("Modo Noturno", isOn: $modoNoturnoAtivo)
    }
}
```

---

## 6. Rede & Conectividade

### 6.1 URLSession Moderna com Async/Await e Generic Decodable
```swift
struct APIClient: Sendable {
    static let shared = APIClient()
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    func requisicao<T: Decodable>(endpoint: URL, token: String? = nil) async throws -> T {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (dados, resposta) = try await session.data(for: request)
        
        guard let httpResponse = resposta as? HTTPURLResponse, 
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: dados)
    }
}
```

### 6.2 Monitoramento de Status de Conexão com `Network.framework`
```swift
import Network

@Observable
final class MonitorRede {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NWMonitorQueue")
    
    var conectado: Bool = true
    var usaCelular: Bool = false
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.conectado = (path.status == .satisfied)
                self?.usaCelular = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
```

---

## 7. Hardware, Sensores & Mídia

### 7.1 Câmera e Captura com AVFoundation
Requer permissão no `Info.plist`: `NSCameraUsageDescription`.

```swift
import AVFoundation

final class CameraService: NSObject, AVCapturePhotoCaptureDelegate {
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    
    func configurar() async throws {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              session.canAddInput(input),
              session.canAddOutput(photoOutput) else {
            session.commitConfiguration()
            throw NSError(domain: "CameraError", code: -1)
        }
        
        session.addInput(input)
        session.addOutput(photoOutput)
        session.commitConfiguration()
        
        Task.detached { [session = self.session] in
            session.startRunning()
        }
    }
}
```

### 7.2 CoreLocation & MapKit (iOS 17+)
Requer permissões: `NSLocationWhenInUseUsageDescription`.

```swift
import SwiftUI
import MapKit

struct MapaInterativoView: View {
    @State private var posicao: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    var body: some View {
        Map(position: $posicao) {
            Marker("São Paulo Centro", coordinate: CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333))
                .tint(.blue)
        }
        .mapStyle(.standard(elevation: .realistic))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }
}
```

### 7.3 Haptics Nativos (Feedback Tátil)
```swift
import UIKit

struct FeedbackManager {
    static func sucesso() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func selecao() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    static func impactoForte() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
}
```

---

## 8. Inteligência Artificial, ML & Visão Computacional

### 8.1 Vision Framework: Reconhecimento de Texto em Imagens (OCR)
```swift
import Vision
import UIKit

func reconhecerTexto(na imagem: UIImage) async throws -> [String] {
    guard let cgImage = imagem.cgImage else { return [] }
    
    return try await withCheckedThrowingContinuation { continuation in
        let request = VNRecognizeTextRequest { request, error in
            if let error {
                continuation.resume(throwing: error)
                return
            }
            let observacoes = request.results as? [VNRecognizedTextObservation] ?? []
            let textos = observacoes.compactMap { $0.topCandidates(1).first?.string }
            continuation.resume(returning: textos)
        }
        
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["pt-BR", "en-US"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            continuation.resume(throwing: error)
        }
    }
}
```

### 8.2 Execução de Modelos CoreML
```swift
import CoreML

func classificarDado(entrada: MeuModeloInput) throws -> MeuModeloOutput {
    let configuracao = MLModelConfiguration()
    configuracao.computeUnits = .all // Utiliza Neural Engine, GPU e CPU
    
    let modelo = try MeuModelo(configuration: configuracao)
    return try modelo.prediction(input: entrada)
}
```

---

## 9. Integrações do Sistema Operacional

### 9.1 Live Activities & Dynamic Island (`ActivityKit`)
Requer `NSSupportsLiveActivities = YES` no `Info.plist`.

```swift
import ActivityKit
import SwiftUI
import WidgetKit

// 1. Definição do Contrato de Atributos
struct CorridaAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var motoristaNome: String
        var tempoEstimadoMinutos: Int
        var status: String
    }
    
    var corridaId: String
}

// 2. Widget da Dynamic Island e Lock Screen
struct CorridaActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CorridaAttributes.self) { context in
            // Visualização na Tela Bloqueada
            VStack {
                Text("Motorista: \(context.state.motoristaNome)")
                Text("Chegada em \(context.state.tempoEstimadoMinutos) min")
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Modo Expandido
                DynamicIslandExpandedRegion(.leading) {
                    Label("\(context.state.tempoEstimadoMinutos)m", systemImage: "car.fill")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.status)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Motorista: \(context.state.motoristaNome)")
                }
            } compactLeading: {
                Image(systemName: "car.fill")
            } compactTrailing: {
                Text("\(context.state.tempoEstimadoMinutos)m")
            } minimal: {
                Image(systemName: "car.fill")
            }
        }
    }
}
```

### 9.2 Gerenciamento do Ciclo de Vida da Live Activity
```swift
func iniciarLiveActivity() throws {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
    
    let atributos = CorridaAttributes(corridaId: "CORR-9988")
    let estadoInicial = CorridaAttributes.ContentState(
        motoristaNome: "Carlos",
        tempoEstimadoMinutos: 8,
        status: "A caminho"
    )
    
    let content = ActivityContent(state: estadoInicial, staleDate: nil)
    _ = try Activity.request(attributes: atributos, content: content, pushType: .token)
}
```

### 9.3 App Intents (Atalhos, Siri e Botão de Ação / Action Button)
```swift
import AppIntents

struct IniciarTreinoIntent: AppIntent {
    static var title: LocalizedStringResource = "Iniciar Treino Rápido"
    static var description = IntentDescription("Inicia a gravação de um treino esportivo")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Tipo de Treino")
    var modalidade: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Lógica de início de treino
        return .result(dialog: "Treino de \(modalidade) iniciado com sucesso!")
    }
}
```

---

## 10. Segurança, Autenticação & Privacidade

### 10.1 Biometria com LocalAuthentication (Face ID / Touch ID)
Requer `NSFaceIDUsageDescription` no `Info.plist`.

```swift
import LocalAuthentication

final class BiometriaService {
    static func autenticarUsuario(motivo: String = "Desbloquear dados confidenciais") async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: motivo
            )
        } catch {
            return false
        }
    }
}
```

### 10.2 Sign in with Apple
```swift
import SwiftUI
import AuthenticationServices

struct LoginSocialView: View {
    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            switch result {
            case .success(let authorization):
                if let credencial = authorization.credential as? ASAuthorizationAppleIDCredential {
                    let userId = credencial.user
                    let email = credencial.email
                    print("Usuário autenticado com Apple ID: \(userId), email: \(String(describing: email))")
                }
            case .failure(let error):
                print("Falha no login com Apple: \(error.localizedDescription)")
            }
        }
        .frame(height: 50)
        .signInWithAppleButtonStyle(.black)
    }
}
```

### 10.3 Manifesto de Privacidade (`PrivacyInfo.xcprivacy`)
Obrigatório pela Apple para todas as submissões. O arquivo deve declarar:
1. **NSPrivacyTracking**: Booleano se o app rastreia dados entre apps/sites de outras empresas.
2. **NSPrivacyCollectedDataTypes**: Categorias de dados coletados (Email, ID do Dispositivo, etc.) e sua finalidade.
3. **NSPrivacyAccessedAPITypes**: Justificativa de APIs restritas (ex: `UserDefaults`, `File timestamp`, `Disk space`).

---

## 11. Monetização & Serviços do Ecossistema

### 11.1 StoreKit 2 (In-App Purchases & Assinaturas)
A API moderna de compras baseada em `async/await`.

```swift
import StoreKit

@Observable
final class LojaViewModel {
    var produtos: [Product] = []
    var comprasAtivas: Set<String> = []
    
    private var transactionTask: Task<Void, Error>?
    
    init() {
        transactionTask = Task.detached {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await self.processar(transacao: transaction)
                    await transaction.finish()
                }
            }
        }
    }
    
    func buscarProdutos(ids: [String]) async throws {
        self.produtos = try await Product.products(for: ids)
    }
    
    func comprar(_ produto: Product) async throws {
        let resultado = try await produto.purchase()
        
        switch resultado {
        case .success(let verificacao):
            switch verificacao {
            case .verified(let transaction):
                await processar(transacao: transaction)
                await transaction.finish()
            case .unverified(_, let erro):
                print("Transação não verificada: \(erro)")
            }
        case .userCancelled:
            print("Usuário cancelou compra")
        case .pending:
            print("Compra aguardando aprovação familiar")
        @unknown default:
            break
        }
    }
    
    @MainActor
    private func processar(transacao: Transaction) {
        if transacao.revocationDate == nil {
            comprasAtivas.insert(transacao.productID)
        } else {
            comprasAtivas.remove(transacao.productID)
        }
    }
}
```

### 11.2 Visualizações Prontas de Assinatura (StoreView - iOS 17+)
```swift
import SwiftUI
import StoreKit

struct AssinaturasView: View {
    var body: some View {
        SubscriptionStoreView(groupID: "GRUPO_PRO_1234") {
            VStack {
                Text("Desbloqueie Todos os Recursos")
                    .font(.title.bold())
                Text("Acesso ilimitado, sincronização em nuvem e suporte prioritário.")
            }
            .padding()
        }
        .storeButton(.visible, for: .restorePurchases)
    }
}
```

---

## 12. Qualidade, Testes, Profiling & Publicação

### 12.1 Swift Testing (Novo Framework - Swift 6)
Substitui o tradicional `XCTest` por uma sintaxe limpa com macros `@Test` e `#expect`.

```swift
import Testing
@testable import MeuApp

struct CalculadoraTestes {
    
    @Test("Verifica cálculo de desconto percentual")
    func testeDesconto() {
        let precoOriginal = 100.0
        let desconto = 0.15
        let valorFinal = Calculadora.aplicar(desconto: desconto, no: precoOriginal)
        
        #expect(valorFinal == 85.0)
    }
    
    @Test("Testa comportamento com múltiplos inputs", arguments: [
        ("user1", true),
        ("admin", true),
        ("bloqueado", false)
    ])
    func testePermissoes(usuario: String, esperado: Bool) async throws {
        let autenticador = AutenticadorMock()
        let acesso = try await autenticador.validar(usuario: usuario)
        #expect(acesso == esperado)
    }
}
```

### 12.2 Principais Chaves de Permissão no `Info.plist`

| Chave | Descrição / Propósito |
| :--- | :--- |
| `NSCameraUsageDescription` | Uso da Câmera para fotos ou vídeos |
| `NSPhotoLibraryUsageDescription` | Acesso à galeria de fotos |
| `NSLocationWhenInUseUsageDescription` | Localização do usuário com o app em uso |
| `NSFaceIDUsageDescription` | Acesso ao Face ID para autenticação |
| `NSMicrophoneUsageDescription` | Gravação de voz ou áudio |
| `NSSpeechRecognitionUsageDescription` | Transcrição de fala para texto |
| `NSBluetoothAlwaysUsageDescription` | Conexões BLE contínuas em segundo plano |
| `NSHealthShareUsageDescription` | Leitura de métricas no HealthKit |
| `NSHealthUpdateUsageDescription` | Gravação de dados no HealthKit |
| `NSUserTrackingUsageDescription` | Rastreamento para anúncios via IDFA (ATT) |

---

## 📌 Guia de Decisão Rápida para o Desenvolvedor

```
Necessidade do Projeto                  Solução Recomendada
-----------------------------------------------------------------------------
Criar Interface Moderna                 SwiftUI com @Observable
Gerenciar Navegação Complexa            NavigationStack(path: $path)
Persistir Dados Estruturados Locais      SwiftData (@Model, @Query)
Salvar Tokens e Senhas                  Keychain Services
Buscar Dados em APIs REST               URLSession + async/await + Decodable
Comunicação P2P sem Internet            MultipeerConnectivity
Reconhecer Documentos/OCR               Vision Framework (VNRecognizeTextRequest)
Notificar Status em Tempo Real          Live Activities + Dynamic Island
Oferecer Assinaturas/Planos Pagos       StoreKit 2 (SubscriptionStoreView)
Autenticar Usuário Seguro               AuthenticationServices (Sign in with Apple)
Testes Rápidos e Confiáveis             Swift Testing (@Test, #expect)
-----------------------------------------------------------------------------
```

---
*Mantenha este documento versionado na raiz ou diretório de documentação do seu projeto para consulta de toda a equipe.*
