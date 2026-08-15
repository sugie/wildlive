// WildLive — Every expedition this player has sent.
//
// Read-only: opening one is what settles it. The list never resolves
// anything itself, so refreshing the screen cannot silently roll a pile of
// outcomes.

import SwiftUI

struct ExpeditionsView: View {
    @State var viewModel: ExpeditionsViewModel

    var body: some View {
        List {
            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "wifi.exclamationmark")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                }
            }

            if viewModel.expeditions.isEmpty && !viewModel.isLoading {
                Section {
                    Text("No expeditions yet.")
                        .foregroundStyle(.secondary)
                    NavigationLink(value: Route.maps) {
                        Label("Choose a Map", systemImage: "map.fill")
                    }
                }
            }

            section("Awaiting your decision", viewModel.awaitingDecision)
            section("In the field", viewModel.ongoing)
            section("Settled", viewModel.settled)
        }
        .navigationTitle("Expeditions")
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .accessibilityIdentifier("expeditionsView")
    }

    @ViewBuilder
    private func section(_ title: String, _ items: [Expedition]) -> some View {
        if !items.isEmpty {
            Section(title) {
                ForEach(items) { expedition in
                    NavigationLink(value: Route.expedition(expeditionID: expedition.id)) {
                        ExpeditionRow(expedition: expedition)
                    }
                    .accessibilityIdentifier("expeditionRow_\(expedition.id)")
                }
            }
        }
    }
}

// MARK: - Row

struct ExpeditionRow: View {
    let expedition: Expedition

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(expedition.mapNameEN)
                    Text(expedition.hunterName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ExpeditionStateBadge(expedition: expedition)
            }

            if expedition.devInstantResolve {
                Label("Development run", systemImage: "hammer.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            trailing
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var trailing: some View {
        if !expedition.isResolved {
            ExpeditionCountdownView(endsAt: expedition.endsAt)
        } else if expedition.awaitsDecision {
            Label("Tap to name or release", systemImage: "hand.tap")
                .labelStyle(.titleAndIcon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)
        } else if let species = expedition.resolution?.encounteredSpecies {
            switch expedition.decision {
            case .kept:
                Text("\(species.nameEN) — in your Zoo")
                    .font(.caption).foregroundStyle(.secondary)
            case .released:
                Text("\(species.nameEN) — released")
                    .font(.caption).foregroundStyle(.secondary)
            case nil:
                Text("\(species.nameEN) got away")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct ExpeditionStateBadge: View {
    let expedition: Expedition

    private var state: (String, Color) {
        if !expedition.isResolved {
            return expedition.isDue ? ("Ready", .accentColor) : ("In the field", .secondary)
        }
        if expedition.awaitsDecision { return ("Captured", .accentColor) }
        switch expedition.decision {
        case .kept:     return ("Kept", .green)
        case .released: return ("Released", .secondary)
        case nil:       return ("No capture", .red)
        }
    }

    var body: some View {
        Text(state.0)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(state.1)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().strokeBorder(state.1.opacity(0.5)))
    }
}

// MARK: - Countdown

struct ExpeditionCountdownView: View {
    let endsAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = Int(endsAt.timeIntervalSince(context.date).rounded())
            if remaining <= 0 {
                Label("Ready to resolve", systemImage: "checkmark.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.tint)
                    .font(.caption.weight(.semibold))
            } else {
                Label(DurationFormat.remaining(seconds: remaining), systemImage: "hourglass")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
