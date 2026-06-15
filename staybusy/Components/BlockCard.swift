//
//  BlockCard.swift
//  staybusy
//
//  Single block card with three layout variants and orthogonal states.
//  Variants control how dense the card is (timeline = full timeline cell,
//  compact = map bottom sheet / trip overview row, list = minimal).
//  States are flags that can compose: a block can be both `past` and
//  carry an `hasOverlap` warning at the same time.
//

import SwiftUI

struct BlockCard: View {
    let block: Block
    var variant: Variant = .timeline
    var isCurrent: Bool = false
    var isPast: Bool = false
    var hasOverlap: Bool = false

    enum Variant {
        case timeline
        case compact
        case list
    }

    var body: some View {
        content
            .background(background)
            .overlay {
                if isCurrent {
                    RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        .stroke(Theme.Color.accent, lineWidth: Theme.Stroke.currentBlockBorder)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .opacity(isPast ? Theme.Opacity.pastBlock : 1.0)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Layout

    private var content: some View {
        HStack(spacing: 0) {
            categoryStripe
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                headerRow
                titleText
                if variant != .list {
                    metaRow
                }
                if variant == .timeline && hasDetailFlags {
                    detailFlagsRow
                }
            }
            .padding(.vertical, variant == .list ? Theme.Spacing.s : Theme.Spacing.m)
            .padding(.horizontal, Theme.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var categoryStripe: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(block.category.color)
            .frame(width: Theme.Size.categoryStripeWidth)
            .padding(.vertical, Theme.Spacing.xs)
    }

    private var headerRow: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: block.category.symbol)
                .font(Theme.Font.caption)
                .foregroundStyle(block.category.textOnSurface)
            Text(block.category.label.uppercased())
                .font(Theme.Font.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.Color.textSecondary)
            if block.isFromCalendar {
                Image(systemName: "calendar")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textTertiary)
                    .accessibilityLabel("From Calendar")
            }
            Spacer(minLength: Theme.Spacing.xs)
            if isCurrent {
                Text("NOW")
                    .font(Theme.Font.caption)
                    .tracking(1.2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Theme.Spacing.s)
                    .padding(.vertical, 2)
                    .background(Theme.Color.accent, in: Capsule())
                    .accessibilityHidden(true)
            }
            if hasOverlap {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.warning)
                    .accessibilityHidden(true)
            }
        }
    }

    private var titleText: some View {
        Text(block.title)
            .font(Theme.Font.title)
            .foregroundStyle(Theme.Color.textPrimary)
            .lineLimit(variant == .list ? 1 : 2)
    }

    private var metaRow: some View {
        HStack(spacing: Theme.Spacing.xs) {
            TimeRangeLabel(start: block.start, end: block.end)
            if !block.locationName.isEmpty {
                Text("·")
                    .foregroundStyle(Theme.Color.textTertiary)
                Text(block.locationName)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    private var ticketCount: Int { block.orderedTickets.count }

    private var hasDetailFlags: Bool {
        ticketCount > 0
            || !block.confirmationCode.isEmpty
            || !block.attachmentFilenames.isEmpty
            || !block.notes.isEmpty
            || !block.links.isEmpty
    }

    private var detailFlagsRow: some View {
        HStack(spacing: Theme.Spacing.xs) {
            if ticketCount > 0 {
                flagPill(
                    symbol: "ticket.fill",
                    label: ticketCount > 1 ? "\(ticketCount) tickets" : "Ticket"
                )
            } else if !block.confirmationCode.isEmpty {
                flagPill(symbol: "ticket.fill", label: "Code")
            }
            if !block.attachmentFilenames.isEmpty {
                flagPill(
                    symbol: "paperclip",
                    label: "\(block.attachmentFilenames.count)"
                )
            }
            if !block.notes.isEmpty {
                flagPill(symbol: "note.text", label: "Notes")
            }
            if !block.links.isEmpty {
                flagPill(symbol: "link", label: "\(block.links.count)")
            }
        }
        .padding(.top, 2)
    }

    private func flagPill(symbol: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(label)
        }
        .font(Theme.Font.caption)
        .foregroundStyle(Theme.Color.textSecondary)
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, 3)
        .background(
            Theme.Color.surfaceElevated,
            in: Capsule()
        )
    }

    private var background: some View {
        Group {
            switch variant {
            case .timeline, .list:
                Theme.Color.surface
            case .compact:
                Theme.Color.surfaceElevated
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        var parts = [
            block.title,
            block.category.label,
            "\(timeFormatter.string(from: block.start)) to \(timeFormatter.string(from: block.end))"
        ]
        if !block.locationName.isEmpty { parts.append(block.locationName) }
        if isCurrent { parts.insert("Currently happening", at: 0) }
        if isPast { parts.append("Past") }
        if hasOverlap { parts.append("Overlaps with another block") }
        return parts.joined(separator: ", ")
    }
}

#Preview("BlockCard variants") {
    let sample = Block(
        title: "Soundcheck",
        start: Date().addingTimeInterval(-1800),
        end: Date().addingTimeInterval(3600),
        category: .gig,
        locationName: "Brooklyn Steel",
        confirmationCode: "BS-44721",
        notes: "Backline ready."
    )
    let ticket = Ticket(name: "Crew pass", confirmationCode: "BS-44721")
    sample.tickets = [ticket]

    return VStack(spacing: Theme.Spacing.l) {
        BlockCard(block: sample, variant: .timeline, isCurrent: true)
            .frame(height: 140)
        BlockCard(block: sample, variant: .compact)
            .frame(height: 80)
        BlockCard(block: sample, variant: .list)
            .frame(height: 64)
    }
    .padding(Theme.Spacing.l)
    .background(Theme.Color.background)
    .preferredColorScheme(.dark)
}
