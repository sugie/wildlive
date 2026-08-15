// WildLive — Choose where to send an expedition.
//
// The first step of the live loop. Unlocked maps are actionable; locked
// ones stay visible with their requirement, because seeing that the
// Serengeti opens at Zoo value 100 is what makes the next capture matter.

import SwiftUI

struct MapListView: View {
    @Environment(AppStore.self) private var store
    @State var viewModel: MapListViewModel

    var body: some View {
        List {
            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "wifi.exclamationmark")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                }
            }

            if viewModel.isLoading && viewModel.maps.isEmpty {
                Section {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Loading maps…").foregroundStyle(.secondary)
                    }
                }
            }

            if !viewModel.unlockedMaps.isEmpty {
                Section("Open to you") {
                    ForEach(viewModel.unlockedMaps) { map in
                        NavigationLink(value: Route.mapDetail(mapID: map.id)) {
                            MapRow(map: map)
                        }
                        .accessibilityIdentifier("mapRow_\(map.id)")
                    }
                }
            }

            if !viewModel.lockedMaps.isEmpty {
                Section("Locked") {
                    ForEach(viewModel.lockedMaps) { map in
                        MapRow(map: map)
                            .accessibilityIdentifier("lockedMapRow_\(map.id)")
                    }
                }
            }
        }
        .navigationTitle("Maps")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .accessibilityIdentifier("mapListView")
    }
}

// MARK: - Row

struct MapRow: View {
    let map: GameMap

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(map.nameEN).font(.headline)
                Spacer()
                if map.unlocked {
                    Label(map.difficultyLabel, systemImage: "target")
                        .labelStyle(.titleAndIcon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(map.difficultyColor)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text("\(map.region) · \(map.nameJA)")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let requirement = map.unlockRequirement {
                Text(requirement)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.orange)
            } else {
                HStack(spacing: 12) {
                    Label("\(map.baseCostG) G", systemImage: "circle.hexagongrid.fill")
                    Label(DurationFormat.minutes(map.expeditionMinutes), systemImage: "hourglass")
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
        .opacity(map.unlocked ? 1 : 0.6)
    }
}
