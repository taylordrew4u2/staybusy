//
//  Theme.swift
//  staybusy
//
//  Single source of truth for every visual value in the app.
//  Mirrors the design-system token schema 1:1. If you need a value
//  not listed here, do not hardcode — add it to the schema first.
//
//  Two palettes ship: the original Dark theme and the Warm light
//  theme. Each Color is backed by `UIColor(dynamicProvider:)` so it
//  swaps based on trait collection — the active palette is driven by
//  `.preferredColorScheme(...)` (see ThemeMode and View.appTheme()).
//
//  Token schema (authoritative — keep this and the code below in sync):
//
//  {
//    "color": {
//      "background":      { "dark": "#0D0D0F", "warm": "#FEF9F5" },
//      "surface":         { "dark": "#17171A", "warm": "#FFFFFF" },
//      "surfaceElevated": { "dark": "#1F1F24", "warm": "#FFF8F3" },
//      "accent":          { "dark": "#E53935", "warm": "#FF6B35" },
//      "textPrimary":     { "dark": "#F5F5F7", "warm": "#2D1F1A" },
//      "textSecondary":   { "dark": "#A1A1AA", "warm": "#8B6F5F" },
//      "textTertiary":    { "dark": "#6B6B73", "warm": "#B8A395" },
//      "openSlot":        { "dark": "#3A3A41", "warm": "#E8D4C4" },
//      "hourRule":        { "dark": "#383842", "warm": "#EEE0D6" },
//      "warning":         { "dark": "#F5A623", "warm": "#CC7700" },
//      "success":         { "dark": "#34C759", "warm": "#3A7D2A" },
//      "category": {
//        "gig":     { "dark": "#E53935", "warm": "#FF6B35" },
//        "travel":  { "dark": "#F59E0A", "warm": "#FFA500" },
//        "food":    { "dark": "#4CAF50", "warm": "#FFD54F" },
//        "social":  { "dark": "#ED5999", "warm": "#FF8A65" },
//        "work":    { "dark": "#428AF5", "warm": "#FF9800" },
//        "explore": { "dark": "#8C5CF5", "warm": "#FFCA28" },
//        "rest":    { "dark": "#738C99", "warm": "#D4A574" },
//        "admin":   { "dark": "#9E9E9E", "warm": "#C9A88A" }
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
//    "size":    { "minTapTarget": 44, "categoryStripeWidth": 4 },
//    "motion": {
//      "snap":   { "type": "spring",    "response": 0.25, "dampingFraction": 0.85 },
//      "gentle": { "type": "easeInOut", "duration": 0.35 },
//      "reduceMotion": "both resolve to duration 0.01"
//    },
//    "haptics": { "blockSaved": "impactLight", "codeCopied": "notificationSuccess" }
//  }
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum Theme {

    // MARK: - Color

    enum Color {
        static let background      = SwiftUI.Color(darkHex: 0x0D0D0F, warmHex: 0xFEF9F5)
        static let surface         = SwiftUI.Color(darkHex: 0x17171A, warmHex: 0xFFFFFF)
        static let surfaceElevated = SwiftUI.Color(darkHex: 0x1F1F24, warmHex: 0xFFF8F3)
        static let accent          = SwiftUI.Color(darkHex: 0xE53935, warmHex: 0xFF6B35)

        static let textPrimary   = SwiftUI.Color(darkHex: 0xF5F5F7, warmHex: 0x2D1F1A)
        static let textSecondary = SwiftUI.Color(darkHex: 0xA1A1AA, warmHex: 0x8B6F5F)
        static let textTertiary  = SwiftUI.Color(darkHex: 0x6B6B73, warmHex: 0xB8A395)

        static let openSlot = SwiftUI.Color(darkHex: 0x3A3A41, warmHex: 0xE8D4C4)
        static let hourRule = SwiftUI.Color(darkHex: 0x383842, warmHex: 0xEEE0D6)
        static let warning  = SwiftUI.Color(darkHex: 0xF5A623, warmHex: 0xCC7700)
        static let success  = SwiftUI.Color(darkHex: 0x34C759, warmHex: 0x3A7D2A)

        /// Raw category colors. Use for stripes, fills, icons.
        /// For text on `surface`, prefer `Theme.Color.Category.onSurface(_:)`
        /// — several categories fail 4.5:1 contrast as raw values on the
        /// warm theme's white surface (and gig/explore fail on the dark
        /// surface) and get tuned text variants there.
        enum Category {
            static let gig     = SwiftUI.Color(darkHex: 0xE53935, warmHex: 0xFF6B35)
            static let travel  = SwiftUI.Color(darkHex: 0xF59E0A, warmHex: 0xFFA500)
            static let food    = SwiftUI.Color(darkHex: 0x4CAF50, warmHex: 0xFFD54F)
            static let social  = SwiftUI.Color(darkHex: 0xED5999, warmHex: 0xFF8A65)
            static let work    = SwiftUI.Color(darkHex: 0x428AF5, warmHex: 0xFF9800)
            static let explore = SwiftUI.Color(darkHex: 0x8C5CF5, warmHex: 0xFFCA28)
            static let rest    = SwiftUI.Color(darkHex: 0x738C99, warmHex: 0xD4A574)
            static let admin   = SwiftUI.Color(darkHex: 0x9E9E9E, warmHex: 0xC9A88A)

            /// Category color suitable for text on `Theme.Color.surface`.
            /// Dark theme lightens gig/explore (which fail 4.5:1 raw on
            /// the dark surface); warm theme darkens every category
            /// (raw warm hues fail on white).
            static func onSurface(_ category: BlockCategory) -> SwiftUI.Color {
                switch category {
                case .gig:     return SwiftUI.Color(darkHex: 0xFF6B66, warmHex: 0xC44000)
                case .travel:  return SwiftUI.Color(darkHex: 0xF59E0A, warmHex: 0x8B5E00)
                case .food:    return SwiftUI.Color(darkHex: 0x4CAF50, warmHex: 0x6B4800)
                case .social:  return SwiftUI.Color(darkHex: 0xED5999, warmHex: 0xB83800)
                case .work:    return SwiftUI.Color(darkHex: 0x428AF5, warmHex: 0x8B4C00)
                case .explore: return SwiftUI.Color(darkHex: 0xA98AF7, warmHex: 0x7B5200)
                case .rest:    return SwiftUI.Color(darkHex: 0x738C99, warmHex: 0x6B4020)
                case .admin:   return SwiftUI.Color(darkHex: 0x9E9E9E, warmHex: 0x5C3C2C)
                }
            }

            /// Raw category color (stripes, fills, icons).
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
    //
    // All styles are SF Rounded (.rounded design) and based on Dynamic
    // Type text styles, so the app scales with the system text-size
    // setting. `codeHuge` overrides design to monospaced for confirmation
    // codes.

    enum Font {
        static let displayCountdown = SwiftUI.Font.system(.largeTitle, design: .rounded).weight(.heavy).monospacedDigit()
        static let titleLarge       = SwiftUI.Font.system(.title,      design: .rounded).weight(.heavy)
        static let title            = SwiftUI.Font.system(.headline,   design: .rounded).weight(.bold)
        static let body             = SwiftUI.Font.system(.body,       design: .rounded).weight(.medium)
        static let caption          = SwiftUI.Font.system(.caption,    design: .rounded).weight(.medium).monospacedDigit()
        static let codeHuge         = SwiftUI.Font.system(.largeTitle, design: .monospaced).weight(.bold)
    }

    // MARK: - Spacing (4-pt scale)

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
        /// Dashed border for OPEN gap cards.
        static let openSlotDashWidth: CGFloat = 1.5
        static let openSlotDashPattern: [CGFloat] = [6, 5]
        /// Solid border for the current block treatment.
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

    // MARK: - Motion
    //
    // Only two animations exist. Pass the environment's
    // `accessibilityReduceMotion` value so both collapse to near-instant
    // when the system setting is on.

    enum Motion {
        static func snap(reduceMotion: Bool = false) -> Animation {
            reduceMotion
                ? .easeInOut(duration: 0.01)
                : .spring(response: 0.25, dampingFraction: 0.85)
        }

        static func gentle(reduceMotion: Bool = false) -> Animation {
            reduceMotion
                ? .easeInOut(duration: 0.01)
                : .easeInOut(duration: 0.35)
        }
    }

    // MARK: - Haptics

    enum Haptic {
        static func blockSaved() {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        }

        static func codeCopied() {
            #if canImport(UIKit)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            #endif
        }
    }
}

// MARK: - ThemeMode
//
// User-selectable palette. The active mode is persisted via @AppStorage
// and applied to the view tree via `.appTheme()`, which sets
// `.preferredColorScheme` — which in turn drives the trait collection
// that every `Theme.Color.*` reads.

enum ThemeMode: String, CaseIterable, Identifiable {
    case dark
    case warm

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dark: return "Dark"
        case .warm: return "Warm"
        }
    }

    var subtitle: String {
        switch self {
        case .dark: return "The original — calm, near-black canvas."
        case .warm: return "Friendly — warm off-white with coral accent."
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .dark: return .dark
        case .warm: return .light
        }
    }
}

extension View {
    /// Applies the user-selected theme palette to this view subtree by
    /// driving `.preferredColorScheme`. Use this at the root of any view
    /// that creates an independent presentation context (the app root and
    /// every sheet) so the trait collection — and therefore every
    /// `Theme.Color.*` lookup — picks up the active palette.
    func appTheme() -> some View {
        modifier(AppThemeModifier())
    }
}

private struct AppThemeModifier: ViewModifier {
    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.dark.rawValue

    func body(content: Content) -> some View {
        let mode = ThemeMode(rawValue: themeModeRaw) ?? .dark
        content.preferredColorScheme(mode.colorScheme)
    }
}

// MARK: - Hex Color Helpers (private to this file)

private extension Color {
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >>  8) & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    /// Trait-collection-aware color: returns `warmHex` under `.light` and
    /// `darkHex` under `.dark`. The active palette is selected by the
    /// `ThemeMode`-driven `.preferredColorScheme` at the root of the
    /// view tree.
    init(darkHex: UInt32, warmHex: UInt32) {
        #if canImport(UIKit)
        self = Color(UIColor { trait in
            trait.userInterfaceStyle == .light
                ? UIColor(hex: warmHex)
                : UIColor(hex: darkHex)
        })
        #else
        self.init(hex: darkHex)
        #endif
    }
}

#if canImport(UIKit)
private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1.0) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >>  8) & 0xFF) / 255.0
        let b = CGFloat( hex        & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
#endif
