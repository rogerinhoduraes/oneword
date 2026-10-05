//
//  AdBannerView.swift
//  OneWord
//
//  Banner adaptativo discreto, fixo na base. Apenas Biblioteca e Estatísticas.
//

import SwiftUI

#if os(iOS) && canImport(GoogleMobileAds)
import GoogleMobileAds

private struct BannerRepresentable: UIViewRepresentable {
    let unitID: String
    let width: CGFloat
    
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: currentOrientationAnchoredAdaptiveBanner(width: width))
        banner.adUnitID = unitID
        banner.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }
            .first
        banner.load(Request())
        return banner
    }
    
    func updateUIView(_ banner: BannerView, context: Context) {}
}

struct AdBannerView: View {
    let unitID: String
    @State private var width: CGFloat = 0
    
    var body: some View {
        GeometryReader { proxy in
            BannerRepresentable(unitID: unitID, width: proxy.size.width)
                .id(Int(proxy.size.width))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width).size.height)
        .accessibilityHidden(true)
    }
}

private struct AdBannerInset: ViewModifier {
    let unitID: String
    private let consent = AdConsentManager.shared
    private let purchases = PurchaseManager.shared
    
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom, spacing: 0) {
            if consent.isReadyToShowAds && !purchases.hasRemovedAds {
                AdBannerView(unitID: unitID)
                    .background(.bar)
            }
        }
    }
}

extension View {
    /// Banner fixo na base da tela. Some para quem comprou "Remover anúncios".
    func adBannerInset(unitID: String) -> some View {
        modifier(AdBannerInset(unitID: unitID))
    }
}

#else

extension View {
    func adBannerInset(unitID: String) -> some View { self }
}

#endif
