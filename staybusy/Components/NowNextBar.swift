//
//  NowNextBar.swift
//  staybusy
//
//  Pinned bar showing what's happening now, what's next, or — when
//  no blocks remain today — the first block of tomorrow. The bar
//  never shows an empty state: every variant communicates a real
//  status the user can act on.
//
//  When the next block has a fixed location and Location Services are
//  authorized, the "starts in" countdown is replaced with a **leave
//  in** countdown that subtracts the current driving ETA + a small
//  buffer — so the prompt reflects when you actually need to head out,
//  not when the next event begins.
//

import SwiftUI
import CoreLocation

struct NowNextBar: View {
    let allBlocks: [Block]

    @State private var leaveBy = LeaveByModel()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let phase = Phase(now: ctx.date, blocks: allBlocks)
            content(state: phase, now: ctx.date)
        }
        .padding(Theme.Spacing.m)
        .background(Theme.Color.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .accessibilityElement(children: .contain)
        // Re-target the leave-by tracker whenever the routeable next
        // block changes (different ID, new arrive-by time, or it goes
        // away entirely). Driving from `.task(id:)` keeps location
        // requests out of the per-second TimelineView re-render.
        .task(id: routeableTargetSignature) {
            syncLeaveBy()
        }
    }

    // MARK: - Routing target

    /// The next block we'd want to compute a leave-by for. We only
    /// consider blocks today that still lie in the future and have a
    /// real lat/lng — otherwise there's nothing to navigate to.
    private var routeableNext: Block? {
        let now = Date()
        let cal = Calendar.current
        return allBlocks
            .filter {
                $0.start > now
                    && cal.isDate($0.start, inSameDayAs: now)
                    && $0.latitude != nil
                    && $0.longitude != nil
            }
            .sorted { $0.start < $1.start }
            .first
    }

    /// A signature for `.task(id:)`. Combines the block identity with
    /// its start time, so editing the block's start time triggers a
    /// retarget while incidental re-renders do not.
    private var routeableTargetSignature: String? {
        guard let block = routeableNext,
              let lat = block.latitude,
              let lng = block.longitude
        else { return nil }
        return "\(block.persistentModelID.hashValue)-\(block.start.timeIntervalSince1970)-\(lat)-\(lng)"
    }

    private func syncLeaveBy() {
        if let block = routeableNext,
           let lat = block.latitude,
           let lng = block.longitude {
            leaveBy.retarget(
                target: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                arriveBy: block.start
            )
        } else {
            leaveBy.clear()
        }
    }

    @ViewBuilder
    private func content(state: Phase, now: Date) -> some View {
        switch state {
        case .current(let current, let next):
            CurrentState(
                now: now,
                current: current,
                next: next,
                leaveByState: leaveByStateForNextIfRouteable(next)
            )
        case .between(let next):
            BetweenState(
                now: now,
                next: next,
                leaveByState: leaveByStateForNextIfRouteable(next)
            )
        case .doneToday(let tomorrow):
            DoneState(tomorrowFirst: tomorrow)
        case .nothing:
            DoneState(tomorrowFirst: nil)
        }
    }

    /// Only surface the leave-by state when the next block we'd route
    /// to is actually the block the bar is talking about — otherwise
    /// the countdown would describe a different destination.
    private func leaveByStateForNextIfRouteable(_ next: Block?) -> LeaveByModel.State? {
        guard let next else { return nil }
        guard let target = routeableNext,
              target.persistentModelID == next.persistentModelID
        else { return nil }
        return leaveBy.state
    }

    // MARK: - Phase

    private enum Phase {
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
        let leaveByState: LeaveByModel.State?

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
                    NextLine(
                        label: "NEXT",
                        next: next,
                        leaveByState: leaveByState,
                        now: now
                    )
                }
            }
            .accessibilityLabel("Now: \(current.title). Ends in \(spokenCountdown(to: current.end, from: now)).")
        }
    }

    private struct BetweenState: View {
        let now: Date
        let next: Block
        let leaveByState: LeaveByModel.State?

        private var leaveBy: Date? {
            if case .ready(let leaveBy, _) = leaveByState {
                return leaveBy
            }
            return nil
        }

        private var useLeaveBy: Bool {
            // Only surface the leave-by countdown when it's strictly
            // earlier than the start — otherwise it just says the same
            // thing twice. (E.g. when you're already at the venue.)
            guard let leaveBy else { return false }
            return leaveBy < next.start
        }

        private var primaryTarget: Date {
            useLeaveBy ? leaveBy! : next.start
        }

        private var trailingLabel: String {
            useLeaveBy ? "LEAVE IN" : "STARTS IN"
        }

        var body: some View {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                PrimaryRow(
                    color: Theme.Color.textTertiary,
                    onSurfaceColor: Theme.Color.textTertiary,
                    symbol: "clock",
                    eyebrow: "FREE UNTIL",
                    title: next.title,
                    trailingLabel: trailingLabel,
                    trailing: countdown(from: now, to: primaryTarget),
                    trailingColor: leaveByColor
                )
                Divider().background(Theme.Color.textTertiary.opacity(0.25))
                NextLine(
                    label: "NEXT",
                    next: next,
                    leaveByState: leaveByState,
                    now: now
                )
            }
            .accessibilityLabel(accessibilityLabel)
        }

        private var leaveByColor: Color {
            guard useLeaveBy, let leaveBy else { return Theme.Color.accent }
            // Inside the last 5 min before leave time, escalate to warning
            // so a glance is enough to register "go now".
            if leaveBy.timeIntervalSince(now) < 5 * 60 {
                return Theme.Color.warning
            }
            return Theme.Color.accent
        }

        private var accessibilityLabel: String {
            if useLeaveBy {
                return "Free until \(next.title). Leave in \(spokenCountdown(to: primaryTarget, from: now)) to arrive on time."
            }
            return "Free until \(next.title). Starts in \(spokenCountdown(to: next.start, from: now))."
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
        let leaveByState: LeaveByModel.State?
        let now: Date

        private var leaveByLabel: String? {
            switch leaveByState {
            case .ready(let leaveBy, _) where leaveBy < next.start:
                let mins = max(0, Int(leaveBy.timeIntervalSince(now) / 60))
                if mins <= 0 { return "leave now" }
                if mins < 60 { return "leave in \(mins)m" }
                let h = mins / 60
                let m = mins % 60
                return m > 0 ? "leave in \(h)h \(m)m" : "leave in \(h)h"
            default:
                return nil
            }
        }

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
                if let leaveByLabel {
                    Text(leaveByLabel)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.accent)
                } else {
                    Text(formatTime(next.start))
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
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
