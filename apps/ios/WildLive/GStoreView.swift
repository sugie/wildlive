// WildLive — G store (mock RevenueCat surface), Apple defaults.
//
// The bundles list, purchase button, progress indicator, and confirmation
// come from `GStoreServiceProtocol`. No real RevenueCat SDK is imported.

import SwiftUI

struct GStoreView: View {
    @Environment(AppStore.self) private var store

    @State private var pendingBundleId: String?
    @State private var lastPurchased: GBundle?
    @State private var errorMessage: String?

    var body: some View {
        List {
            balanceSection
            bundlesSection
            disclaimerSection
        }
        .navigationTitle("Buy G")
        .accessibilityIdentifier("gStoreView")
        .alert("Purchase failed", isPresented: errorBinding) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
        .alert("Thanks!", isPresented: confirmationBinding, presenting: lastPurchased) { _ in
            Button("OK") { lastPurchased = nil }
        } message: { bundle in
            Text("+ G \(bundle.gAmount) added to your balance.")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private var confirmationBinding: Binding<Bool> {
        Binding(get: { lastPurchased != nil }, set: { if !$0 { lastPurchased = nil } })
    }

    private var balanceSection: some View {
        Section("Balance") {
            LabeledContent("G") {
                Text("\(store.currentPlayer.gBalance)")
                    .monospacedDigit()
                    .foregroundStyle(.tint)
            }
        }
    }

    private var bundlesSection: some View {
        Section("Buy G") {
            ForEach(store.gBundles) { bundle in
                bundleRow(bundle)
            }
        }
    }

    private func bundleRow(_ bundle: GBundle) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(bundle.title)
                        .font(.headline)
                    if let bonus = bundle.bonusLabel {
                        Text(bonus)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Color.accentColor))
                            .foregroundStyle(.white)
                    }
                }
                Text("+ G \(bundle.gAmount)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            purchaseButton(for: bundle)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func purchaseButton(for bundle: GBundle) -> some View {
        if pendingBundleId == bundle.id {
            ProgressView()
                .controlSize(.small)
                .frame(width: 80)
        } else {
            Button {
                Task { await purchase(bundle) }
            } label: {
                Text(bundle.priceDisplay)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(pendingBundleId != nil)
            .accessibilityIdentifier("buyButton_\(bundle.id)")
        }
    }

    private var disclaimerSection: some View {
        Section {
            Text("This is a UI prototype. No RevenueCat SDK is bundled. All prices are placeholders for design review only.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func purchase(_ bundle: GBundle) async {
        pendingBundleId = bundle.id
        let result = await store.storeService.purchase(bundleId: bundle.id)
        pendingBundleId = nil
        switch result {
        case .success(let b):
            lastPurchased = b
        case .failure(let err):
            errorMessage = err.localizedDescription
        }
    }
}
