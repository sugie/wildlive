// WildLive — One expedition, from countdown to decision.
//
// Opening the screen asks the server for the expedition, which settles it
// if it is due. When it is still out, a live countdown and an explicit
// Resolve button once the timer reaches zero.
//
// A capture ends here with two choices and no default: KEEP opens the
// naming screen, RELEASE lets it go and returns nothing.

import SwiftUI

struct ExpeditionDetailView: View {
    @Environment(AppStore.self) private var store
    @State var viewModel: ExpeditionDetailViewModel

    var body: some View {
        Form {
            if let expedition = viewModel.expedition {
                summarySection(expedition)
                if expedition.devInstantResolve { developmentNoticeSection }
                stateSection(expedition)
            } else if viewModel.isLoading {
                Section {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Loading…").foregroundStyle(.secondary)
                    }
                }
            } else if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Expedition")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .accessibilityIdentifier("expeditionDetailView")
    }

    // MARK: Sections

    private func summarySection(_ expedition: Expedition) -> some View {
        Section {
            LabeledContent("Map", value: expedition.mapNameEN)
            LabeledContent("Hunter", value: expedition.hunterName)
            LabeledContent("Paid", value: "\(expedition.totalCostG) G")
            LabeledContent("Expedition time",
                           value: DurationFormat.minutes(expedition.plannedDurationMinutes))
        }
    }

    private var developmentNoticeSection: some View {
        Section {
            Label("Development run — the wait was skipped", systemImage: "hammer.fill")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.orange)
                .accessibilityIdentifier("devRunNotice")
        }
    }

    @ViewBuilder
    private func stateSection(_ expedition: Expedition) -> some View {
        if !expedition.isResolved {
            inFieldSection(expedition)
        } else if expedition.captured {
            capturedSection(expedition)
        } else {
            noCaptureSection(expedition)
        }
    }

    private func inFieldSection(_ expedition: Expedition) -> some View {
        Section("In the field") {
            HStack {
                Text("Returns")
                Spacer()
                ExpeditionCountdownView(endsAt: expedition.endsAt)
            }

            Button {
                Task {
                    await viewModel.resolve()
                }
            } label: {
                HStack {
                    if viewModel.isActing { ProgressView().controlSize(.small) }
                    Text("Resolve now").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!viewModel.canResolve || viewModel.isActing)
            .accessibilityIdentifier("resolveButton")

            if !viewModel.canResolve {
                Text("The Hunter is still out. Come back when the countdown reaches zero.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let error = viewModel.errorMessage {
                Text(error).font(.footnote).foregroundStyle(.orange)
            }
        }
    }

    @ViewBuilder
    private func capturedSection(_ expedition: Expedition) -> some View {
        if let species = expedition.resolution?.encounteredSpecies {
            Section("Capture") {
                LabeledContent("Species", value: species.nameEN)
                LabeledContent("Rarity") {
                    HStack(spacing: 6) {
                        Circle().fill(species.rarity.systemColor).frame(width: 10, height: 10)
                        Text(species.rarity.nameEN).foregroundStyle(.secondary)
                    }
                }
                LabeledContent("Zoo value", value: "\(species.baseZooValue)")
                if let resolution = expedition.resolution {
                    LabeledContent("Odds",
                                   value: "\(resolution.captureChancePercent)% · rolled \(resolution.captureRoll)")
                }
                Text(species.descriptionEN)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .accessibilityIdentifier("captureResultSection")
        }

        if expedition.awaitsDecision {
            decisionSection(expedition)
        } else {
            settledSection(expedition)
        }
    }

    private func decisionSection(_ expedition: Expedition) -> some View {
        Section {
            NavigationLink(value: Route.captureName(expeditionID: expedition.id)) {
                Label("Keep — add to My Zoo", systemImage: "plus.circle.fill")
            }
            .accessibilityIdentifier("keepButton")

            Button(role: .destructive) {
                Task { await viewModel.release() }
            } label: {
                HStack {
                    if viewModel.isActing { ProgressView().controlSize(.small) }
                    Label("Release", systemImage: "arrow.uturn.backward.circle")
                }
            }
            .disabled(viewModel.isActing)
            .accessibilityIdentifier("releaseButton")
        } footer: {
            Text("Releasing returns the animal to the wild. It pays nothing — the expedition's cost is already spent either way.")
        }
    }

    @ViewBuilder
    private func settledSection(_ expedition: Expedition) -> some View {
        Section {
            switch expedition.decision {
            case .kept:
                Label("Added to your Zoo as “\(expedition.zooAnimal?.name ?? "—")”",
                      systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .accessibilityIdentifier("keptConfirmation")
                NavigationLink(value: Route.myZoo) {
                    Label("Open My Zoo", systemImage: "leaf.fill")
                }
            case .released:
                Label("Released back into the wild", systemImage: "arrow.uturn.backward.circle")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("releasedConfirmation")
            case nil:
                EmptyView()
            }
        }
    }

    private func noCaptureSection(_ expedition: Expedition) -> some View {
        Section("No capture") {
            if let species = expedition.resolution?.encounteredSpecies {
                Label("\(species.nameEN) got away", systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
                if let resolution = expedition.resolution {
                    LabeledContent("Odds",
                                   value: "\(resolution.captureChancePercent)% · rolled \(resolution.captureRoll)")
                }
            } else {
                Label("Nothing was found", systemImage: "xmark.octagon.fill")
                    .foregroundStyle(.red)
            }
            Text("The cost is already spent, and failing costs nothing more. Even the best Hunters come back empty-handed.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("noCaptureSection")
    }
}
