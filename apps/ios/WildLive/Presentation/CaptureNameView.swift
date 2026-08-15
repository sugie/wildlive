// WildLive — Name the captured Animal, or release from here.

import SwiftUI

struct CaptureNameView: View {
    @Environment(AppStore.self) private var store
    let expeditionId: UUID

    @State private var name: String = ""
    @State private var errorMessage: String?
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        Form {
            if let animal = store.gameService.pendingAnimal(for: expeditionId),
               let species = store.speciesById[animal.speciesId] {
                summarySection(animal: animal, species: species)
                namingSection
                actionSection
            } else {
                Section {
                    Text("Nothing to name.")
                        .foregroundStyle(.secondary)
                    Text("This capture has already been handled.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Name your Animal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { nameFieldFocused = true }
        .alert("Cannot add", isPresented: errorBinding) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func summarySection(animal: Animal, species: Species) -> some View {
        Section("Captured") {
            LabeledContent("Species", value: species.commonName)
            LabeledContent("Rarity") {
                HStack(spacing: 6) {
                    Circle().fill(species.rarity.systemColor).frame(width: 10, height: 10)
                    Text(species.rarity.label).foregroundStyle(.secondary)
                }
            }
            if animal.trait != .none {
                LabeledContent("Trait", value: animal.trait.label)
            }
        }
    }

    private var namingSection: some View {
        Section {
            TextField("Nickname (optional)", text: $name)
                .autocorrectionDisabled()
                .focused($nameFieldFocused)
                .accessibilityIdentifier("nicknameField")
        } footer: {
            Text("Give it a name, or leave blank to keep it unnamed.")
        }
    }

    private var actionSection: some View {
        Section {
            Button {
                switch store.gameService.keepInZoo(expeditionId: expeditionId, nickname: name) {
                case .success:
                    store.popToHome()
                    store.push(.myZoo)
                case .failure(let err):
                    errorMessage = err.localizedDescription
                }
            } label: {
                Label("Add to Zoo", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("confirmAddToZooButton")

            Button(role: .destructive) {
                _ = store.gameService.release(expeditionId: expeditionId)
                store.popToHome()
            } label: {
                Label("Release instead", systemImage: "arrow.uturn.backward.circle")
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
