//
//  NowNextBar.swift
//  staybusy
//
//  Pinned bar showing what's happening now, what's next, or — when
//  no blocks remain today — the first block of tomorrow. The bar
//  never shows an empty state: every variant communicates a real
//  status the user can act on.
//

import SwiftUI

struct NowNextBar: View {
    let allBlocks: [Block]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            content(now: ctx.date)
        }
        .padding(Theme.Spacing.m)
        .background(Theme.Color.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        switch State(now: now, blocks: allBlocks) {
        case .current(let current, let next):
            CurrentState(now: now, current: current, next: next)
        case .between(let next):
            BetweenState(now: now, next: next)
        case .doneToday(let tomorrow):
            DoneState(tomorrowFirst: tomorrow)
        case .nothing:
            DoneState(tomorrowFirst: nil)
        }
    }

    // MARK: - State

    private enum State {
        case current(Block, next: Block?)
        case between(Block)
        case doneToday(Block?)
        case nothing

        init(now: Date, blocks: [Block]) {
            let cal = Calendar.current
            if let current = blocks.first(where: { $0.start <= now && now < $0.end }) {
                let next = blocks
                    .filter { $0.start > now && cal.isDate($0.start, inSameDayAs: now) }
                    .sorted { $0.start < $1.start }
                    .first
                self = .current(current, next: next)
                return
            }
            let nextToday = blocks
                .filter { $0.start > now && cal.isDate($0.start, inSameDayAs: now) }
                .sorted { $0.start < $1.start }
                .first
            if let nextToday {
                self = .between(nextToday)
                return
            }
            let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now)) ?? now
            let firstTomorrow = blocks
                .filter { cal.isDate($0.start, inSameDayAs: tomorrow) }
                .sorted { $0.start < $1.start }
                .first
            if firstTomorrow != nil {
                self = .doneToday(firstTomorrow)
                return
            }
            // No blocks at all anywhere.
            self = blocks.isEmpty ? .nothing : .doneToday(nil)
        }
    }

    // MARK: - Sub-views

    private struct CurrentState: View {
        let now: Date
        let current: Block
        let next: Block?

        var body: some View {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                PrimaryRow(
                    color: current.category.color,
                    onSurfaceColor: current.category.textOnSurface,
                    symbol: current.category.symbol,
                    eyebrow: "NOW",
                    title: current.title,
                    trailingLabel: "ENDS IN",
                    trailing: countdown(from: now, to: current.end),
                    trailingColor: Theme.Color.textPrimary
                )
                if let next {
                    Divider().background(Theme.Color.textTertiary.opacity(0.25))
                    NextLine(label: "NEXT", next: next)
                }
            }
            .accessibilityLabel("Now: \(current.title). Ends in \(spokenCountdown(to: current.end, from: now)).")
        }
    }

    private struct BetweenState: View {
        let now: Date
        let next: Block

        var body: some View {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                PrimaryRow(
                    color: Theme.Color.textTertiary,
                    onSurfaceColor: Theme.Color.textTertiary,
                    symbol: "clock",
                    eyebrow: "FREE UNTIL",
                    title: next.title,
                    trailingLabel: "STARTS IN",
                    trailing: countdown(from: now, to: next.start),
                    trailingColor: Theme.Color.accent
                )
                Divider().background(Theme.Color.textTertiary.opacity(0.25))
                NextLine(label: "NEXT", next: next)
            }
            .accessibilityLabel("Free until \(next.title). Starts in \(spokenCountdown(to: next.start, from: now)).")
        }
    }

    private struct DoneState: View {
        let tomorrowFirst: Block?

        var body: some View {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.success)
                    Text("Done for today")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.textPrimary)
                }
                if let first = tomorrowFirst {
                    Divider().background(Theme.Color.textTertiary.opacity(0.25))
                    HStack(spacing: Theme.Spacing.s) {
                        Circle()
                            .fill(first.category.color)
                            .frame(width: 8, height: 8)
                        Image(systemName: first.category.symbol)
                            .font(Theme.Font.caption)
                            .foregroundStyle(first.category.textOnSurface)
                        Text("TOMORROW")
                            .font(Theme.Font.caption)
                            .tracking(1.3)
                            .foregroundStyle(Theme.Color.textSecondary)
                        Text(first.title)
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.textPrimary)
                            .lineLimit(1)
                        Spacer(minLength: Theme.Spacing.s)
                        Text(formatTime(first.start))
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                } else {
                    Text("Nothing scheduled yet")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            .accessibilityLabel(tomorrowFirst.map { "Done for today. Tomorrow's first block: \($0.title)." } ?? "Done for today. Nothing scheduled yet.")
        }
    }

    private struct PrimaryRow: View {
        let color: Color
        let onSurfaceColor: Color
        let symbol: String
        let eyebrow: String
        let title: String
        let trailingLabel: String
        let trailing: String
        let trailingColor: Color

        var body: some View {
            HStack(alignment: .center, spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.small)
                        .fill(color.opacity(0.18))
                        .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                    Image(systemName: symbol)
                        .font(Theme.Font.title)
                        .foregroundStyle(onSurfaceColor)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(eyebrow)
                        .font(Theme.Font.caption)
                        .tracking(1.5)
                        .foregroundStyle(Theme.Color.textSecondary)
                    Text(title)
                        .font(Theme.Font.titleLarge)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: Theme.Spacing.s)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(trailingLabel)
                        .font(Theme.Font.caption)
                        .tracking(1.5)
                        .foregroundStyle(Theme.Color.textSecondary)
                    Text(trailing)
                        .font(Theme.Font.displayCountdown)
                        .foregroundStyle(trailingColor)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
        }
    }

    private struct NextLine: View {
        let label: String
        let next: Block

        var body: some View {
            HStack(spacing: Theme.Spacing.s) {
                Circle()
                    .fill(next.category.color)
                    .frame(width: 8, height: 8)
                Image(systemName: next.category.symbol)
                    .font(Theme.Font.caption)
                    .foregroundStyle(next.category.textOnSurface)
                Text(label)
                    .font(Theme.Font.caption)
                    .tracking(1.5)
                    .foregroundStyle(Theme.Color.textSecondary)
                Text(next.title)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: Theme.Spacing.s)
                Text(formatTime(next.start))
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
    }
}

// MARK: - Helpers (file-private)

private func countdown(from: Date, to: Date) -> String {
    let total = max(0, Int(to.timeIntervalSince(from)))
    let h = total / 3600
    let m = (total % 3600) / 60
    let s = total % 60
    if h > 0 { return String(format: "%dh %02dm", h, m) }
    return String(format: "%dm %02ds", m, s)
}

private func spokenCountdown(to date: Date, from now: Date) -> String {
    let total = max(0, Int(date.timeIntervalSince(now)))
    let h = total / 3600
    let m = (total % 3600) / 60
    if h > 0 && m > 0 { return "\(h) hours \(m) minutes" }
    if h > 0 { return "\(h) hours" }
    return "\(m) minutes"
}

private func formatTime(_ d: Date) -> String {
    let f = DateFormatter()
    f.dateFormat = "h:mm a"
    return f.string(from: d)
}
