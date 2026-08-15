// WildLive — Read-only view of another player's Zoo.

import SwiftUI

struct VisitZooView: View {
    @Environment(AppStore.self) private var store
    let playerId: String

    var body: some View {
        List {
            if let player = store.player(playerId) {
                Section(player.displayName) {
                    LabeledContent("Zoo Value",
                                   value: "\(player.zooValue(using: store.speciesById))")
                    LabeledContent("Animals", value: "\(player.animals.count)")
                }
                if player.animals.isEmpty {
                    Section {
                        Text("This Zoo is empty.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Animals") {
                        ForEach(player.animals) { animal in
                            AnimalRow(animal: animal)
                        }
                    }
                }
            } else {
                Section {
                    Text("Player not found.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Visiting")
        .navigationBarTitleDisplayMode(.inline)
    }
}
