//
//  RemoveAdsView.swift
//  OneWord
//
//  Compra única para remover anúncios, restaurar compras e opções de privacidade.
//

import SwiftUI

struct RemoveAdsView: View {
    @Environment(\.dismiss) private var dismiss
    private let purchases = PurchaseManager.shared
    private let consent = AdConsentManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: purchases.hasRemovedAds ? "checkmark.seal.fill" : "nosign")
                    .font(.system(size: 56))
                    .foregroundStyle(purchases.hasRemovedAds ? .green : .blue)
                    .padding(.top, 24)
                
                Text(purchases.hasRemovedAds ? "Anúncios removidos" : "Remover anúncios")
                    .font(.title2.bold())
                
                Text(purchases.hasRemovedAds
                     ? "Obrigado por apoiar o OneWord! Você não verá mais anúncios."
                     : "O OneWord é gratuito e mostra um pequeno banner na Biblioteca e nas Estatísticas. Com uma compra única, ele some para sempre. O leitor nunca tem anúncios.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                if !purchases.hasRemovedAds {
                    Button {
                        Task { await purchases.purchase() }
                    } label: {
                        Group {
                            if purchases.isWorking {
                                ProgressView()
                            } else if let product = purchases.product {
                                Text("Remover anúncios por \(product.displayPrice)")
                            } else {
                                Text("Remover anúncios")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(purchases.isWorking || purchases.product == nil)
                    .padding(.horizontal)
                }
                
                Button("Restaurar compras") {
                    Task { await purchases.restore() }
                }
                .disabled(purchases.isWorking)
                
                if consent.canShowPrivacyOptions && !purchases.hasRemovedAds {
                    Button("Opções de privacidade de anúncios") {
                        Task { await consent.presentPrivacyOptions() }
                    }
                    .font(.footnote)
                }
                
                if let message = purchases.message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Anúncios")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
            .task { await purchases.prepare() }
        }
    }
}
