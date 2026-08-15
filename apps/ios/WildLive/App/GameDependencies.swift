// WildLive — The gameplay object graph, assembled once at launch.
//
// Everything the live expedition loop needs, in one value the composition
// root builds and hands down. Screens receive the pieces they use; none of
// them ever constructs a repository, so swapping Live for Mock is a single
// decision made in WildLiveApp.init.
//
// This type lives in App/ because it IS the composition root's vocabulary.
// It names Domain protocols and Application use cases — never concrete Data
// implementations, which is why the same struct serves the live app, the
// previews, and the UI tests.

import Foundation

struct GameDependencies {
    let catalog: GameCatalogRepository
    let expeditions: ExpeditionRepository
    let profiles: PlayerProfileRepository

    let startExpedition: StartExpedition
    let resolveExpedition: ResolveExpedition
    let decideCapture: DecideCapturedAnimal

    /// Whether the dispatch screen's developer toggle starts switched on.
    ///
    /// Always false for a human launching the app; set only by the
    /// `--ui-tests-instant-expeditions` launch argument, because a UI test
    /// cannot wait out a 10-minute expedition. The server still decides
    /// whether to honour the request.
    let devInstantResolveDefault: Bool

    init(
        catalog: GameCatalogRepository,
        expeditions: ExpeditionRepository,
        profiles: PlayerProfileRepository,
        devInstantResolveDefault: Bool = false
    ) {
        self.catalog = catalog
        self.expeditions = expeditions
        self.profiles = profiles
        self.devInstantResolveDefault = devInstantResolveDefault
        self.startExpedition = StartExpedition(expeditions: expeditions, profiles: profiles)
        self.resolveExpedition = ResolveExpedition(expeditions: expeditions)
        self.decideCapture = DecideCapturedAnimal(expeditions: expeditions, profiles: profiles)
    }

    /// The in-memory graph, for SwiftUI previews and UI tests that must run
    /// without Laravel and PostgreSQL.
    static func mocked(
        displayName: String = "UITest",
        devInstantResolveDefault: Bool = false
    ) -> GameDependencies {
        GameDependencies(
            catalog: MockGameCatalogRepository(),
            expeditions: MockExpeditionRepository(),
            profiles: MockPlayerProfileRepository(displayName: displayName),
            devInstantResolveDefault: devInstantResolveDefault
        )
    }

    /// The real graph, talking to the Laravel API.
    static func live(devInstantResolveDefault: Bool = false) -> GameDependencies {
        GameDependencies(
            catalog: LiveGameCatalogRepository(),
            expeditions: LiveExpeditionRepository(),
            profiles: LivePlayerProfileRepository(),
            devInstantResolveDefault: devInstantResolveDefault
        )
    }
}
