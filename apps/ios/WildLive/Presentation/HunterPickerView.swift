// WildLive — Contract a Hunter for this expedition.
//
// The Guild pool, priced for the chosen Map. A Hunter is contracted for
// this one expedition and is never owned, so there is no "available"
// state, no roster to manage, and nothing to release afterwards — the
// contract simply ends with the expedition.

import SwiftUI

struct HunterPickerView: View {
    @Environment(AppStore.self) private var store
    @State var viewModel: HunterListViewModel

    var body: some View {
        List {
            introSection

            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "wifi.exclamationmark")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                }
            }

            Section(viewModel.isPickingForExpedition ? "Available to contract" : "Guild roster") {
                ForEach(viewModel.hunters) { hunter in
                    hunterRow(hunter)
                }
            }
        }
        .navigationTitle(viewModel.isPickingForExpedition ? "Hunters" : "Guild")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .accessibilityIdentifier(viewModel.isPickingForExpedition ? "hunterPickerView" : "guildView")
    }

    private var introSection: some View {
        Section {
            Text("Hunters belong to the Guild, not to you. You contract one for a single expedition; the fee is paid once and there is nothing to maintain afterwards.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func hunterRow(_ hunter: Hunter) -> some View {
        if let mapID = viewModel.mapID {
            NavigationLink(value: Route.dispatchConfirm(mapID: mapID, hunterID: hunter.id)) {
                HunterRow(hunter: hunter, balance: store.overview?.gBalance)
            }
            .disabled(!viewModel.isAffordable(hunter, balance: store.overview?.gBalance))
            .accessibilityIdentifier("hunterRow_\(hunter.id)")
        } else {
            HunterRow(hunter: hunter, balance: store.overview?.gBalance)
                .accessibilityIdentifier("hunterRow_\(hunter.id)")
        }
    }
}

// MARK: - Row

struct HunterRow: View {
    let hunter: Hunter
    let balance: Int?

    private var affordable: Bool {
        guard let balance, let cost = hunter.costing?.totalCostG else { return true }
        return balance >= cost
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hunter.name).font(.headline)
                    Text("\(hunter.rank) · \(hunter.specialty)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if hunter.costing?.biomeAffinity == true {
                    Label("Biome match", systemImage: "leaf.fill")
                        .labelStyle(.titleAndIcon)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            Text(hunter.hunterDescription)
                .font(.footnote)
                .foregroundStyle(.secondary)

            bonusRow

            if let costing = hunter.costing {
                HStack {
                    Label("\(costing.totalCostG) G total", systemImage: "circle.hexagongrid.fill")
                        .foregroundStyle(affordable ? .primary : Color.red)
                    Spacer()
                    Label(DurationFormat.minutes(costing.durationMinutes), systemImage: "hourglass")
                        .foregroundStyle(.secondary)
                }
                .font(.callout.monospacedDigit())

                if !affordable {
                    Text("Not enough G")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
            } else {
                Label("\(hunter.contractCostG) G contract", systemImage: "circle.hexagongrid.fill")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    /// The three structured skills. Shown as signed values because a
    /// negative is a real trade-off, not a defect: a rare-find tracker is
    /// slower on purpose.
    private var bonusRow: some View {
        HStack(spacing: 14) {
            bonus("Capture", hunter.captureBonus)
            bonus("Rare find", hunter.rareFindBonus)
            bonus("Speed", hunter.speedBonus)
        }
        .font(.caption2.monospacedDigit())
    }

    private func bonus(_ label: String, _ value: Int) -> some View {
        HStack(spacing: 3) {
            Text(label).foregroundStyle(.secondary)
            Text(value > 0 ? "+\(value)" : "\(value)")
                .foregroundStyle(value > 0 ? .green : (value < 0 ? .red : .secondary))
        }
    }
}
