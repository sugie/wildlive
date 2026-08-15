// WildLive — Ranking-style list of other players; tap to visit their Zoo.

import SwiftUI

struct OtherZoosView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            Theme.appBackground
            ScrollView {
                VStack(spacing: 12) {
                    header
                    ForEach(rankedPlayers) { entry in
                        row(entry)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Other Zoos")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bgTop, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("otherZoosView")
    }

    private struct Entry: Identifiable {
        let id: String
        let player: Player
        let zooValue: Int
        let isMe: Bool
    }

    private var rankedPlayers: [Entry] {
        let all: [Player] = [store.currentPlayer] + store.otherPlayers
        return all
            .map { Entry(id: $0.id, player: $0, zooValue: $0.zooValue(using: store.speciesById), isMe: $0.id == store.currentPlayer.id) }
            .sorted { $0.zooValue > $1.zooValue }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Zoo Value Ranking")
                .font(.headline).foregroundStyle(.white)
            Text("Tap to visit. You cannot attack or take Animals.")
                .font(.caption).foregroundStyle(Theme.subtle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    @ViewBuilder
    private func row(_ entry: Entry) -> some View {
        Button {
            store.push(.visitZoo(playerId: entry.player.id))
        } label: {
            HStack(spacing: 12) {
                Text("#\(rank(of: entry))")
                    .font(.system(size: 20, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(Theme.accent)
                    .frame(minWidth: 40, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(entry.player.displayName)
                            .font(.headline).foregroundStyle(.white)
                        if entry.isMe {
                            Text("YOU")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Theme.accent))
                                .foregroundStyle(.black)
                        }
                    }
                    Text("\(entry.player.animals.count) animals")
                        .font(.caption).foregroundStyle(Theme.subtle)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.zooValue)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Zoo Value")
                        .font(.caption2).foregroundStyle(Theme.subtle)
                }
            }
            .card()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("zooRow_\(entry.player.id)")
    }

    private func rank(of entry: Entry) -> Int {
        (rankedPlayers.firstIndex(where: { $0.id == entry.id }) ?? 0) + 1
    }
}
