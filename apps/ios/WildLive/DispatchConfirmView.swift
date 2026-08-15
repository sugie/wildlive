// WildLive — Dispatch confirmation. Final step: fire the expedition.

import SwiftUI

struct DispatchConfirmView: View {
    @Environment(AppStore.self) private var store
    let hunterId: String
    let regionId: String
    @State private var dispatched = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Theme.appBackground
            ScrollView {
                VStack(spacing: 16) {
                    if let hunter = store.hunter(hunterId), let region = store.region(regionId) {
                        summary(hunter: hunter, region: region)
                        actionButton(hunter: hunter, region: region)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Dispatch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bgTop, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Dispatch failed", isPresented: errorBinding) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func summary(hunter: Hunter, region: Region) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            row("Hunter", value: "\(hunter.name)  ·  \(hunter.tier.label)")
            row("Skill",  value: "\(hunter.skill) / 100")
            row("Region", value: region.name)
            row("Difficulty", value: region.difficulty.label)
            row("Simulated wait", value: "~ \(Int(region.simulatedDurationSeconds)) seconds")
            row("Possible species", value: region.speciesPool
                .compactMap { store.speciesById[$0]?.commonName }
                .joined(separator: ", "))
        }
        .card()
    }

    private func row(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(Theme.subtle)
            Text(value).font(.subheadline).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func actionButton(hunter: Hunter, region: Region) -> some View {
        if dispatched {
            VStack(spacing: 8) {
                Text("Dispatched.")
                    .font(.headline).foregroundStyle(Theme.accent)
                Text("Watch the countdown in Expeditions.")
                    .font(.caption).foregroundStyle(Theme.subtle)
                Button {
                    store.popToHome()
                    store.push(.expeditions)
                } label: {
                    Text("Go to Expeditions")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Capsule().fill(Theme.accent))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("goToExpeditionsButton")
            }
            .frame(maxWidth: .infinity)
            .card()
        } else {
            Button {
                switch store.gameService.dispatch(hunterId: hunter.id, regionId: region.id) {
                case .success:
                    dispatched = true
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            } label: {
                Text("Dispatch \(hunter.name)")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.accent))
                    .foregroundStyle(.black)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("dispatchButton")
        }
    }
}
