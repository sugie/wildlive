// WildLive — Detail view for a single Animal in the player's Zoo.

import SwiftUI

struct AnimalDetailView: View {
    @Environment(AppStore.self) private var store
    let animalId: UUID

    var body: some View {
        ZStack {
            Theme.appBackground
            ScrollView {
                if let animal = store.animal(animalId), let species = store.speciesById[animal.speciesId] {
                    VStack(alignment: .leading, spacing: 20) {
                        titleBlock(animal: animal, species: species)
                        speciesBlock(species)
                        provenanceBlock(animal)
                    }
                    .padding(20)
                } else {
                    Text("Animal not found").foregroundStyle(Theme.subtle).padding(40)
                }
            }
        }
        .navigationTitle("Animal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bgTop, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func titleBlock(animal: Animal, species: Species) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle().fill(Theme.rarityColor(species.rarity)).frame(width: 10, height: 10)
                Text(species.rarity.label.uppercased())
                    .font(.caption.weight(.semibold))
                    .tracking(2)
                    .foregroundStyle(Theme.rarityColor(species.rarity))
                if animal.trait != .none {
                    Text(animal.trait.label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Theme.accent.opacity(0.25)))
                        .foregroundStyle(Theme.accent)
                }
            }
            Text(animal.nickname ?? "(unnamed)")
                .font(.system(size: 32, weight: .semibold, design: .serif))
                .foregroundStyle(.white)
            Text(species.commonName)
                .font(.title3).foregroundStyle(.white.opacity(0.85))
            Text(species.scientificName)
                .font(.footnote.italic()).foregroundStyle(Theme.subtle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func speciesBlock(_ species: Species) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Species").font(.headline).foregroundStyle(.white)
            Text(species.habitatSummary).font(.footnote).foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func provenanceBlock(_ animal: Animal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Provenance").font(.headline).foregroundStyle(.white)
            row("Captured", value: animal.capturedAt.formatted(date: .abbreviated, time: .shortened))
            if let regionId = animal.capturedFromRegionId, let region = store.region(regionId) {
                row("Region", value: region.name)
            }
            if let hunterId = animal.capturedByHunterId, let hunter = store.hunter(hunterId) {
                row("Hunter", value: hunter.name)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func row(_ label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.caption).foregroundStyle(Theme.subtle).frame(width: 90, alignment: .leading)
            Text(value).font(.footnote).foregroundStyle(.white)
            Spacer()
        }
    }
}
