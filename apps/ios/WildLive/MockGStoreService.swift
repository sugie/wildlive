// WildLive — Mock G store service.
//
// Shaped like a RevenueCat-backed IAP layer so the real SDK can slot in
// later without touching any view. NO real SDK is imported in this milestone
// — the whole point is a UI-only walk-through.

import Foundation

protocol GStoreServiceProtocol: AnyObject {
    var bundles: [GBundle] { get }
    func purchase(bundleId: String) async -> Result<GBundle, GStoreError>
}

enum GStoreError: Error, LocalizedError {
    case unknownBundle
    case cancelled
    case networkFailure

    var errorDescription: String? {
        switch self {
        case .unknownBundle:   return "Unknown bundle."
        case .cancelled:       return "Purchase cancelled."
        case .networkFailure:  return "Store network failure."
        }
    }
}

final class MockGStoreService: GStoreServiceProtocol {

    private weak var store: AppStore?
    func bind(store: AppStore) { self.store = store }

    var bundles: [GBundle] {
        store?.gBundles ?? SampleData.gBundles
    }

    /// Simulates a purchase: 800ms pause (so the UI can show a spinner) then
    /// credits G to the current player. Never fails in this prototype.
    func purchase(bundleId: String) async -> Result<GBundle, GStoreError> {
        guard let store, let bundle = store.gBundles.first(where: { $0.id == bundleId }) else {
            return .failure(.unknownBundle)
        }
        try? await Task.sleep(nanoseconds: 800_000_000)
        await MainActor.run {
            store.currentPlayer.gBalance += bundle.gAmount
        }
        return .success(bundle)
    }
}
