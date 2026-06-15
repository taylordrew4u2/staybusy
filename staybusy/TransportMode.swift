//
//  TransportMode.swift
//  staybusy
//
//  User-selectable mode for the leave-by ETA calculation. Persisted
//  via @AppStorage("transportMode") and mirrored to iCloud so the
//  choice rides along with the user across devices.
//

import SwiftUI
import MapKit

enum TransportMode: String, CaseIterable, Identifiable {
    case driving
    case transit
    case walking
    case cycling

    var id: String { rawValue }

    var label: String {
        switch self {
        case .driving: return "Driving"
        case .transit: return "Transit"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        }
    }

    var symbol: String {
        switch self {
        case .driving: return "car.fill"
        case .transit: return "tram.fill"
        case .walking: return "figure.walk"
        case .cycling: return "bicycle"
        }
    }

    /// MapKit equivalent. Walking + cycling aren't separately supported
    /// by `MKDirectionsTransportType`, so cycling falls back to
    /// walking — close enough for the leave-by estimate.
    var mkType: MKDirectionsTransportType {
        switch self {
        case .driving: return .automobile
        case .transit: return .transit
        case .walking, .cycling: return .walking
        }
    }

    /// Word that fits in "you'll be reminded 2h ahead by X" / "Leave
    /// X to ___" — used in notification bodies and the editor hint.
    var verbForm: String {
        switch self {
        case .driving: return "to drive"
        case .transit: return "by transit"
        case .walking: return "to walk"
        case .cycling: return "to cycle"
        }
    }

    static let storageKey = "transportMode"

    /// Resolve the current setting from UserDefaults. Used by
    /// LeaveByModel, which doesn't have @AppStorage available.
    static var current: TransportMode {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? ""
        return TransportMode(rawValue: raw) ?? .driving
    }
}
