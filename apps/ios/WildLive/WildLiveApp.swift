// WildLive — iOS client entry point.
//
// UI-first: most of the app runs against in-memory dummy data. First-time
// player registration is the exception — it calls the real Laravel API
// through `LivePlayerRegistrationService`.
//
// Launch arguments (UI tests only):
//   --ui-tests-mock-api         → use MockPlayerRegistrationService
//   --ui-tests-fresh            → clear any persisted session on launch
//   --ui-tests-preregistered    → seed a fake session so Home is reachable
//                                  without going through the form

import SwiftUI

@main
struct WildLiveApp: App {
    @State private var appStore: AppStore

    init() {
        let args = ProcessInfo.processInfo.arguments
        let useMock = args.contains("--ui-tests-mock-api")
        let clearFirst = args.contains("--ui-tests-fresh")
        let preregister = args.contains("--ui-tests-preregistered")

        let session = PlayerSession()
        if clearFirst { session.clear() }
        if preregister {
            session.persist(
                RegisteredPlayer(
                    playerId: "00000000-0000-0000-0000-0000000000ff",
                    displayName: "UITest",
                    zooId: "00000000-0000-0000-0000-0000000000fe",
                    createdAt: Date()
                )
            )
        }

        let regService: PlayerRegistrationServiceProtocol = useMock
            ? MockPlayerRegistrationService()
            : LivePlayerRegistrationService()

        _appStore = State(
            initialValue: AppStore(session: session, registrationService: regService)
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appStore)
        }
    }
}
