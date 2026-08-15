// WildLive — G store (mock RevenueCat surface).
//
// The bundles list, purchase button, spinner, and confirmation come from
// `GStoreServiceProtocol`. When the real RevenueCat SDK is wired in later,
// only the concrete service changes.

import SwiftUI

struct GStoreView: View {
    @Environment(AppStore.self) private var store
    @State private var pendingBundleId: String?
    @State private var lastPurchased: GBundle?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Theme.appBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    ForEach(store.gBundles) { bundle in
                        bundleCard(bundle)
                    }
                    disclaimer
                }
                .padding(20)
            }
            if let bundle = lastPurchased {
                confirmationOverlay(bundle: bundle)
            }
        }
        .navigationTitle("Buy G")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Theme.bgTop, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Purchase failed", isPresented: errorBinding) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
        .accessibilityIdentifier("gStoreView")
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Balance").font(.caption).foregroundStyle(Theme.subtle)
                Spacer()
                Text("G \(store.currentPlayer.gBalance)")
                    .font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.accent)
            }
            Text("G is spent to contract Hunters. Purchases here go through a mock in-app-purchase layer — no real payment is made in this build.")
                .font(.caption).foregroundStyle(Theme.subtle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func bundleCard(_ bundle: GBundle) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(bundle.title).font(.headline).foregroundStyle(.white)
                    if let bonus = bundle.bonusLabel {
                        Text(bonus)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(Theme.accent))
                            .foregroundStyle(.black)
                    }
                }
                Text("G \(bundle.gAmount)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.accent)
            }
            Spacer()
            purchaseButton(for: bundle)
        }
        .card()
    }

    @ViewBuilder
    private func purchaseButton(for bundle: GBundle) -> some View {
        if pendingBundleId == bundle.id {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .frame(width: 80, height: 36)
        } else {
            Button {
                Task { await purchase(bundle) }
            } label: {
                Text(bundle.priceDisplay)
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Color.white))
                    .foregroundStyle(.black)
            }
            .buttonStyle(.plain)
            .disabled(pendingBundleId != nil)
            .accessibilityIdentifier("buyButton_\(bundle.id)")
        }
    }

    private var disclaimer: some View {
        Text("This is a UI prototype. No RevenueCat SDK is bundled. All prices displayed are placeholders for design review only.")
            .font(.caption2).foregroundStyle(Theme.subtle)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
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

    private func confirmationOverlay(bundle: GBundle) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 12) {
                Text("Thanks!").font(.title2.weight(.semibold)).foregroundStyle(.white)
                Text("+ G \(bundle.gAmount)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.accent)
                Text(bundle.title).font(.caption).foregroundStyle(Theme.subtle)
                Button {
                    lastPurchased = nil
                } label: {
                    Text("Close")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .background(Capsule().fill(Theme.accent))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("purchaseConfirmClose")
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 16).fill(Theme.bgMid)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardStroke, lineWidth: 1))
            )
            .padding(40)
        }
        .transition(.opacity)
    }
}
