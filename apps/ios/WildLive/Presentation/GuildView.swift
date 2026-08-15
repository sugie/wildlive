// WildLive — The Guild roster.
//
// Browse-only. Contracting happens inside the expedition flow (Maps →
// Map → Hunters), because a contract only exists in the context of one
// expedition — there is nothing to hire here and nothing to keep.
//
// Rendered by HunterPickerView with no map: same list, no destination.

import SwiftUI

struct GuildView: View {
    @State var viewModel: HunterListViewModel

    var body: some View {
        HunterPickerView(viewModel: viewModel)
            .navigationTitle("Guild")
    }
}
