// WildLive — Name the captured Animal, then add to Zoo. Or release from here.

import SwiftUI

struct CaptureNameView: View {
    @Environment(AppStore.self) private var store
    let expeditionId: UUID
    @State private var name: String = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Theme.appBackground
            ScrollView {
                if let animal = store.gameService.pendingAnimal(for: expeditionId),
                   let species = store.speciesById[animal.speciesId] {
                    VStack(spacing: 16) {
                        summary(animal: animal, species: species)
                        namingCard
                        addButton
                        releaseButton
                    }
                    .padding(20)
                } else {
                    VStack(spacing: 8) {
                        Text("Nothing to name.").font(.headline).foregroundStyle(.white)
                        Text("This capture has already been handled.")
                            .font(.caption).foregroundStyle(Theme.subtle)
                    }
                    .padding(40)
                }
            }
        }
        .navigationTitle("Name your Animal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bgTop, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Cannot add", isPresented: errorBinding) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func summary(animal: Animal, species: Species) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle().fill(Theme.rarityColor(species.rarity)).frame(width: 10, height: 10)
                Text(species.rarity.label.uppercased()).font(.caption.weight(.semibold)).tracking(2)
                    .foregroundStyle(Theme.rarityColor(species.rarity))
                if animal.trait != .none {
                    Text(animal.trait.label)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(Theme.accent.opacity(0.25)))
                        .foregroundStyle(Theme.accent)
                }
            }
            Text(species.commonName).font(.title2.weight(.semibold)).foregroundStyle(.white)
            Text(species.scientificName).font(.footnote.italic()).foregroundStyle(Theme.subtle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var namingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Give it a name (optional)").font(.caption).foregroundStyle(Theme.subtle)
            TextField("e.g. Ember, Shadow, Kumo", text: $name)
                .textFieldStyle(.plain)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .accessibilityIdentifier("nicknameField")
        }
        .card()
    }

    private var addButton: some View {
        Button {
            switch store.gameService.keepInZoo(expeditionId: expeditionId, nickname: name) {
            case .success:
                store.popToHome()
                store.push(.myZoo)
            case .failure(let err):
                errorMessage = err.localizedDescription
            }
        } label: {
            Text("Add to Zoo")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.accent))
                .foregroundStyle(.black)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("confirmAddToZooButton")
    }

    private var releaseButton: some View {
        Button(role: .destructive) {
            _ = store.gameService.release(expeditionId: expeditionId)
            store.popToHome()
        } label: {
            Text("Release instead")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Theme.danger, lineWidth: 1)
                )
                .foregroundStyle(Theme.danger)
        }
        .buttonStyle(.plain)
    }
}
