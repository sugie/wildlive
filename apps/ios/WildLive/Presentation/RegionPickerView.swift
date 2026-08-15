// WildLive — Region picker; second step of the dispatch flow.

import SwiftUI

struct RegionPickerView: View {
    @Environment(AppStore.self) private var store
    let hunterId: String

    var body: some View {
        List {
            if let hunter = store.hunter(hunterId) {
                Section("Dispatching") {
                    LabeledContent("Hunter", value: hunter.name)
                    Text("A weaker Hunter in a harder Region raises the chance of no capture.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Regions") {
                ForEach(store.regions) { region in
                    NavigationLink(value: Route.dispatchConfirm(hunterId: hunterId, regionId: region.id)) {
                        regionRow(region)
                    }
                    .accessibilityIdentifier("regionRow_\(region.id)")
                }
            }
        }
        .navigationTitle("Region")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("regionPickerView")
    }

    private func regionRow(_ region: Region) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(region.name).font(.headline)
                Spacer()
                Label(region.difficulty.label, systemImage: "target")
                    .labelStyle(.titleAndIcon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(region.difficulty.systemColor)
            }
            Text(region.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(region.flavor)
                .font(.footnote)
                .foregroundStyle(.secondary)
            HStack {
                Label("~ \(Int(region.simulatedDurationSeconds)) s",
                      systemImage: "hourglass")
                    .font(.caption)
                Spacer()
                Text("\(region.speciesPool.count) species")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
