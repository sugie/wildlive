// WildLive — The player's own Zoo.

import SwiftUI

struct MyZooView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            Theme.appBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    if store.currentPlayer.animals.isEmpty {
                        emptyState
                    } else {
                        animalGrid(store.currentPlayer.animals, readonly: false)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("My Zoo")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Theme.bgTop, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("myZooView")
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Zoo Value")
                    .font(.caption).foregroundStyle(Theme.subtle)
                Text("\(store.myZooValue)")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Animals")
                    .font(.caption).foregroundStyle(Theme.subtle)
                Text("\(store.currentPlayer.animals.count)")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .card()
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("Your Zoo is empty.")
                .font(.headline).foregroundStyle(.white)
            Text("Contract a Hunter at the Guild and dispatch them to a Region.")
                .font(.footnote).foregroundStyle(Theme.subtle)
                .multilineTextAlignment(.center)
            Button {
                store.popToHome()
                store.push(.guild)
            } label: {
                Text("Go to Guild")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Theme.accent))
                    .foregroundStyle(.black)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    @ViewBuilder
    func animalGrid(_ animals: [Animal], readonly: Bool) -> some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 12
        ) {
            ForEach(animals) { animal in
                Button {
                    if !readonly {
                        store.push(.animalDetail(animalId: animal.id))
                    }
                } label: {
                    AnimalCardView(animal: animal)
                }
                .buttonStyle(.plain)
                .disabled(readonly)
            }
        }
    }
}

// MARK: - Animal card

struct AnimalCardView: View {
    @Environment(AppStore.self) private var store
    let animal: Animal

    var body: some View {
        let species = store.speciesById[animal.speciesId]
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Theme.rarityColor(species?.rarity ?? .common))
                    .frame(width: 8, height: 8)
                Text(species?.rarity.label ?? "—")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Theme.rarityColor(species?.rarity ?? .common))
                Spacer()
                if animal.trait != .none {
                    Text(animal.trait.label)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Theme.accent.opacity(0.25)))
                        .foregroundStyle(Theme.accent)
                }
            }
            Text(animal.nickname ?? "(unnamed)")
                .font(.headline).foregroundStyle(.white)
                .lineLimit(1)
            Text(species?.commonName ?? animal.speciesId)
                .font(.caption).foregroundStyle(Theme.subtle)
                .lineLimit(1)
            if let sp = species {
                Text("Value \(animal.zooValue(species: sp))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}
