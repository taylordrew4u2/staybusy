//
//  Theme.swift
//  StayBusyWidgets
//
//  Widget-extension copy of the design tokens. Mirrors the same schema
//  as the main app's Theme.swift, minus members the widget runtime can't
//  use (haptics, the runtime-bound motion API). Keep these two files in
//  sync — they describe the same design system.
//
//  Token schema (authoritative — keep this and the code below in sync):
//
//  {
//    "color": {
//      "background":      "#0D0D0F",
//      "surface":         "#17171A",
//      "surfaceElevated": "#1F1F24",
//      "accent":          "#E53935",
//      "textPrimary":     "#F5F5F7",
//      "textSecondary":   "#A1A1AA",
//      "textTertiary":    "#6B6B73",
//      "openSlot":        "#3A3A41",
//      "hourRule":        "#383842",
//      "warning":         "#F5A623",
//      "success":         "#34C759",
//      "category": {
//        "gig":     "#E53935",
//        "travel":  "#F59E0A",
//        "food":    "#4CAF50",
//        "social":  "#ED5999",
//        "work":    "#428AF5",
//        "explore": "#8C5CF5",
//        "rest":    "#738C99",
//        "admin":   "#9E9E9E"
//      }
//    },
//    "typography": {
//      "displayCountdown": { "base": "largeTitle", "weight": "heavy",   "monospacedDigit": true },
//      "titleLarge":       { "base": "title",      "weight": "heavy" },
//      "title":            { "base": "headline",   "weight": "bold" },
//      "body":             { "base": "body",       "weight": "medium" },
//      "caption":          { "base": "caption",    "weight": "medium",  "monospacedDigit": true },
//      "codeHuge":         { "base": "largeTitle", "weight": "bold",    "design": "monospaced" }
//    },
//    "spacing": { "xs": 4, "s": 8, "m": 12, "l": 16, "xl": 24, "xxl": 32 },
//    "radius":  { "small": 8, "medium": 14, "large": 22 },
//    "stroke":  { "openSlotDash": { "width": 1.5, "dash": [6, 5] }, "currentBlockBorder": 2 },
//    "opacity": { "pastBlock": 0.4, "pressed": 0.97 },
//    "size":    { "minTapTarget": 44, "categoryStripeWidth": 4 }
//  }
//

import SwiftUI

enum Theme {

    // MARK: - Color

    enum Color {
        static let background      = SwiftUI.Color(hex: 0x0D0D0F)
        static let surface         = SwiftUI.Color(hex: 0x17171A)
        static let surfaceElevated = SwiftUI.Color(hex: 0x1F1F24)
        static let accent          = SwiftUI.Color(hex: 0xE53935)

        static let textPrimary   = SwiftUI.Color(hex: 0xF5F5F7)
        static let textSecondary = SwiftUI.Color(hex: 0xA1A1AA)
        static let textTertiary  = SwiftUI.Color(hex: 0x6B6B73)

        static let openSlot = SwiftUI.Color(hex: 0x3A3A41)
        static let hourRule = SwiftUI.Color(hex: 0x383842)
        static let warning  = SwiftUI.Color(hex: 0xF5A623)
        static let success  = SwiftUI.Color(hex: 0x34C759)

        enum Category {
            static let gig     = SwiftUI.Color(hex: 0xE53935)
            static let travel  = SwiftUI.Color(hex: 0xF59E0A)
            static let food    = SwiftUI.Color(hex: 0x4CAF50)
            static let social  = SwiftUI.Color(hex: 0xED5999)
            static let work    = SwiftUI.Color(hex: 0x428AF5)
            static let explore = SwiftUI.Color(hex: 0x8C5CF5)
            static let rest    = SwiftUI.Color(hex: 0x738C99)
            static let admin   = SwiftUI.Color(hex: 0x9E9E9E)

            static func onSurface(_ category: BlockCategory) -> SwiftUI.Color {
                switch category {
                case .gig:     return SwiftUI.Color(hex: 0xFF6B66) // ~6.2:1
                case .explore: return SwiftUI.Color(hex: 0xA98AF7) // ~6.3:1
                case .travel:  return travel
                case .food:    return food
                case .social:  return social
                case .work:    return work
                case .rest:    return rest
                case .admin:   return admin
                }
            }

            static func color(for category: BlockCategory) -> SwiftUI.Color {
                switch category {
                case .gig:     return gig
                case .travel:  return travel
                case .food:    return food
                case .social:  return social
                case .work:    return work
                case .explore: return explore
                case .rest:    return rest
                case .admin:   return admin
                }
            }
        }
    }

    // MARK: - Typography

    enum Font {
        static let displayCountdown = SwiftUI.Font.system(.largeTitle, design: .rounded).weight(.heavy).monospacedDigit()
        static let titleLarge       = SwiftUI.Font.system(.title,      design: .rounded).weight(.heavy)
        static let title            = SwiftUI.Font.system(.headline,   design: .rounded).weight(.bold)
        static let body             = SwiftUI.Font.system(.body,       design: .rounded).weight(.medium)
        static let caption          = SwiftUI.Font.system(.caption,    design: .rounded).weight(.medium).monospacedDigit()
        static let codeHuge         = SwiftUI.Font.system(.largeTitle, design: .monospaced).weight(.bold)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xs:  CGFloat = 4
        static let s:   CGFloat = 8
        static let m:   CGFloat = 12
        static let l:   CGFloat = 16
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Shape

    enum Radius {
        static let small:  CGFloat = 8
        static let medium: CGFloat = 14
        static let large:  CGFloat = 22
    }

    enum Stroke {
        static let openSlotDashWidth: CGFloat = 1.5
        static let openSlotDashPattern: [CGFloat] = [6, 5]
        static let currentBlockBorder: CGFloat = 2
    }

    enum Opacity {
        static let pastBlock: Double = 0.4
        static let pressed:   Double = 0.97
    }

    enum Size {
        static let minTapTarget:        CGFloat = 44
        static let categoryStripeWidth: CGFloat = 4
    }
}

// MARK: - Stage-1 Backwards-Compatibility Shims
//
// Existing widget views still reference the old flat Theme API. Stage 2
// refactors every view to use the nested namespaces; these shims must
// be deleted then.

extension Theme {
    static let accent          = Color.accent
    static let background      = Color.background
    static let surface         = Color.surface
    static let surfaceElevated = Color.surfaceElevated
    static let textPrimary     = Color.textPrimary
    static let textSecondary   = Color.textSecondary
    static let textMuted       = Color.textTertiary
    static let openBorder      = Color.openSlot
    static let hourRule        = Color.hourRule
}

// MARK: - Hex Color Helper (private to this file)

private extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
