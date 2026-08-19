// WildLive — Root: chooses Title / Registration / Home, hosts the
// NavigationStack, and builds each destination's ViewModel.
//
// This is where the composition root's dependencies meet the screens.
// Every ViewModel is constructed here with the repositories and use cases
// WildLiveApp supplied, and given a closure for anything it needs to push
// back into AppStore — so no ViewModel imports AppStore, and no View
// constructs a repository.

import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store
    let registerPlayer: RegisterPlayer
    let sessionRepository: PlayerSessionRepository
    let game: GameDependencies

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
                if let playerID = store.playerID {
                    HomeView(viewModel: makeHomeViewModel(playerID: playerID))
                } else {
                    RegistrationView(viewModel: makeRegistrationViewModel())
                }
            }
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
        }
    }

    // MARK: Destinations

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        // Every gameplay screen needs the player id. It exists for the whole
        // of this stack's lifetime (the stack only renders once registered),
        // but the type is optional, so unwrap once here rather than in nine
        // ViewModels.
        if let playerID = store.playerID {
            switch route {
            case .myZoo:
                MyZooView(viewModel: MyZooViewModel(
                    playerID: playerID,
                    profiles: game.profiles
                ))

            case .maps:
                MapListView(viewModel: MapListViewModel(
                    playerID: playerID,
                    catalog: game.catalog
                ))

            case .mapDetail(let mapID):
                MapDetailView(viewModel: MapDetailViewModel(
                    playerID: playerID,
                    mapID: mapID,
                    catalog: game.catalog
                ))

            case .hunterPicker(let mapID):
                HunterPickerView(viewModel: HunterListViewModel(
                    mapID: mapID,
                    catalog: game.catalog
                ))

            case .dispatchConfirm(let mapID, let hunterID):
                DispatchConfirmView(viewModel: makeDispatchViewModel(
                    playerID: playerID, mapID: mapID, hunterID: hunterID
                ))

            case .expeditions:
                ExpeditionsView(viewModel: ExpeditionsViewModel(
                    playerID: playerID,
                    repository: game.expeditions,
                    notifier: game.notifier
                ))

            case .expedition(let expeditionID):
                ExpeditionDetailView(viewModel: makeExpeditionDetailViewModel(
                    playerID: playerID, expeditionID: expeditionID
                ))

            case .captureName(let expeditionID):
                CaptureNameView(viewModel: makeCaptureNameViewModel(
                    playerID: playerID, expeditionID: expeditionID
                ))

            case .guild:
                GuildView(viewModel: HunterListViewModel(
                    mapID: nil,
                    catalog: game.catalog
                ))

            // Prototype screens, still on sample data.
            case .otherZoos:                  OtherZoosView()
            case .visitZoo(let playerId):     VisitZooView(playerId: playerId)
            case .animalDetail(let animalId): AnimalDetailView(animalId: animalId)
            case .store:                      GStoreView()
            }
        } else {
            // Only reachable if the session was cleared mid-navigation.
            Text("Session ended.").foregroundStyle(.secondary)
        }
    }

    // MARK: ViewModel factories

    private func makeRegistrationViewModel() -> RegistrationViewModel {
        RegistrationViewModel(
            registerPlayer: registerPlayer,
            onSuccess: { [store] registered in
                store.adoptRegistration(registered)
            }
        )
    }

    private func makeHomeViewModel(playerID: String) -> HomeViewModel {
        HomeViewModel(
            playerID: playerID,
            profiles: game.profiles,
            notifier: game.notifier,
            onLoaded: { [store] overview in store.apply(overview) }
        )
    }

    private func makeDispatchViewModel(
        playerID: String,
        mapID: String,
        hunterID: String
    ) -> DispatchConfirmViewModel {
        DispatchConfirmViewModel(
            playerID: playerID,
            mapID: mapID,
            hunterID: hunterID,
            catalog: game.catalog,
            startExpedition: game.startExpedition,
            notifier: game.notifier,
            devInstantResolveDefault: game.devInstantResolveDefault,
            onDispatched: { [store] expedition, overview in
                store.apply(overview)
                // Replace the setup screens with the expedition itself:
                // going Back from a running expedition should return Home,
                // not to the Hunter you already contracted.
                store.resetPath(to: [.expedition(expeditionID: expedition.id)])
            }
        )
    }

    private func makeExpeditionDetailViewModel(
        playerID: String,
        expeditionID: String
    ) -> ExpeditionDetailViewModel {
        ExpeditionDetailViewModel(
            playerID: playerID,
            expeditionID: expeditionID,
            repository: game.expeditions,
            resolveExpedition: game.resolveExpedition,
            decideCapture: game.decideCapture,
            notifier: game.notifier,
            onOverviewChanged: { [store] overview in store.apply(overview) }
        )
    }

    private func makeCaptureNameViewModel(
        playerID: String,
        expeditionID: String
    ) -> CaptureNameViewModel {
        CaptureNameViewModel(
            playerID: playerID,
            expeditionID: expeditionID,
            repository: game.expeditions,
            decideCapture: game.decideCapture,
            onKept: { [store] _, overview in
                store.apply(overview)
                // Land the player in My Zoo, with Home behind it — the
                // animal they just named is the thing they want to see.
                store.resetPath(to: [.myZoo])
            }
        )
    }
}
