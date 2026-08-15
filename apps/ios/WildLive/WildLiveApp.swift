// WildLive — iOS client.
//
// UI-first: the whole app runs against in-memory dummy data. No network,
// no persistence, no backend. When the API arrives, `AppStore` is the
// single hand-off point.

import SwiftUI

@main
struct WildLiveApp: App {
    @State private var appStore = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appStore)
        }
    }
}
