//
//  AdConsentManager.swift
//  OneWord
//
//  Consentimento (Google UMP) e rastreamento (ATT) antes de iniciar o AdMob.
//  Quem comprou "Remover anúncios" nunca vê consentimento, ATT nem banner.
//

import Foundation
import Observation

#if os(iOS) && canImport(GoogleMobileAds) && canImport(UserMessagingPlatform)
import UIKit
import AppTrackingTransparency
import GoogleMobileAds
import UserMessagingPlatform

@Observable
@MainActor
public final class AdConsentManager {
    public static let shared = AdConsentManager()
    
    /// Verdadeiro quando o SDK foi iniciado e é permitido pedir anúncios.
    public private(set) var isReadyToShowAds: Bool = false
    /// Verdadeiro quando o usuário (EEA/UK) pode reabrir o formulário de privacidade.
    public private(set) var canShowPrivacyOptions: Bool = false
    
    @ObservationIgnored private var didStart = false
    
    private init() {}
    
    /// Fluxo de abertura: UMP, depois ATT, depois SDK.
    public func start() async {
        guard !didStart, !PurchaseManager.shared.hasRemovedAds else { return }
        didStart = true
        
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false
        #if DEBUG
        // Para testar o formulário europeu no simulador/dispositivo:
        // let debug = DebugSettings(); debug.geography = .EEA; parameters.debugSettings = debug
        #endif
        
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            try await ConsentForm.loadAndPresentIfRequired(from: Self.topViewController())
        } catch {
            // Segue com o que o UMP já permitir (canRequestAds).
        }
        
        await requestTrackingIfNeeded()
        refreshPrivacyOptions()
        
        guard ConsentInformation.shared.canRequestAds else { return }
        await MobileAds.shared.start()
        isReadyToShowAds = true
    }
    
    public func presentPrivacyOptions() async {
        try? await ConsentForm.presentPrivacyOptionsForm(from: Self.topViewController())
        refreshPrivacyOptions()
    }
    
    private func refreshPrivacyOptions() {
        canShowPrivacyOptions = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }
    
    private func requestTrackingIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        // O ATT só aparece com o app ativo.
        try? await Task.sleep(for: .seconds(1))
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }
    
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }
}

#else

@Observable
@MainActor
public final class AdConsentManager {
    public static let shared = AdConsentManager()
    public private(set) var isReadyToShowAds: Bool = false
    public private(set) var canShowPrivacyOptions: Bool = false
    private init() {}
    public func start() async {}
    public func presentPrivacyOptions() async {}
}

#endif
