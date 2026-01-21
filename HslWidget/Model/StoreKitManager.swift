//
//  StoreKitManager.swift
//  HslWidget
//
//  Manages in-app purchases using StoreKit 2
//

import Foundation
import StoreKit

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    private let productId = "com.balenet.HslWidget.unlimited"
    private let purchasedKey = "hasUnlimitedPurchase"
    private let sharedDefaults = UserDefaults(suiteName: "group.balenet.widget")

    @Published private(set) var product: Product?
    @Published private(set) var purchaseState: PurchaseState = .unknown
    @Published private(set) var isLoading = false

    enum PurchaseState {
        case unknown
        case notPurchased
        case purchased
        case pending
    }

    var hasUnlimitedAccess: Bool {
        purchaseState == .purchased
    }

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
        loadCachedPurchaseState()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            print("StoreKitManager: Requesting product: \(productId)")
            let products = try await Product.products(for: [productId])
            product = products.first
            if let product = product {
                print("StoreKitManager: Loaded product: \(product.displayName) - \(product.displayPrice)")
            } else {
                print("StoreKitManager: No products returned for ID: \(productId)")
            }
        } catch {
            print("StoreKitManager: Failed to load products: \(error)")
        }
    }

    func purchase() async throws -> Bool {
        guard let product = product else {
            throw StoreError.productNotAvailable
        }

        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchaseState()
            await transaction.finish()
            debugLog("StoreKitManager: Purchase successful")
            return true

        case .userCancelled:
            debugLog("StoreKitManager: User cancelled purchase")
            return false

        case .pending:
            purchaseState = .pending
            debugLog("StoreKitManager: Purchase pending")
            return false

        @unknown default:
            debugLog("StoreKitManager: Unknown purchase result")
            return false
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updatePurchaseState()
            debugLog("StoreKitManager: Restore completed, state: \(purchaseState)")
        } catch {
            debugLog("StoreKitManager: Restore failed: \(error)")
        }
    }

    func updatePurchaseState() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productId {
                purchaseState = .purchased
                savePurchaseState(true)
                debugLog("StoreKitManager: Found valid entitlement")
                return
            }
        }

        purchaseState = .notPurchased
        savePurchaseState(false)
        debugLog("StoreKitManager: No valid entitlement found")
    }

    // MARK: - Private Methods

    private func loadCachedPurchaseState() {
        if sharedDefaults?.bool(forKey: purchasedKey) == true {
            purchaseState = .purchased
            debugLog("StoreKitManager: Loaded cached purchase state: purchased")
        }
    }

    private func savePurchaseState(_ purchased: Bool) {
        sharedDefaults?.set(purchased, forKey: purchasedKey)
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await self.updatePurchaseState()
                    await transaction.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: LocalizedError {
    case productNotAvailable
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .productNotAvailable:
            return String(localized: "Product not available")
        case .verificationFailed:
            return String(localized: "Transaction verification failed")
        }
    }
}
