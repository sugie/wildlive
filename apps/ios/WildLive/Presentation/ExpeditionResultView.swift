// WildLive — Result of a single expedition. Resolves lazily on view.

import SwiftUI

struct ExpeditionResultView: View {
    @Environment(AppStore.self) private var store
    let expeditionId: UUID

    var body: some View {
        Form {
            if let exp = store.expedition(expeditionId) {
                summarySection(exp)
                stateSection(exp)
            } else {
                Section {
                    Text("Expedition not found.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Expedition")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            _ = store.gameService.resolve(expeditionId: expeditionId)
        }
    }

    private func summarySection(_ exp: Expedition) -> some View {
        Section {
            LabeledContent("Hunter", value: store.hunter(exp.hunterId)?.name ?? "—")
            LabeledContent("Region", value: store.region(exp.regionId)?.name ?? "—")
            LabeledContent("Started",
                           value: exp.startedAt.formatted(date: .omitted, time: .standard))
            if let resolved = exp.resolvedAt {
                LabeledContent("Resolved",
                               value: resolved.formatted(date: .omitted, time: .standard))
            }
        }
    }

    @ViewBuilder
    private func stateSection(_ exp: Expedition) -> some View {
        switch exp.state {
        case .inProgress, .awaitingResolution:
            Section("Still on assignment") {
                HStack {
                    Text("Remaining")
                    Spacer()
                    ExpeditionCountdownView(endsAt: exp.endsAt)
                        .font(.body)
                }
                Text("Come back when the timer hits zero.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case .captured:
            capturedSection(exp)
        case .noCapture:
            Section {
                Label("No capture", systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
                Text("Even the best Hunters return empty-handed sometimes.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        case .handled:
            handledSection(exp)
        }
    }

    @ViewBuilder
    private func capturedSection(_ exp: Expedition) -> some View {
        if let animal = store.gameService.pendingAnimal(for: exp.id),
           let species = store.speciesById[animal.speciesId] {
            Section("Capture success!") {
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
                Text(species.habitatSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Section {
                NavigationLink(value: Route.captureName(expeditionId: exp.id)) {
                    Label("Add to Zoo", systemImage: "plus.circle.fill")
                }
                .accessibilityIdentifier("addToZooButton")

                Button(role: .destructive) {
                    _ = store.gameService.release(expeditionId: exp.id)
                } label: {
                    Label("Release", systemImage: "arrow.uturn.backward.circle")
                }
                .accessibilityIdentifier("releaseButton")
            }
        }
    }

    @ViewBuilder
    private func handledSection(_ exp: Expedition) -> some View {
        if exp.handledDecision == .keptInZoo,
           let animalId = exp.resultingAnimalId,
           let animal = store.animal(animalId) {
            Section("Added to your Zoo") {
                LabeledContent("Name", value: animal.nickname ?? "(unnamed)")
                NavigationLink(value: Route.animalDetail(animalId: animal.id)) {
                    Label("View in Zoo", systemImage: "leaf.fill")
                }
            }
        } else {
            Section {
                Label("Released", systemImage: "arrow.uturn.backward.circle")
                    .foregroundStyle(.secondary)
                Text("Back into the wild.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
