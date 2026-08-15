// WildLive — Colour and formatting helpers, used only where they carry
// real information (rarity tier, map difficulty, expedition timing).
// Everything else is Apple defaults.

import SwiftUI

// MARK: - Live game types

extension Rarity {
    /// Cool for common, warm for rare. Ordered by the Game Master's own
    /// sort_order rather than the tier id, so a future sixth tier still
    /// lands somewhere sensible instead of falling into a default case.
    var systemColor: Color {
        switch sortOrder {
        case 1:  return .gray
        case 2:  return .green
        case 3:  return .blue
        case 4:  return .purple
        default: return .orange
        }
    }
}

extension GameMap {
    var difficultyColor: Color {
        switch difficulty {
        case 1:  return .green
        case 2:  return .yellow
        case 3:  return .orange
        default: return .red
        }
    }

    var difficultyLabel: String {
        switch difficulty {
        case 1:  return "Easy"
        case 2:  return "Moderate"
        case 3:  return "Hard"
        case 4:  return "Severe"
        default: return "Extreme"
        }
    }
}

// MARK: - Durations

enum DurationFormat {
    /// Canonical expedition durations run from 10 minutes to 6 hours, so
    /// "360 min" needs to read as "6h" to be usable in a list.
    static func minutes(_ total: Int) -> String {
        if total < 60 { return "\(total) min" }
        let hours = total / 60
        let minutes = total % 60
        return minutes == 0 ? "\(hours) h" : "\(hours) h \(minutes) min"
    }

    /// A live countdown to an expedition's return.
    static func remaining(seconds: Int) -> String {
        if seconds <= 0 { return "Ready" }
        if seconds < 60 { return "\(seconds)s" }
        let m = seconds / 60
        let s = seconds % 60
        if m < 60 { return String(format: "%d:%02d", m, s) }
        return String(format: "%d:%02d:%02d", m / 60, m % 60, s)
    }
}

// MARK: - Prototype types (Other Zoos / G Store screens)

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
