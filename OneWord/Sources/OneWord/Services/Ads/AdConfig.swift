//
//  AdConfig.swift
//  OneWord
//
//  IDs do Google AdMob. Builds de debug usam os IDs de TESTE oficiais do Google
//  (nunca clique em anúncios reais durante o desenvolvimento).
//

import Foundation

public enum AdConfig {
    #if DEBUG
    /// Bloco de banner de teste do Google.
    private static let bannerUnitID = "ca-app-pub-3940256099942544/2435281174"
    #else
    /// Bloco de banner real (AdMob).
    private static let bannerUnitID = "ca-app-pub-4791753177590529/4473486021"
    #endif
    
    /// Banner da aba Biblioteca.
    public static let libraryBannerUnitID = bannerUnitID
    /// Banner da aba Estatísticas.
    public static let statsBannerUnitID = bannerUnitID
}
