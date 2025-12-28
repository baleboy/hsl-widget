//
//  PaywallView.swift
//  HslWidget
//
//  Paywall sheet for upgrading to unlimited favorites
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var storeManager = StoreKitManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var purchaseError: String?
    @State private var showingError = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                headerSection
                featureSection
                Spacer()
                purchaseSection
                restoreSection
            }
            .padding()
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(purchaseError ?? "An unknown error occurred")
            }
            .task {
                await storeManager.loadProducts()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            Text("Unlimited Favorites")
                .font(.roundedTitle2)

            Text("You've reached the free limit of 2 favorites")
                .font(.roundedBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featureSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            featureRow(icon: "star.fill", text: "Add unlimited favorite stops")
            featureRow(icon: "tram.fill", text: "Track all your daily commute stops")
            featureRow(icon: "heart.fill", text: "Support independent development")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
                .font(.roundedBody)
        }
    }

    private var purchaseSection: some View {
        VStack(spacing: 8) {
            if storeManager.isLoading {
                ProgressView()
                    .frame(height: 50)
            } else if let product = storeManager.product {
                Button(action: performPurchase) {
                    HStack {
                        Text("Unlock for")
                        Text(product.displayPrice)
                    }
                    .font(.roundedHeadline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(12)
                }
            } else {
                VStack(spacing: 8) {
                    Text("Unable to load product")
                        .font(.roundedBody)
                        .foregroundColor(.secondary)
                    #if DEBUG
                    Text("Check Xcode console for details")
                        .font(.roundedCaption)
                        .foregroundColor(.secondary)
                    #endif
                }
            }

            Text("One-time purchase")
                .font(.roundedCaption)
                .foregroundColor(.secondary)
        }
    }

    private var restoreSection: some View {
        Button(action: performRestore) {
            Text("Restore Purchases")
                .font(.roundedSubheadline)
                .foregroundColor(.accentColor)
        }
        .disabled(storeManager.isLoading)
    }

    private func performPurchase() {
        Task {
            do {
                let success = try await storeManager.purchase()
                if success {
                    dismiss()
                }
            } catch {
                purchaseError = error.localizedDescription
                showingError = true
            }
        }
    }

    private func performRestore() {
        Task {
            await storeManager.restorePurchases()
            if storeManager.hasUnlimitedAccess {
                dismiss()
            }
        }
    }
}

#Preview {
    PaywallView()
}
