// WildLive — Detail view for a single Animal. Rendered as a Form.

import SwiftUI

struct AnimalDetailView: View {
    @Environment(AppStore.self) private var store
    let animalId: UUID

    var body: some View {
        Form {
            if let animal = store.animal(animalId),
               let species = store.speciesById[animal.speciesId] {
                identitySection(animal: animal, species: species)
                rarityTraitSection(animal: animal, species: species)
                speciesSection(species)
                provenanceSection(animal)
            } else {
                Section {
                    Text("Animal not found.").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Animal")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func identitySection(animal: Animal, species: Species) -> some View {
        Section {
            LabeledContent("Name", value: animal.nickname ?? "(unnamed)")
            LabeledContent("Species", value: species.commonName)
            LabeledContent("Scientific") {
                Text(species.scientificName)
                    .italic()
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func rarityTraitSection(animal: Animal, species: Species) -> some View {
        Section("Rarity & Traits") {
            LabeledContent("Rarity") {
                HStack(spacing: 6) {
                    Circle().fill(species.rarity.systemColor).frame(width: 10, height: 10)
                    Text(species.rarity.label)
                        .foregroundStyle(.secondary)
                }
            }
            LabeledContent("Individual trait", value: animal.trait.label)
            LabeledContent("Zoo Value contribution",
                           value: "\(animal.zooValue(species: species))")
        }
    }

    private func speciesSection(_ species: Species) -> some View {
        Section("About the species") {
            Text(species.habitatSummary)
                .font(.callout)
        }
    }

    /// Map and Hunter names are no longer resolved here: those types are
    /// now live, server-backed concepts (GameWorld.swift) and this screen
    /// only ever shows prototype animals from the mocked zoos.
    private func provenanceSection(_ animal: Animal) -> some View {
        Section("Provenance") {
            LabeledContent("Captured",
                           value: animal.capturedAt.formatted(date: .abbreviated,
                                                              time: .shortened))
        }
    }
}
