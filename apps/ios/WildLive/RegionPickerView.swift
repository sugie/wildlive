// WildLive — Region picker; second step of the dispatch flow.

import SwiftUI

struct RegionPickerView: View {
    @Environment(AppStore.self) private var store
    let hunterId: String

    var body: some View {
        ZStack {
            Theme.appBackground
            ScrollView {
                VStack(spacing: 12) {
                    if let hunter = store.hunter(hunterId) {
                        hunterHeader(hunter)
                    }
                    ForEach(store.regions) { region in
                        regionCard(region)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Region")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bgTop, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .accessibilityIdentifier("regionPickerView")
    }

    private func hunterHeader(_ hunter: Hunter) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Dispatching \(hunter.name)")
                .font(.headline).foregroundStyle(.white)
            Text("A weaker Hunter in a harder Region raises the chance of no capture.")
                .font(.caption).foregroundStyle(Theme.subtle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func regionCard(_ region: Region) -> some View {
        Button {
            store.push(.dispatchConfirm(hunterId: hunterId, regionId: region.id))
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(region.name).font(.headline).foregroundStyle(.white)
                        Text(region.subtitle).font(.caption).foregroundStyle(Theme.subtle)
                    }
                    Spacer()
                    difficultyChip(region.difficulty)
                }
                Text(region.flavor).font(.caption).foregroundStyle(.white.opacity(0.75))
                HStack {
                    Text("~ \(Int(region.simulatedDurationSeconds))s simulated wait")
                        .font(.caption2).foregroundStyle(Theme.subtle)
                    Spacer()
                    Text("\(region.speciesPool.count) species")
                        .font(.caption2).foregroundStyle(Theme.subtle)
                }
            }
            .card()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("regionRow_\(region.id)")
    }

    private func difficultyChip(_ difficulty: Region.Difficulty) -> some View {
        let color: Color = {
            switch difficulty {
            case .easy:    return Color(red: 0.45, green: 0.85, blue: 0.55)
            case .medium:  return Color(red: 0.90, green: 0.80, blue: 0.30)
            case .high:    return Color(red: 0.95, green: 0.55, blue: 0.30)
            case .extreme: return Color(red: 0.95, green: 0.35, blue: 0.35)
            }
        }()
        return Text(difficulty.label.uppercased())
            .font(.caption2.weight(.bold)).tracking(1)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().stroke(color, lineWidth: 1))
            .foregroundStyle(color)
    }
}
