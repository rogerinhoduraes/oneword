//
//  PurchaseManager.swift
//  OneWord
//
//  Compra única "Remover anúncios" (StoreKit 2, produto não consumível).
//

import Foundation
import StoreKit
import Observation

@Observable
@MainActor
public final class PurchaseManager {
    public static let shared = PurchaseManager()
    
    /// Compra "Remover anúncios" ativa. Em Debug usa `Products.storekit` quando rodado pelo Xcode.
    nonisolated public static let isPurchaseEnabled = true
    
    nonisolated public static let removeAdsID = "com.oneword.removeads"
    private static let cacheKey = "oneword.hasRemovedAds"
    
    public private(set) var product: Product?
    public private(set) var hasRemovedAds: Bool
    public private(set) var isWorking: Bool = false
    public private(set) var isLoadingProduct: Bool = false
    public private(set) var message: String?
    
    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    
    private init() {
        // Cache local para não exibir anúncio por engano na abertura, offline.
        hasRemovedAds = UserDefaults.standard.bool(forKey: Self.cacheKey)
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.handle(result)
            }
        }
    }
    
    /// Carrega o produto e confere o que o usuário já comprou.
    public func prepare() async {
        await refreshEntitlements()
        guard product == nil, !isLoadingProduct else { return }
        isLoadingProduct = true
        defer { isLoadingProduct = false }
        do {
            product = try await Product.products(for: [Self.removeAdsID]).first
            message = product == nil ? String(localized: "Compra indisponível no momento.") : nil
        } catch {
            message = String(localized: "Não foi possível carregar a compra.")
        }
    }
    
    public func purchase() async {
        guard let product else {
            await prepare()
            return
        }
        isWorking = true
        message = nil
        defer { isWorking = false }
        do {
            switch try await product.purchase() {
            case .success(let result):
                await handle(result)
            case .pending, .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = String(localized: "A compra não foi concluída.")
        }
    }
    
    public func restore() async {
        isWorking = true
        message = nil
        defer { isWorking = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !hasRemovedAds {
                message = String(localized: "Nenhuma compra encontrada para restaurar.")
            }
        } catch {
            message = String(localized: "Não foi possível restaurar as compras.")
        }
    }
    
    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        if transaction.productID == Self.removeAdsID {
            setRemoved(transaction.revocationDate == nil)
        }
        await transaction.finish()
    }
    
    private func refreshEntitlements() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.removeAdsID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        setRemoved(owned)
    }
    
    private func setRemoved(_ value: Bool) {
        hasRemovedAds = value
        UserDefaults.standard.set(value, forKey: Self.cacheKey)
    }
}
