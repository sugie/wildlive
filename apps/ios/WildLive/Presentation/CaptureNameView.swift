// WildLive — Name the animal you just caught.
//
// The last step before it becomes a permanent row in your Zoo. The name is
// optional: leaving it blank keeps the species name, and the preview under
// the field shows exactly what will be saved either way.

import SwiftUI

struct CaptureNameView: View {
    @Environment(AppStore.self) private var store
    @State var viewModel: CaptureNameViewModel
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        Form {
            if let species = viewModel.species {
                capturedSection(species)
                namingSection(species)
                actionSection
            } else if viewModel.isLoading {
                Section {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Loading…").foregroundStyle(.secondary)
                    }
                }
            } else {
                Section {
                    Text("Nothing to name.").foregroundStyle(.secondary)
                    Text("This capture has already been handled.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Name your Animal")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
            nameFieldFocused = true
        }
        .alert("Could not add to your Zoo", isPresented: errorBinding) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .accessibilityIdentifier("captureNameView")
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private func capturedSection(_ species: AnimalSpecies) -> some View {
        Section("Captured") {
            LabeledContent("Species", value: species.nameEN)
            LabeledContent("Rarity") {
                HStack(spacing: 6) {
                    Circle().fill(species.rarity.systemColor).frame(width: 10, height: 10)
                    Text(species.rarity.nameEN).foregroundStyle(.secondary)
                }
            }
            LabeledContent("Zoo value", value: "\(species.baseZooValue)")
        }
    }

    private func namingSection(_ species: AnimalSpecies) -> some View {
        Section {
            TextField("Name (optional)", text: $viewModel.name)
                .autocorrectionDisabled()
                .focused($nameFieldFocused)
                .accessibilityIdentifier("animalNameField")
        } header: {
            Text("Name")
        } footer: {
            Text("Will be saved as “\(viewModel.effectiveName)”.")
        }
    }

    private var actionSection: some View {
        Section {
            Button {
                Task { await viewModel.keep() }
            } label: {
                HStack {
                    if viewModel.isSaving { ProgressView().controlSize(.small) }
                    Text(viewModel.isSaving ? "Adding…" : "Add to My Zoo")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canSave)
            .accessibilityIdentifier("confirmKeepButton")
        }
    }
}
