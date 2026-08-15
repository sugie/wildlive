// WildLive — Final confirmation before an expedition is dispatched.

import SwiftUI

struct DispatchConfirmView: View {
    @Environment(AppStore.self) private var store
    let hunterId: String
    let regionId: String

    @State private var dispatched = false
    @State private var errorMessage: String?

    var body: some View {
        Form {
            if let hunter = store.hunter(hunterId), let region = store.region(regionId) {
                hunterSection(hunter)
                regionSection(region)
                speciesSection(region)
                actionSection(hunter: hunter, region: region)
            }
        }
        .navigationTitle("Dispatch")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Dispatch failed", isPresented: errorBinding) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func hunterSection(_ hunter: Hunter) -> some View {
        Section("Hunter") {
            LabeledContent("Name",  value: hunter.name)
            LabeledContent("Tier",  value: hunter.tier.label)
            LabeledContent("Skill", value: "\(hunter.skill) / 100")
        }
    }

    private func regionSection(_ region: Region) -> some View {
        Section("Region") {
            LabeledContent("Name", value: region.name)
            LabeledContent("Difficulty") {
                Label(region.difficulty.label, systemImage: "target")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(region.difficulty.systemColor)
            }
            LabeledContent("Simulated wait",
                           value: "\(Int(region.simulatedDurationSeconds)) seconds")
        }
    }

    private func speciesSection(_ region: Region) -> some View {
        Section("Possible species") {
            ForEach(region.speciesPool, id: \.self) { id in
                if let sp = store.speciesById[id] {
                    HStack {
                        Circle().fill(sp.rarity.systemColor).frame(width: 8, height: 8)
                        Text(sp.commonName)
                        Spacer()
                        Text(sp.rarity.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func actionSection(hunter: Hunter, region: Region) -> some View {
        if dispatched {
            Section {
                Label("Dispatched.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
                Text("Watch the countdown in Expeditions.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button {
                    store.popToHome()
                    store.push(.expeditions)
                } label: {
                    Label("Go to Expeditions", systemImage: "map.fill")
                }
                .accessibilityIdentifier("goToExpeditionsButton")
            }
        } else {
            Section {
                Button {
                    switch store.gameService.dispatch(hunterId: hunter.id, regionId: region.id) {
                    case .success:
                        dispatched = true
                    case .failure(let err):
                        errorMessage = err.localizedDescription
                    }
                } label: {
                    Text("Dispatch \(hunter.name)")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("dispatchButton")
            }
        }
    }
}
