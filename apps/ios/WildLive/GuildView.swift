// WildLive — Guild. List of Hunters + current contract action.

import SwiftUI

struct GuildView: View {
    @Environment(AppStore.self) private var store
    @State private var errorMessage: String?

    var body: some View {
        List {
            introSection
            if let hunter = store.contractedHunter {
                contractedSection(hunter)
            }
            huntersSection
        }
        .navigationTitle("Guild")
        .alert("Cannot contract", isPresented: errorBinding) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .accessibilityIdentifier("guildView")
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private var introSection: some View {
        Section {
            Text("Basic Hunters are always available. Elite and Legendary Hunters are a shared Guild resource — sometimes another player already has them out on assignment.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func contractedSection(_ hunter: Hunter) -> some View {
        Section("Under contract") {
            LabeledContent("Hunter", value: hunter.name)
            LabeledContent("Tier", value: hunter.tier.label)
            NavigationLink(value: Route.regionPicker(hunterId: hunter.id)) {
                Label("Choose Region → Dispatch", systemImage: "arrow.right.circle.fill")
            }
            .accessibilityIdentifier("chooseRegionButton")

            Button(role: .destructive) {
                store.gameService.releaseContract()
            } label: {
                Label("Release contract", systemImage: "xmark.circle")
            }
        }
    }

    private var huntersSection: some View {
        Section("Available Hunters") {
            ForEach(store.hunters) { hunter in
                hunterRow(hunter)
            }
        }
    }

    private func hunterRow(_ hunter: Hunter) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hunter.name)
                        .font(.headline)
                    Text("\(hunter.tier.label)  ·  Skill \(hunter.skill)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                statusView(hunter)
            }
            Text(hunter.bio)
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Label("\(hunter.contractCostG) G", systemImage: "circle.hexagongrid.fill")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.tint)
                Spacer()
                Button {
                    attemptContract(hunter)
                } label: {
                    Text(store.contractedHunterId == hunter.id ? "Contracted" : "Contract")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!canContract(hunter))
                .accessibilityIdentifier("contractButton_\(hunter.id)")
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func statusView(_ hunter: Hunter) -> some View {
        if store.contractedHunterId == hunter.id {
            Label("Yours", systemImage: "checkmark.seal.fill")
                .labelStyle(.iconOnly)
                .foregroundStyle(.tint)
        } else if !hunter.available {
            Label("Booked", systemImage: "clock.badge.exclamationmark")
                .labelStyle(.titleAndIcon)
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            EmptyView()
        }
    }

    private func canContract(_ hunter: Hunter) -> Bool {
        guard store.contractedHunterId == nil else { return false }
        guard hunter.available else { return false }
        return store.currentPlayer.gBalance >= hunter.contractCostG
    }

    private func attemptContract(_ hunter: Hunter) {
        switch store.gameService.contract(hunterId: hunter.id) {
        case .success:
            break
        case .failure(let err):
            errorMessage = err.localizedDescription
        }
    }
}
