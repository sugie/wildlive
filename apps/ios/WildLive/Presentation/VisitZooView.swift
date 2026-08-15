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

// MARK: - Row (prototype)

/// Row for the mocked zoos. My Zoo has its own row type (ZooAnimalRow),
/// because a live ZooAnimal and a prototype Animal are different things.
struct AnimalRow: View {
    @Environment(AppStore.self) private var store
    let animal: Animal

    var body: some View {
        let species = store.speciesById[animal.speciesId]
        HStack(spacing: 12) {
            Circle()
                .fill(species?.rarity.systemColor ?? .gray)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(animal.nickname ?? "(unnamed)")
                Text(species?.commonName ?? animal.speciesId)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if animal.trait != .none {
                Text(animal.trait.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().strokeBorder(.secondary.opacity(0.5)))
            }
            if let sp = species {
                Text("\(animal.zooValue(species: sp))")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
