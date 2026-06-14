//
//  TimeRangeLabel.swift
//  staybusy
//
//  Monospaced-digit time range used wherever start–end is displayed.
//  Routes through Theme.Font.caption so digits don't jitter.
//

import SwiftUI

struct TimeRangeLabel: View {
    let start: Date
    let end: Date
    var style: Style = .caption

    enum Style {
        case caption
        case title
    }

    var body: some View {
        Text(formatted)
            .font(font)
            .foregroundStyle(Theme.Color.textSecondary)
            .accessibilityLabel(accessibilityText)
    }

    private var font: Font {
        switch style {
        case .caption: return Theme.Font.caption
        case .title:   return Theme.Font.title
        }
    }

    private var formatted: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }

    private var accessibilityText: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return "\(f.string(from: start)) to \(f.string(from: end))"
    }
}
