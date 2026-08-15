// WildLive — Ranked list of players; tap a row to visit their Zoo.

import SwiftUI

struct OtherZoosView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        List {
            Section {
                Text("Tap to visit. You cannot attack or take Animals.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section("Ranking") {
                ForEach(Array(rankedPlayers.enumerated()), id: \.element.id) { index, entry in
                    row(entry, rank: index + 1)
                }
            }
        }
        .navigationTitle("Other Zoos")
        .navigationBarTitleDisplayMode(.inline)
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
            .map {
                Entry(id: $0.id,
                      player: $0,
                      zooValue: $0.zooValue(using: store.speciesById),
                      isMe: $0.id == store.currentPlayer.id)
            }
            .sorted { $0.zooValue > $1.zooValue }
    }

    @ViewBuilder
    private func row(_ entry: Entry, rank: Int) -> some View {
        NavigationLink(value: Route.visitZoo(playerId: entry.player.id)) {
            HStack(spacing: 12) {
                Text("#\(rank)")
                    .font(.callout.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.tint)
                    .frame(minWidth: 32, alignment: .leading)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(entry.player.displayName)
                        if entry.isMe {
                            Text("You")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor))
                                .foregroundStyle(.white)
                        }
                    }
                    Text("\(entry.player.animals.count) animals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(entry.zooValue)")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier("zooRow_\(entry.player.id)")
    }
}
