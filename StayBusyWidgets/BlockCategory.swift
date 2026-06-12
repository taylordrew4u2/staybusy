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

    var color: Color {
        switch self {
        case .gig:
            return Theme.accent
        case .travel:
            return Color(red: 0.30, green: 0.69, blue: 0.95)
        case .food:
            return Color(red: 0.98, green: 0.65, blue: 0.20)
        case .social:
            return Color(red: 0.85, green: 0.45, blue: 0.90)
        case .work:
            return Color(red: 0.50, green: 0.55, blue: 0.95)
        case .explore:
            return Color(red: 0.30, green: 0.80, blue: 0.55)
        case .rest:
            return Color(red: 0.48, green: 0.55, blue: 0.70)
        case .admin:
            return Color(red: 0.70, green: 0.70, blue: 0.75)
        }
    }
}
