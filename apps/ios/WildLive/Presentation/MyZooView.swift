// WildLive — The player's Zoo.
//
// Every animal on this screen is a row in PostgreSQL, fetched from the
// server. Nothing is held locally, so what is shown here is what actually
// persisted.

import SwiftUI

struct MyZooView: View {
    @Environment(AppStore.self) private var store
    @State var viewModel: MyZooViewModel

    var body: some View {
        List {
            Section {
                LabeledContent("Zoo Value") {
                    Text("\(viewModel.zooValue)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("zooValueValue")
                }
                LabeledContent("Animals") {
                    Text("\(viewModel.animalCount)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("zooAnimalCountValue")
                }
            }

            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "wifi.exclamationmark")
                        .foregroundStyle(.orange)
                        .font(.footnote)
                }
            }

            if viewModel.isEmpty {
                Section {
                    Text("Your Zoo is empty.")
                        .foregroundStyle(.secondary)
                    NavigationLink(value: Route.maps) {
                        Label("Send an Expedition", systemImage: "map.fill")
                    }
                }
            } else {
                Section("Your Animals") {
                    ForEach(viewModel.animals) { animal in
                        ZooAnimalRow(animal: animal)
                    }
                }
            }
        }
        .navigationTitle("My Zoo")
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .accessibilityIdentifier("myZooView")
    }
}

// MARK: - Row

struct ZooAnimalRow: View {
    let animal: ZooAnimal

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(animal.species.rarity.systemColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                // The identifier goes on the name itself, not on the row:
                // an identifier on the enclosing HStack overrides the ones
                // its children carry, and the name is what a test — or a
                // person using VoiceOver — is actually looking for.
                Text(animal.name)
                    .accessibilityIdentifier("zooAnimalName_\(animal.name)")
                Text("\(animal.species.nameEN) · \(animal.species.rarity.nameEN)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(animal.species.baseZooValue)")
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
