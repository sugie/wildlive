// WildLive — The player's own Zoo. Apple defaults: List + Sections + rows.

import SwiftUI

struct MyZooView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        List {
            Section {
                LabeledContent("Zoo Value", value: "\(store.myZooValue)")
                LabeledContent("Animals",   value: "\(store.currentPlayer.animals.count)")
            }
            if store.currentPlayer.animals.isEmpty {
                Section {
                    Text("Your Zoo is empty.")
                        .foregroundStyle(.secondary)
                    Button {
                        store.popToHome()
                        store.push(.guild)
                    } label: {
                        Label("Go to Guild", systemImage: "figure.walk")
                    }
                }
            } else {
                Section("Your Animals") {
                    ForEach(store.currentPlayer.animals) { animal in
                        NavigationLink(value: Route.animalDetail(animalId: animal.id)) {
                            AnimalRow(animal: animal)
                        }
                        .accessibilityIdentifier("animalRow_\(animal.id.uuidString.prefix(8))")
                    }
                }
            }
        }
        .navigationTitle("My Zoo")
        .accessibilityIdentifier("myZooView")
    }
}

// MARK: - Reusable row

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
                    .background(
                        Capsule().strokeBorder(.secondary.opacity(0.5))
                    )
            }
            if let sp = species {
                Text("\(animal.zooValue(species: sp))")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}
