// WildLive — Root: chooses Title / Registration / Home, hosts NavigationStack.
//
// Receives the RegisterPlayer use case + PlayerSessionRepository from the
// composition root and constructs a fresh RegistrationViewModel bound to
// the AppStore. The ViewModel is given an `onSuccess` closure that pushes
// the registered player into AppStore — the ViewModel itself never
// imports AppStore.

import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store
    let registerPlayer: RegisterPlayer
    let sessionRepository: PlayerSessionRepository

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
                    RegistrationView(viewModel: makeRegistrationViewModel())
                }
            }
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
        }
    }

    private func makeRegistrationViewModel() -> RegistrationViewModel {
        RegistrationViewModel(
            registerPlayer: registerPlayer,
            onSuccess: { [store] registered in
                store.adoptRegistration(registered)
            }
        )
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
