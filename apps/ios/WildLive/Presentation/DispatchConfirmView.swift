// WildLive — The last screen before G is spent.
//
// Everything shown here is the server's own quote for this exact
// map + hunter pair, so the cost and the duration a player agrees to are
// the ones they will be charged and made to wait.

import SwiftUI

struct DispatchConfirmView: View {
    @Environment(AppStore.self) private var store
    @State var viewModel: DispatchConfirmViewModel

    var body: some View {
        Form {
            if let map = viewModel.map, let hunter = viewModel.hunter {
                summarySection(map: map, hunter: hunter)
                costSection
                // The developer section only exists in a DEBUG build, so in
                // a release build the action sits directly under the cost
                // and needs no scrolling.
                #if DEBUG
                developerSection
                #endif
                actionSection
            } else if viewModel.isLoading {
                Section {
                    HStack {
                        ProgressView().controlSize(.small)
                        Text("Preparing…").foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Dispatch")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .alert("Dispatch failed", isPresented: errorBinding) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .accessibilityIdentifier("dispatchConfirmView")
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private func summarySection(map: GameMap, hunter: Hunter) -> some View {
        Section("Expedition") {
            LabeledContent("Map", value: map.nameEN)
            LabeledContent("Hunter", value: hunter.name)
            LabeledContent("Rank", value: hunter.rank)
            if viewModel.hasBiomeAffinity {
                Label("Biome match — better odds of a capture here",
                      systemImage: "leaf.fill")
                    .font(.footnote)
                    .foregroundStyle(.green)
            }
        }
    }

    @ViewBuilder
    private var costSection: some View {
        Section {
            if let map = viewModel.map, let hunter = viewModel.hunter {
                LabeledContent("Map cost", value: "\(map.baseCostG) G")
                LabeledContent("Hunter contract", value: "\(hunter.contractCostG) G")
            }
            if let total = viewModel.totalCostG {
                LabeledContent("Total") {
                    Text("\(total) G")
                        .monospacedDigit()
                        .fontWeight(.semibold)
                        .foregroundStyle(viewModel.canAfford(balance: store.overview?.gBalance)
                                         ? .primary : Color.red)
                }
                .accessibilityIdentifier("dispatchTotalCost")
            }
            if let balance = store.overview?.gBalance {
                LabeledContent("Your balance", value: "\(balance) G")
            }
            if let minutes = viewModel.durationMinutes {
                LabeledContent("Returns in", value: DurationFormat.minutes(minutes))
            }
        } footer: {
            Text("The cost is paid now and is not refunded — a Hunter who comes back empty-handed costs nothing extra, but nothing comes back either.")
        }
    }

    #if DEBUG
    /// Development-only. The server refuses this outright in any
    /// environment that does not allow it, so the switch cannot become a
    /// production shortcut; it is DEBUG-gated here as well so it never
    /// even renders in a release build.
    private var developerSection: some View {
        Section {
            Toggle(isOn: $viewModel.devInstantResolve) {
                Label("Resolve instantly", systemImage: "hammer.fill")
            }
            .tint(.orange)
            .accessibilityIdentifier("devInstantResolveToggle")
        } header: {
            Text("Developer")
        } footer: {
            Text("DEVELOPMENT ONLY. Skips the wait so the loop can be played end to end. The expedition is permanently flagged as a development run, and the real duration is still recorded. The server rejects this outside local and testing environments.")
        }
    }
    #endif

    private var actionSection: some View {
        Section {
            Button {
                Task { await viewModel.dispatch() }
            } label: {
                HStack {
                    if viewModel.isDispatching {
                        ProgressView().controlSize(.small)
                    }
                    Text(viewModel.isDispatching ? "Dispatching…" : "Start Expedition")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isDispatching
                      || !viewModel.canAfford(balance: store.overview?.gBalance))
            .accessibilityIdentifier("dispatchButton")
        }
    }
}
