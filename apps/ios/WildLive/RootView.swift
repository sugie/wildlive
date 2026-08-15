// WildLive — Root: chooses Title vs. Home, hosts the NavigationStack.

import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        Group {
            if store.hasStarted {
                gameStack
            } else {
                TitleView()
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var gameStack: some View {
        @Bindable var bindableStore = store
        NavigationStack(path: $bindableStore.navigationPath) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .myZoo:
            MyZooView()
        case .otherZoos:
            OtherZoosView()
        case .visitZoo(let playerId):
            VisitZooView(playerId: playerId)
        case .animalDetail(let animalId):
            AnimalDetailView(animalId: animalId)
        case .guild:
            GuildView()
        case .regionPicker(let hunterId):
            RegionPickerView(hunterId: hunterId)
        case .dispatchConfirm(let hunterId, let regionId):
            DispatchConfirmView(hunterId: hunterId, regionId: regionId)
        case .expeditions:
            ExpeditionsView()
        case .expeditionResult(let expeditionId):
            ExpeditionResultView(expeditionId: expeditionId)
        case .captureName(let expeditionId):
            CaptureNameView(expeditionId: expeditionId)
        case .store:
            GStoreView()
        }
    }
}
