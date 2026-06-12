//
//  BlockCategory.swift
//  staybusy
//

import SwiftUI

enum BlockCategory: String, CaseIterable, Identifiable, Codable {
    case gig
    case travel
    case food
    case social
    case work
    case explore
    case rest
    case admin

    var id: String { rawValue }

    var label: String {
        switch self {
        case .gig: return "Gig"
        case .travel: return "Travel"
        case .food: return "Food"
        case .social: return "Social"
        case .work: return "Work"
        case .explore: return "Explore"
        case .rest: return "Rest"
        case .admin: return "Admin"
        }
    }

    var symbol: String {
        switch self {
        case .gig: return "music.mic"
        case .travel: return "airplane"
        case .food: return "fork.knife"
        case .social: return "person.2.fill"
        case .work: return "laptopcomputer"
        case .explore: return "map.fill"
        case .rest: return "moon.zzz.fill"
        case .admin: return "tray.full.fill"
        }
    }

    /// Raw category color — use for stripes, fills, icons.
    var color: Color {
        Theme.Color.Category.color(for: self)
    }

    /// Category color suitable for text on `Theme.Color.surface`.
    /// Lightened for categories that fail 4.5:1 against surface (gig, explore).
    var textOnSurface: Color {
        Theme.Color.Category.onSurface(self)
    }
}
