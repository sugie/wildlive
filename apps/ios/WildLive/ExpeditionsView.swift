// WildLive — List of expeditions: ongoing, awaiting decision, resolved.
// Auto-resolves any expedition whose end time has passed (idempotent).

import SwiftUI

struct ExpeditionsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        List {
            if store.expeditions.isEmpty {
                Section {
                    Text("No expeditions yet.")
                        .foregroundStyle(.secondary)
                    Text("Contract a Hunter at the Guild to send one out.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                if !store.ongoingExpeditions.isEmpty {
                    Section("Ongoing") {
                        ForEach(store.ongoingExpeditions) { exp in
                            row(exp)
                        }
                    }
                }
                if !store.unhandledCapturedExpeditions.isEmpty {
                    Section("Awaiting your decision") {
                        ForEach(store.unhandledCapturedExpeditions) { exp in
                            row(exp)
                        }
                    }
                }
                let resolved = store.expeditions.filter {
                    $0.state == .noCapture || $0.state == .handled
                }
                if !resolved.isEmpty {
                    Section("Resolved") {
                        ForEach(resolved) { exp in
                            row(exp)
                        }
                    }
                }
            }
        }
        .navigationTitle("Expeditions")
        .accessibilityIdentifier("expeditionsView")
        .onAppear(perform: autoResolveDue)
    }

    private func autoResolveDue() {
        for exp in store.expeditions where exp.isReadyToResolve {
            _ = store.gameService.resolve(expeditionId: exp.id)
        }
    }

    private func row(_ exp: Expedition) -> some View {
        NavigationLink(value: Route.expeditionResult(expeditionId: exp.id)) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.hunter(exp.hunterId)?.name ?? "Hunter")
                        Text(store.region(exp.regionId)?.name ?? "Region")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    stateBadge(exp)
                }
                trailingText(exp)
            }
            .padding(.vertical, 2)
        }
        .accessibilityIdentifier("expeditionRow_\(exp.id.uuidString.prefix(8))")
    }

    @ViewBuilder
    private func trailingText(_ exp: Expedition) -> some View {
        switch exp.state {
        case .inProgress, .awaitingResolution:
            ExpeditionCountdownView(endsAt: exp.endsAt)
        case .captured:
            Label("Tap to name or release", systemImage: "hand.tap")
                .labelStyle(.titleAndIcon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tint)
        case .noCapture:
            Text("No capture")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .handled:
            if exp.handledDecision == .keptInZoo {
                Text("Added to your Zoo")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Released")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func stateBadge(_ exp: Expedition) -> some View {
        let (text, color): (String, Color) = {
            switch exp.state {
            case .inProgress:         return ("In progress", .secondary)
            case .awaitingResolution: return ("Ready",       .accentColor)
            case .captured:           return ("Captured",    .accentColor)
            case .noCapture:          return ("No capture",  .red)
            case .handled:            return ("Done",        .secondary)
            }
        }()
        return Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().strokeBorder(color.opacity(0.5)))
    }
}
