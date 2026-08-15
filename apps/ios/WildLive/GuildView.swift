// WildLive — Guild: contract a Hunter, then choose a Region.

import SwiftUI

struct GuildView: View {
    @Environment(AppStore.self) private var store
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Theme.appBackground
            ScrollView {
                VStack(spacing: 16) {
                    header
                    if let hunter = store.contractedHunter {
                        contractedCard(hunter)
                    }
                    ForEach(store.hunters) { hunter in
                        hunterCard(hunter)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Guild")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Theme.bgTop, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Cannot contract", isPresented: errorBinding) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .accessibilityIdentifier("guildView")
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Contract a Hunter")
                .font(.headline).foregroundStyle(.white)
            Text("Basic Hunters are always available. Elite and Legendary Hunters are a shared Guild resource — sometimes they are already out on assignment.")
                .font(.caption).foregroundStyle(Theme.subtle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private func contractedCard(_ hunter: Hunter) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Currently under contract").font(.caption).foregroundStyle(Theme.accent)
            Text(hunter.name).font(.headline).foregroundStyle(.white)
            HStack {
                Button {
                    store.push(.regionPicker(hunterId: hunter.id))
                } label: {
                    Text("Choose Region → Dispatch")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14).padding(.vertical, 10)
                        .background(Capsule().fill(Theme.accent))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("chooseRegionButton")
                Spacer()
                Button(role: .destructive) {
                    store.gameService.releaseContract()
                } label: {
                    Text("Release").font(.caption)
                }
            }
        }
        .card()
    }

    private func hunterCard(_ hunter: Hunter) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hunter.name).font(.headline).foregroundStyle(.white)
                    Text("\(hunter.tier.label) · Skill \(hunter.skill)")
                        .font(.caption).foregroundStyle(Theme.subtle)
                }
                Spacer()
                statusChip(hunter)
            }
            Text(hunter.bio).font(.caption).foregroundStyle(.white.opacity(0.8))
            HStack {
                Text("G \(hunter.contractCostG)")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Spacer()
                Button {
                    attemptContract(hunter)
                } label: {
                    Text(store.contractedHunterId == hunter.id ? "Contracted" : "Contract")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(
                            Capsule().fill(
                                canContract(hunter) ? Theme.accent : Color.white.opacity(0.15)
                            )
                        )
                        .foregroundStyle(canContract(hunter) ? .black : Color.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .disabled(!canContract(hunter))
                .accessibilityIdentifier("contractButton_\(hunter.id)")
            }
        }
        .card()
    }

    private func statusChip(_ hunter: Hunter) -> some View {
        Group {
            if store.contractedHunterId == hunter.id {
                Text("YOURS")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(Theme.accent))
                    .foregroundStyle(.black)
            } else if !hunter.available {
                Text("Booked").font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
                    .foregroundStyle(Theme.subtle)
            } else {
                Text("Available").font(.caption2)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().stroke(Theme.subtle, lineWidth: 1))
                    .foregroundStyle(Theme.subtle)
            }
        }
    }

    private func canContract(_ hunter: Hunter) -> Bool {
        guard store.contractedHunterId == nil else { return false }
        guard hunter.available else { return false }
        return store.currentPlayer.gBalance >= hunter.contractCostG
    }

    private func attemptContract(_ hunter: Hunter) {
        switch store.gameService.contract(hunterId: hunter.id) {
        case .success:
            break
        case .failure(let err):
            errorMessage = err.localizedDescription
        }
    }
}
