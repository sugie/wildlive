// WildLive — Root: chooses Title vs. Home, hosts the NavigationStack.
//
// No forced colour scheme — follows the system.

import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        if store.hasStarted {
            gameStack
        } else {
            TitleView()
        }
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
        case .myZoo:                          MyZooView()
        case .otherZoos:                      OtherZoosView()
        case .visitZoo(let playerId):         VisitZooView(playerId: playerId)
        case .animalDetail(let animalId):     AnimalDetailView(animalId: animalId)
        case .guild:                          GuildView()
        case .regionPicker(let hunterId):     RegionPickerView(hunterId: hunterId)
        case .dispatchConfirm(let h, let r):  DispatchConfirmView(hunterId: h, regionId: r)
        case .expeditions:                    ExpeditionsView()
        case .expeditionResult(let id):       ExpeditionResultView(expeditionId: id)
        case .captureName(let id):            CaptureNameView(expeditionId: id)
        case .store:                          GStoreView()
        }
    }
}
