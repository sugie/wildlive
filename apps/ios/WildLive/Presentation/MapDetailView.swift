// WildLive — What lives on a map, and the way on to choosing a Hunter.
//
// The spawn list is the map's real Game Master table: these are exactly
// the species this expedition can encounter, with the share of encounters
// each represents before any Hunter's rare-find bias is applied.

import SwiftUI

struct MapDetailView: View {
    @Environment(AppStore.self) private var store
    @State var viewModel: MapDetailViewModel

    var body: some View {
        List {
            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                }
            }

            if let map = viewModel.map {
                briefingSection(map)
                // Before the animal list, not after it: a real map has
                // sixteen spawn rows, and burying the only way forward
                // under all of them makes the screen a dead end on a phone.
                actionSection(map)
                animalsSection
            } else if viewModel.isLoading {
                Section {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Loading map…").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(viewModel.map?.nameEN ?? "Map")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .accessibilityIdentifier("mapDetailView")
    }

    private func briefingSection(_ map: GameMap) -> some View {
        Section("Briefing") {
            Text(map.descriptionEN)
                .font(.callout)

            LabeledContent("Region", value: map.region)
            LabeledContent("Difficulty") {
                Label(map.difficultyLabel, systemImage: "target")
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(map.difficultyColor)
            }
            LabeledContent("Expedition time",
                           value: DurationFormat.minutes(map.expeditionMinutes))
            LabeledContent("Map cost", value: "\(map.baseCostG) G")
        }
    }

    private var animalsSection: some View {
        Section {
            ForEach(viewModel.spawnsByRarity) { spawn in
                spawnRow(spawn)
            }
        } header: {
            Text("Animals you can meet here")
        } footer: {
            Text("Encounter share before any Hunter's rare-find bias. A Hunter with a rare-find bonus shifts these toward the rarer end — it does not make a capture easier.")
        }
    }

    private func spawnRow(_ spawn: MapSpawn) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(spawn.species.rarity.systemColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(spawn.species.nameEN)
                Text(spawn.species.rarity.nameEN)
                    .font(.caption)
                    .foregroundStyle(spawn.species.rarity.systemColor)
            }

            Spacer()

            Text(viewModel.encounterShare(spawn).formatted(.percent.precision(.fractionLength(0))))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("spawnRow_\(spawn.species.id)")
    }

    @ViewBuilder
    private func actionSection(_ map: GameMap) -> some View {
        Section {
            if map.unlocked {
                NavigationLink(value: Route.hunterPicker(mapID: map.id)) {
                    Label("Choose a Hunter", systemImage: "person.crop.circle.badge.checkmark")
                }
                .accessibilityIdentifier("chooseHunterButton")
            } else {
                Label(map.unlockRequirement ?? "Locked", systemImage: "lock.fill")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
