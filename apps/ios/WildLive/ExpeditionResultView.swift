// WildLive — Expedition result. Resolves lazily on view; offers capture flow.

import SwiftUI

struct ExpeditionResultView: View {
    @Environment(AppStore.self) private var store
    let expeditionId: UUID

    var body: some View {
        ZStack {
            Theme.appBackground
            ScrollView {
                if let exp = store.expedition(expeditionId) {
                    content(for: exp)
                        .padding(20)
                } else {
                    Text("Expedition not found").foregroundStyle(Theme.subtle).padding(40)
                }
            }
        }
        .navigationTitle("Expedition")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.bgTop, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            // Idempotent — safe to call every time we open the view.
            _ = store.gameService.resolve(expeditionId: expeditionId)
        }
    }

    @ViewBuilder
    private func content(for exp: Expedition) -> some View {
        let hunter = store.hunter(exp.hunterId)
        let region = store.region(exp.regionId)

        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(hunter?.name ?? "Hunter")
                    .font(.headline).foregroundStyle(.white)
                Text(region?.name ?? "Region")
                    .font(.subheadline).foregroundStyle(Theme.subtle)
                Text("Started \(exp.startedAt.formatted(date: .omitted, time: .standard))")
                    .font(.caption).foregroundStyle(Theme.subtle)
                if let resolved = exp.resolvedAt {
                    Text("Resolved \(resolved.formatted(date: .omitted, time: .standard))")
                        .font(.caption).foregroundStyle(Theme.subtle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()

            switch exp.state {
            case .inProgress, .awaitingResolution:
                VStack(spacing: 8) {
                    Text("Still on assignment.")
                        .font(.headline).foregroundStyle(.white)
                    ExpeditionCountdownView(endsAt: exp.endsAt)
                        .font(.title2)
                    Text("Come back when the timer hits zero.")
                        .font(.caption).foregroundStyle(Theme.subtle)
                }
                .frame(maxWidth: .infinity)
                .card()
            case .captured:
                capturedBlock(exp: exp)
            case .noCapture:
                noCaptureBlock
            case .handled:
                handledBlock(exp: exp)
            }
        }
    }

    @ViewBuilder
    private func capturedBlock(exp: Expedition) -> some View {
        if let animal = store.gameService.pendingAnimal(for: exp.id),
           let species = store.speciesById[animal.speciesId] {
            VStack(alignment: .leading, spacing: 12) {
                Text("Capture success!")
                    .font(.title3.weight(.semibold)).foregroundStyle(Theme.accent)
                HStack(spacing: 8) {
                    Circle().fill(Theme.rarityColor(species.rarity)).frame(width: 10, height: 10)
                    Text(species.rarity.label.uppercased())
                        .font(.caption.weight(.semibold)).tracking(2)
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
                Text(species.habitatSummary).font(.caption).foregroundStyle(.white.opacity(0.8))

                HStack(spacing: 12) {
                    Button {
                        store.push(.captureName(expeditionId: exp.id))
                    } label: {
                        Text("Add to Zoo")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Theme.accent))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("addToZooButton")

                    Button {
                        _ = store.gameService.release(expeditionId: exp.id)
                    } label: {
                        Text("Release")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Theme.danger, lineWidth: 1)
                            )
                            .foregroundStyle(Theme.danger)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("releaseButton")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
        }
    }

    private var noCaptureBlock: some View {
        VStack(spacing: 8) {
            Text("No capture")
                .font(.title3.weight(.semibold)).foregroundStyle(Theme.danger)
            Text("Even the best Hunters return empty-handed sometimes.")
                .font(.caption).foregroundStyle(Theme.subtle)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .card()
    }

    @ViewBuilder
    private func handledBlock(exp: Expedition) -> some View {
        if exp.handledDecision == .keptInZoo, let animalId = exp.resultingAnimalId, let animal = store.animal(animalId) {
            VStack(spacing: 8) {
                Text("Added to your Zoo").font(.headline).foregroundStyle(.white)
                Text(animal.nickname ?? "(unnamed)")
                    .font(.title3.weight(.semibold)).foregroundStyle(Theme.accent)
                Button {
                    store.push(.animalDetail(animalId: animal.id))
                } label: {
                    Text("View in Zoo")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().stroke(Theme.accent, lineWidth: 1))
                        .foregroundStyle(Theme.accent)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity).card()
        } else {
            VStack(spacing: 8) {
                Text("Released").font(.headline).foregroundStyle(.white)
                Text("Back into the wild.").font(.caption).foregroundStyle(Theme.subtle)
            }
            .frame(maxWidth: .infinity).card()
        }
    }
}
