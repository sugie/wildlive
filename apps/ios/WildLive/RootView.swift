// WildLive — Root: chooses Title / Registration / Home, hosts NavigationStack.
//
// Post-START behaviour depends on the session:
//   - no persisted session → RegistrationView (submit calls the real API)
//   - persisted session    → Home dashboard

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
            Group {
                if store.isRegistered {
                    HomeView()
                } else {
                    RegistrationView()
                }
            }
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
