// WildLive — Colour helpers used only where colour carries real information
// (rarity tier, region difficulty). Everything else is Apple defaults.

import SwiftUI

extension SpeciesRarity {
    var systemColor: Color {
        switch self {
        case .common:    .gray
        case .uncommon:  .green
        case .rare:      .blue
        case .epic:      .purple
        case .legendary: .orange
        }
    }
}

extension Region.Difficulty {
    var systemColor: Color {
        switch self {
        case .easy:    .green
        case .medium:  .yellow
        case .high:    .orange
        case .extreme: .red
        }
    }
}
