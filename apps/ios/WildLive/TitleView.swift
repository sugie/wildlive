// WildLive — Milestone 001 title screen (Version 0).
// Intentionally minimal. Human UI review will drive the next iteration.

import SwiftUI

struct TitleView: View {
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
            colors: [
                Color(red: 0.04, green: 0.06, blue: 0.08),   // near-black
                Color(red: 0.06, green: 0.10, blue: 0.09),   // deep forest
                Color(red: 0.02, green: 0.04, blue: 0.06)    // darker at bottom
            ],
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
            // Version 0: no navigation. Just record the tap for verification.
            #if DEBUG
            print("START tapped")
            #endif
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
    }
}

#Preview {
    TitleView()
}
