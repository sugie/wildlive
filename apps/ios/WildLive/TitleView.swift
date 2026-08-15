// WildLive — Title screen.
//
// Introduced in Milestone 001. Since Milestone 002 the START button hands
// off to the in-memory NavigationStack owned by AppStore.

import SwiftUI

struct TitleView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        ZStack {
            backgroundGradient
                .ignoresSafeArea()

            VStack {
                Spacer()

                titleBlock

                Spacer()

                startButton
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 32)
        }
        .preferredColorScheme(.dark)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Theme.bgTop, Theme.bgMid, Theme.bgBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var titleBlock: some View {
        VStack(spacing: 12) {
            Text("WildLive")
                .font(.system(size: 64, weight: .heavy, design: .serif))
                .foregroundStyle(.white)
                .tracking(2)
                .accessibilityAddTraits(.isHeader)

            Text("AI Made Live MMO")
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundStyle(.white.opacity(0.7))
                .tracking(4)
                .textCase(.uppercase)
        }
        .multilineTextAlignment(.center)
    }

    private var startButton: some View {
        Button {
            store.start()
        } label: {
            Text("START")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .tracking(6)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.92))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start")
        .accessibilityIdentifier("startButton")
    }
}

#Preview {
    TitleView()
        .environment(AppStore())
}
