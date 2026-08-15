// WildLive — Shared visual tokens for the UI prototype.

import SwiftUI

enum Theme {
    static let bgTop    = Color(red: 0.04, green: 0.06, blue: 0.08)
    static let bgMid    = Color(red: 0.06, green: 0.10, blue: 0.09)
    static let bgBottom = Color(red: 0.02, green: 0.04, blue: 0.06)

    static let cardFill    = Color.white.opacity(0.05)
    static let cardStroke  = Color.white.opacity(0.10)
    static let accent      = Color(red: 0.85, green: 0.75, blue: 0.35)  // muted gold
    static let danger      = Color(red: 0.90, green: 0.35, blue: 0.30)
    static let subtle      = Color.white.opacity(0.55)

    static var appBackground: some View {
        LinearGradient(
            colors: [bgTop, bgMid, bgBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    static func rarityColor(_ rarity: SpeciesRarity) -> Color {
        switch rarity {
        case .common:    return Color.white.opacity(0.55)
        case .uncommon:  return Color(red: 0.45, green: 0.85, blue: 0.55)
        case .rare:      return Color(red: 0.40, green: 0.70, blue: 0.95)
        case .epic:      return Color(red: 0.75, green: 0.50, blue: 0.95)
        case .legendary: return Color(red: 0.95, green: 0.70, blue: 0.30)
        }
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Theme.cardStroke, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}
