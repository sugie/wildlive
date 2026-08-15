// WildLive — Home dashboard shown right after START.

import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            Theme.appBackground
            ScrollView {
                VStack(spacing: 20) {
                    statusCard
                    ongoingCard
                    navGrid
                    Button(role: .destructive) {
                        store.returnToTitle()
                    } label: {
                        Text("Sign out (return to title)")
                            .font(.footnote)
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
        }
        .navigationTitle("WildLive")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bgTop, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("homeView")
    }

    // MARK: Status card

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.currentPlayer.displayName)
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                    Text("Zookeeper")
                        .font(.caption)
                        .foregroundStyle(Theme.subtle)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("G")
                            .font(.caption).foregroundStyle(Theme.accent)
                        Text("\(store.currentPlayer.gBalance)")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .accessibilityIdentifier("gBalance")
                    }
                    Button {
                        store.push(.store)
                    } label: {
                        Text("Buy G")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().stroke(Theme.accent, lineWidth: 1)
                            )
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("buyGButton")
                }
            }

            Divider().background(Theme.cardStroke)

            HStack {
                stat(label: "Zoo Value", value: "\(store.myZooValue)")
                Spacer()
                stat(label: "Animals",   value: "\(store.currentPlayer.animals.count)")
                Spacer()
                stat(label: "Visitors/day", value: "\(store.currentPlayer.visitorsPerDay)")
            }
        }
        .card()
    }

    private func stat(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption).foregroundStyle(Theme.subtle)
            Text(value).font(.system(size: 18, weight: .semibold, design: .rounded)).foregroundStyle(.white)
        }
    }

    // MARK: Ongoing expeditions summary

    private var ongoingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Expeditions")
                    .font(.headline).foregroundStyle(.white)
                Spacer()
                Button("View all") { store.push(.expeditions) }
                    .font(.caption)
                    .foregroundStyle(Theme.accent)
                    .accessibilityIdentifier("viewExpeditionsButton")
            }

            let ongoing = store.ongoingExpeditions
            let pending = store.unhandledCapturedExpeditions

            if ongoing.isEmpty && pending.isEmpty {
                Text("No active expeditions. Visit the Guild to dispatch a Hunter.")
                    .font(.footnote).foregroundStyle(Theme.subtle)
            } else {
                if !pending.isEmpty {
                    Text("\(pending.count) expedition(s) awaiting your decision.")
                        .font(.footnote).foregroundStyle(Theme.accent)
                }
                ForEach(ongoing.prefix(3)) { exp in
                    ongoingRow(exp)
                }
            }
        }
        .card()
    }

    private func ongoingRow(_ exp: Expedition) -> some View {
        let hunter = store.hunter(exp.hunterId)?.name ?? "Hunter"
        let region = store.region(exp.regionId)?.name ?? "Region"
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(hunter).font(.subheadline).foregroundStyle(.white)
                Text(region).font(.caption).foregroundStyle(Theme.subtle)
            }
            Spacer()
            ExpeditionCountdownView(endsAt: exp.endsAt)
        }
    }

    // MARK: Navigation grid

    private var navGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            NavCard(title: "My Zoo",       subtitle: "See what you have caught",   symbol: "leaf",           id: "navMyZoo")     { store.push(.myZoo) }
            NavCard(title: "Other Zoos",   subtitle: "Visit other players",         symbol: "person.2",       id: "navOtherZoos") { store.push(.otherZoos) }
            NavCard(title: "Guild",        subtitle: "Contract a Hunter",           symbol: "figure.walk",    id: "navGuild")     { store.push(.guild) }
            NavCard(title: "Expeditions",  subtitle: "Results & decisions",         symbol: "map",            id: "navExpeditions"){ store.push(.expeditions) }
            NavCard(title: "Store",        subtitle: "Buy G",                       symbol: "creditcard",     id: "navStore")     { store.push(.store) }
        }
    }
}

// MARK: - Nav card

private struct NavCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let id: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: symbol).font(.title2).foregroundStyle(Theme.accent)
                Text(title).font(.headline).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(Theme.subtle)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
            .card()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}

// MARK: - Live countdown

struct ExpeditionCountdownView: View {
    let endsAt: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let remaining = max(0, Int(endsAt.timeIntervalSince(context.date)))
            if remaining == 0 {
                Text("Ready")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            } else {
                Text("\(remaining)s")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Theme.subtle)
            }
        }
    }
}
