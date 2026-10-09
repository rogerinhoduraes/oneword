//
//  SettingsView.swift
//  OneWord
//
//  Aba Ajustes: apoio (compra única), privacidade, preferências de leitura, idioma e sobre.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    
    private let purchases = PurchaseManager.shared
    private let consent = AdConsentManager.shared
    
    @AppStorage(AppSettings.defaultWPMKey) private var defaultWPM: Int = 300
    @State private var reader = ReaderSettings.load()
    @State private var habitTracker = ReadingHabitTracker.shared
    @State private var isShowingReadingGuide = false
    
    private static let privacyURL = URL(string: "https://rogerinhoduraes.github.io/oneword/privacy.html")!
    private static let contactURL = URL(string: "mailto:rogerinho.duraes@gmail.com?subject=OneWord")!
    private static let reviewURL = URL(string: "https://apps.apple.com/app/oneword/id6819051378?action=write-review")!
    
    var body: some View {
        NavigationStack {
            Form {
                supportSection
                privacySection
                readingSection
                languageSection
                aboutSection
            }
            .navigationTitle("Ajustes")
            .sheet(isPresented: $isShowingReadingGuide) {
                ReadingGuideView()
            }
            .task { if PurchaseManager.isPurchaseEnabled { await purchases.prepare() } }
            .onChange(of: reader) { _, newValue in newValue.save() }
        }
    }
    
    // MARK: - Apoio
    
    private var supportSection: some View {
        Section {
            if PurchaseManager.isPurchaseEnabled {
                if purchases.hasRemovedAds {
                    Label("Anúncios removidos. Obrigado por apoiar o OneWord!", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                } else {
                    purchaseCard
                }
            } else {
                Text("O OneWord é gratuito e mostra um pequeno banner na Biblioteca e nas Estatísticas. O leitor nunca tem anúncios.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Apoio")
        } footer: {
            if PurchaseManager.isPurchaseEnabled && !purchases.hasRemovedAds {
                Text("Compra única. O leitor nunca tem anúncios.")
            }
        }
    }
    
    private var purchaseCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "rectangle.badge.xmark")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Remover anúncios")
                        .font(.headline)
                    Text("Tira o banner da Biblioteca e das Estatísticas para sempre.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Button {
                Task { await purchases.purchase() }
            } label: {
                HStack(spacing: 8) {
                    if purchases.isWorking || purchases.isLoadingProduct {
                        ProgressView().tint(.white)
                    }
                    if purchases.isWorking {
                        Text("Processando…")
                    } else if let product = purchases.product {
                        Text("Comprar por \(product.displayPrice)")
                    } else if purchases.isLoadingProduct {
                        Text("Carregando preço…")
                    } else {
                        Text("Tentar novamente")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .disabled(purchases.isWorking || purchases.isLoadingProduct)
            
            HStack {
                if let message = purchases.message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Button("Restaurar compras") {
                    Task { await purchases.restore() }
                }
                .font(.footnote)
                .disabled(purchases.isWorking)
            }
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Privacidade
    
    private var privacySection: some View {
        Section("Privacidade") {
            if consent.canShowPrivacyOptions && !purchases.hasRemovedAds {
                Button("Opções de privacidade de anúncios") {
                    Task { await consent.presentPrivacyOptions() }
                }
            }
            Link("Política de privacidade", destination: Self.privacyURL)
        }
    }
    
    // MARK: - Leitura
    
    private var readingSection: some View {
        Section("Leitura") {
            Stepper(value: $defaultWPM, in: AppSettings.wpmRange, step: 25) {
                LabeledContent("Velocidade inicial", value: "\(defaultWPM) WPM")
            }
            
            Stepper(
                value: Binding(
                    get: { habitTracker.dailyWordGoal },
                    set: { habitTracker.dailyWordGoal = $0 }
                ),
                in: 500...20000,
                step: 500
            ) {
                LabeledContent("Meta diária", value: String(localized: "\(habitTracker.dailyWordGoal) palavras"))
            }
            
            Picker("Tema", selection: $reader.theme) {
                ForEach(ReaderTheme.allCases) { Text(LocalizedStringKey($0.rawValue)).tag($0) }
            }
            Picker("Fonte", selection: $reader.font) {
                ForEach(ReaderFont.allCases) { Text(LocalizedStringKey($0.rawValue)).tag($0) }
            }
            VStack(alignment: .leading) {
                LabeledContent("Tamanho da fonte", value: "\(Int(reader.fontSize))")
                Slider(value: $reader.fontSize, in: 24...80, step: 2)
            }
            Picker("Palavras por vez", selection: $reader.chunkSize) {
                ForEach(1...3, id: \.self) { Text("\($0)").tag($0) }
            }
            Toggle("Guia de ponto focal (ORP)", isOn: $reader.showORPNotch)
            Toggle("Velocidade inteligente", isOn: $reader.smartWPMEnabled)
            Toggle("Áudio bimodal", isOn: $reader.bimodalAudioEnabled)
        }
    }
    
    // MARK: - Idioma
    
    private var languageSection: some View {
        Section {
            LabeledContent("Idioma do app e da tradução", value: "\(AppLanguage.flag) \(AppLanguage.name)")
            #if canImport(UIKit)
            Button("Alterar nos Ajustes do sistema") {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
            #endif
        } header: {
            Text("Idioma")
        } footer: {
            Text("O OneWord segue o idioma do sistema (português, inglês ou espanhol).")
        }
    }
    
    // MARK: - Sobre
    
    private var aboutSection: some View {
        Section("Sobre") {
            LabeledContent("Versão", value: appVersion)
            Button("Guia: Técnicas & Recursos") { isShowingReadingGuide = true }
            Link("Avaliar na App Store", destination: Self.reviewURL)
            Link("Contato", destination: Self.contactURL)
        }
    }
    
    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView()
}
