// WildLive — Read-only view of another player's Zoo.

import SwiftUI

struct VisitZooView: View {
    @Environment(AppStore.self) private var store
    let playerId: String

    var body: some View {
        ZStack {
            Theme.appBackground
            ScrollView {
                if let player = store.player(playerId) {
                    VStack(spacing: 16) {
                        header(player)
                        if player.animals.isEmpty {
                            Text("This Zoo is empty.")
                                .font(.footnote)
                                .foregroundStyle(Theme.subtle)
                        } else {
                            grid(player.animals)
                        }
                    }
                    .padding(20)
                } else {
                    Text("Player not found")
                        .foregroundStyle(Theme.subtle)
                        .padding(40)
                }
            }
        }
        .navigationTitle("Visiting")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bgTop, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func header(_ player: Player) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.displayName)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                Text("Read-only visit")
                    .font(.caption).foregroundStyle(Theme.subtle)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(player.zooValue(using: store.speciesById))")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Zoo Value").font(.caption2).foregroundStyle(Theme.subtle)
            }
        }
        .card()
    }

    private func grid(_ animals: [Animal]) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(animals) { animal in
                AnimalCardView(animal: animal)
            }
        }
    }
}
