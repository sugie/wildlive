// WildLive — Title screen.
//
// Iteration 2: rendered against Apple SwiftUI defaults — system background,
// system typography, system blue tint on the primary action. No custom
// gradients, no forced colour scheme.

import SwiftUI

struct TitleView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 8) {
                Text("WildLive")
                    .font(.largeTitle.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)

                Text("AI Made Live MMO")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(2)
            }

            Spacer()

            Button {
                store.start()
            } label: {
                Text("Start")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .accessibilityLabel("Start")
            .accessibilityIdentifier("startButton")
        }
    }
}

#Preview {
    TitleView()
        .environment(AppStore())
}
