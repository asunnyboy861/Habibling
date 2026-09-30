import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    static let plusID = "com.zzoutuo.Habibling.plus.lifetime"
    static let cloudID = "com.zzoutuo.Habibling.cloud.monthly"

    @Published var isPlus: Bool = false
    @Published var isCloudPlus: Bool = false
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var loadError: String?

    private var transactionListener: Task<Void, Never>?
    private var updatesTask: Task<Void, Never>?

    private init() {
        transactionListener = Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    Task { @MainActor [weak self] in
                        await self?.refreshEntitlements()
                    }
                }
            }
        }
        Task { await loadProducts(); await refreshEntitlements() }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: [Self.plusID, Self.cloudID])
            loadError = nil
        } catch {
            loadError = "Unable to load purchase options."
        }
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                    return true
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    func refreshEntitlements() async {
        if let result = await Transaction.currentEntitlement(for: Self.plusID),
           case .verified(let transaction) = result {
            isPlus = transaction.revocationDate == nil
        } else {
            isPlus = false
        }
        var cloud = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.cloudID,
               transaction.revocationDate == nil {
                cloud = true
            }
        }
        isCloudPlus = cloud
        syncSnapshotFlags()
    }

    private func syncSnapshotFlags() {
        if let snapshot = HabiblingSnapshot.load() {
            var updated = snapshot
            updated.save()
        }
        let defaults = UserDefaults(suiteName: HabiblingSnapshot.appGroupId) ?? .standard
        defaults.set(isPlus, forKey: "entitlement.isPlus")
        defaults.set(isCloudPlus, forKey: "entitlement.isCloudPlus")
    }

    var plusProduct: Product? { products.first { $0.id == Self.plusID } }
    var cloudProduct: Product? { products.first { $0.id == Self.cloudID } }
}
