//
//  OpenSlotCard.swift
//  staybusy
//
//  Dashed-border card representing free time in the timeline.
//  Visually distinct from a real block (no category stripe, no fill)
//  so a glance can't confuse "open" with "scheduled".
//

import SwiftUI

struct OpenSlotCard: View {
    let start: Date
    let end: Date
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.s) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("OPEN — \(durationString)")
                        .font(Theme.Font.body)
                        .tracking(0.8)
                        .foregroundStyle(Theme.Color.textTertiary)
                    TimeRangeLabel(start: start, end: end)
                }
                Spacer(minLength: Theme.Spacing.s)
                Image(systemName: "plus.circle")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textTertiary)
            }
            .padding(.vertical, Theme.Spacing.m)
            .padding(.horizontal, Theme.Spacing.m)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .strokeBorder(
                        Theme.Color.openSlot,
                        style: StrokeStyle(
                            lineWidth: Theme.Stroke.openSlotDashWidth,
                            dash: Theme.Stroke.openSlotDashPattern
                        )
                    )
            )
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Open time, \(accessibleDuration)")
        .accessibilityHint("Double tap to fill")
    }

    private var durationString: String {
        let total = Int(end.timeIntervalSince(start) / 60)
        let h = total / 60
        let m = total % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private var accessibleDuration: String {
        let total = Int(end.timeIntervalSince(start) / 60)
        let h = total / 60
        let m = total % 60
        var parts: [String] = []
        if h > 0 { parts.append("\(h) hour\(h == 1 ? "" : "s")") }
        if m > 0 { parts.append("\(m) minute\(m == 1 ? "" : "s")") }
        return parts.joined(separator: " ")
    }
}
