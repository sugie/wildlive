// WildLive — List of ongoing and resolved expeditions.
//
// Auto-resolves any expedition whose end time has passed. Because the
// underlying mock service is idempotent, tapping "check now" is harmless.

import SwiftUI

struct ExpeditionsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            Theme.appBackground
            ScrollView {
                VStack(spacing: 12) {
                    if store.expeditions.isEmpty {
                        emptyState
                    } else {
                        sectionHeader("Ongoing")
                        ForEach(store.ongoingExpeditions) { exp in
                            row(exp)
                        }
                        if !store.unhandledCapturedExpeditions.isEmpty {
                            sectionHeader("Awaiting your decision")
                            ForEach(store.unhandledCapturedExpeditions) { exp in
                                row(exp)
                            }
                        }
                        let resolved = store.expeditions.filter {
                            $0.state == .noCapture || $0.state == .handled
                        }
                        if !resolved.isEmpty {
                            sectionHeader("Resolved")
                            ForEach(resolved) { exp in
                                row(exp)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Expeditions")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Theme.bgTop, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("expeditionsView")
        .onAppear(perform: autoResolveDue)
    }

    private func autoResolveDue() {
        for exp in store.expeditions where exp.isReadyToResolve {
            _ = store.gameService.resolve(expeditionId: exp.id)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold)).tracking(2)
            .foregroundStyle(Theme.subtle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No expeditions yet.")
                .font(.headline).foregroundStyle(.white)
            Text("Contract a Hunter at the Guild to send one out.")
                .font(.caption).foregroundStyle(Theme.subtle)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    private func row(_ exp: Expedition) -> some View {
        Button {
            store.push(.expeditionResult(expeditionId: exp.id))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.hunter(exp.hunterId)?.name ?? "Hunter")
                            .font(.headline).foregroundStyle(.white)
                        Text(store.region(exp.regionId)?.name ?? "Region")
                            .font(.caption).foregroundStyle(Theme.subtle)
                    }
                    Spacer()
                    stateBadge(exp)
                }
                HStack {
                    switch exp.state {
                    case .inProgress, .awaitingResolution:
                        ExpeditionCountdownView(endsAt: exp.endsAt)
                    case .captured:
                        Text("Tap to name or release")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.accent)
                    case .noCapture:
                        Text("No capture")
                            .font(.caption)
                            .foregroundStyle(Theme.subtle)
                    case .handled:
                        if exp.handledDecision == .keptInZoo {
                            Text("Added to your Zoo")
                                .font(.caption).foregroundStyle(.white.opacity(0.75))
                        } else {
                            Text("Released")
                                .font(.caption).foregroundStyle(Theme.subtle)
                        }
                    }
                    Spacer()
                }
            }
            .card()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("expeditionRow_\(exp.id.uuidString.prefix(8))")
    }

    private func stateBadge(_ exp: Expedition) -> some View {
        let (text, color): (String, Color) = {
            switch exp.state {
            case .inProgress:         return ("IN PROGRESS", Theme.subtle)
            case .awaitingResolution: return ("READY",        Theme.accent)
            case .captured:           return ("CAPTURED",     Theme.accent)
            case .noCapture:          return ("NO CAPTURE",   Theme.danger)
            case .handled:            return ("DONE",         Theme.subtle)
            }
        }()
        return Text(text)
            .font(.caption2.weight(.bold)).tracking(1)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().stroke(color, lineWidth: 1))
            .foregroundStyle(color)
    }
}
