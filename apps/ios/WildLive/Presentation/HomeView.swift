// WildLive — Home dashboard.
//
// Every number on this screen comes from the server. It reloads on each
// appearance because an expedition settled elsewhere in the app changes
// what Home should say.
//
// Apple defaults throughout: List with grouped Sections, LabeledContent
// for scalar stats, Labels with system SF Symbols for navigation rows.

import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store
    @State var viewModel: HomeViewModel

    var body: some View {
        List {
            statusSection
            expeditionsSection
            navigationSection
            signOutSection
        }
        .navigationTitle("WildLive")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .accessibilityIdentifier("homeView")
    }

    // MARK: Sections

    @ViewBuilder
    private var statusSection: some View {
        Section("Zookeeper") {
            LabeledContent("Name", value: viewModel.overview?.displayName ?? store.displayName)

            LabeledContent("G Balance") {
                if let overview = viewModel.overview {
                    Text("\(overview.gBalance)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("gBalanceValue")
                } else {
                    loadingOrError
                }
            }

            LabeledContent("Zoo Value", value: "\(viewModel.overview?.zoo.zooValue ?? 0)")
            LabeledContent("Animals") {
                Text("\(viewModel.overview?.zoo.animalCount ?? 0)")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("animalCountValue")
            }

            Button {
                store.push(.store)
            } label: {
                Label("Buy G", systemImage: "cart.badge.plus")
            }
            .accessibilityIdentifier("buyGButton")
        }
    }

    @ViewBuilder
    private var loadingOrError: some View {
        if viewModel.isLoading {
            ProgressView().controlSize(.small)
        } else if viewModel.errorMessage != nil {
            Label("Unavailable", systemImage: "exclamationmark.triangle.fill")
                .labelStyle(.titleAndIcon)
                .font(.caption)
                .foregroundStyle(.orange)
        } else {
            Text("—").foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var expeditionsSection: some View {
        Section("Expeditions") {
            if let error = viewModel.errorMessage {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Cannot reach WildLive", systemImage: "wifi.exclamationmark")
                        .foregroundStyle(.orange)
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("homeErrorRow")
            }

            let overview = viewModel.overview

            if let overview, overview.pendingDecisions > 0 {
                Label(
                    "\(overview.pendingDecisions) capture(s) awaiting your decision.",
                    systemImage: "exclamationmark.circle.fill"
                )
                .foregroundStyle(.orange)
                .accessibilityIdentifier("pendingDecisionsBadge")
            }

            if let overview, overview.activeExpeditions > 0 {
                Label("\(overview.activeExpeditions) expedition(s) in the field.",
                      systemImage: "figure.walk.motion")
                    .foregroundStyle(.secondary)
            }

            if overview?.activeExpeditions == 0 && overview?.pendingDecisions == 0 {
                Text("No active expeditions. Choose a Map to send one out.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            NavigationLink(value: Route.maps) {
                Label("Send an Expedition", systemImage: "map.fill")
            }
            .accessibilityIdentifier("navMaps")
        }
    }

    private var navigationSection: some View {
        Section {
            NavigationLink(value: Route.myZoo) {
                Label("My Zoo", systemImage: "leaf.fill")
            }
            .accessibilityIdentifier("navMyZoo")

            NavigationLink(value: Route.expeditions) {
                Label("Expeditions", systemImage: "list.bullet.rectangle")
            }
            .accessibilityIdentifier("navExpeditions")

            NavigationLink(value: Route.guild) {
                Label("Guild", systemImage: "figure.walk")
            }
            .accessibilityIdentifier("navGuild")

            NavigationLink(value: Route.otherZoos) {
                Label("Other Zoos", systemImage: "person.2.fill")
            }
            .accessibilityIdentifier("navOtherZoos")

            NavigationLink(value: Route.store) {
                Label("Store", systemImage: "creditcard.fill")
            }
            .accessibilityIdentifier("navStore")
        }
    }

    private var signOutSection: some View {
        Section {
            Button("Sign out (return to title)", role: .destructive) {
                store.returnToTitle()
            }
        }
    }
}
