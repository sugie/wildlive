// WildLive — Home dashboard. Apple-defaults render: List with grouped
// Sections, LabeledContent for scalar stats, Labels + system SF Symbols
// for the navigation rows.

import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        List {
            statusSection
            expeditionsSection
            navigationSection
            signOutSection
        }
        .navigationTitle("WildLive")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("homeView")
    }

    // MARK: Sections

    private var statusSection: some View {
        Section("Zookeeper") {
            LabeledContent("Name", value: store.currentPlayer.displayName)
            LabeledContent("G Balance") {
                Text("\(store.currentPlayer.gBalance)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            LabeledContent("Zoo Value", value: "\(store.myZooValue)")
            LabeledContent("Animals",   value: "\(store.currentPlayer.animals.count)")
            LabeledContent("Visitors / day", value: "\(store.currentPlayer.visitorsPerDay)")
            Button {
                store.push(.store)
            } label: {
                Label("Buy G", systemImage: "cart.badge.plus")
            }
            .accessibilityIdentifier("buyGButton")
        }
    }

    @ViewBuilder
    private var expeditionsSection: some View {
        let ongoing = store.ongoingExpeditions
        let pending = store.unhandledCapturedExpeditions

        Section("Expeditions") {
            if ongoing.isEmpty && pending.isEmpty {
                Text("No active expeditions. Visit the Guild to dispatch a Hunter.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                if !pending.isEmpty {
                    Label("\(pending.count) expedition(s) awaiting your decision.",
                          systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                }
                ForEach(ongoing.prefix(3)) { exp in
                    ongoingRow(exp)
                }
                NavigationLink(value: Route.expeditions) {
                    Label("See all expeditions", systemImage: "list.bullet")
                }
                .accessibilityIdentifier("viewExpeditionsButton")
            }
        }
    }

    private var navigationSection: some View {
        Section {
            NavigationLink(value: Route.myZoo) {
                Label("My Zoo", systemImage: "leaf.fill")
            }
            .accessibilityIdentifier("navMyZoo")

            NavigationLink(value: Route.otherZoos) {
                Label("Other Zoos", systemImage: "person.2.fill")
            }
            .accessibilityIdentifier("navOtherZoos")

            NavigationLink(value: Route.guild) {
                Label("Guild", systemImage: "figure.walk")
            }
            .accessibilityIdentifier("navGuild")

            NavigationLink(value: Route.expeditions) {
                Label("Expeditions", systemImage: "map.fill")
            }
            .accessibilityIdentifier("navExpeditions")

            NavigationLink(value: Route.store) {
                Label("Store", systemImage: "creditcard.fill")
            }
            .accessibilityIdentifier("navStore")
        }
    }

    private var signOutSection: some View {
        Section {
            Button("Sign out (return to title)", role: .destructive) {
                store.returnToTitle()
            }
        }
    }

    // MARK: Row helpers

    private func ongoingRow(_ exp: Expedition) -> some View {
        let hunter = store.hunter(exp.hunterId)?.name ?? "Hunter"
        let region = store.region(exp.regionId)?.name ?? "Region"
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(hunter)
                Text(region).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            ExpeditionCountdownView(endsAt: exp.endsAt)
        }
    }
}

// MARK: - Countdown

struct ExpeditionCountdownView: View {
    let endsAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int(endsAt.timeIntervalSince(context.date)))
            if remaining == 0 {
                Label("Ready", systemImage: "checkmark.circle.fill")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.tint)
                    .font(.caption.weight(.semibold))
            } else {
                Text("\(remaining)s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
