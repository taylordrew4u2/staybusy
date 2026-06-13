//
//  TripTabView.swift
//  staybusy
//

import SwiftUI
import SwiftData

// MARK: - Root

struct TripTabView: View {
    @Query(sort: \Block.start, order: .forward) private var allBlocks: [Block]
    let onSelectDay: (Date) -> Void

    @State private var presentedSheet: EditorSheet?

    var body: some View {
        let summary = TripSummary(blocks: allBlocks)
        ZStack {
            Theme.Color.background.ignoresSafeArea()
            if summary.days.isEmpty {
                EmptyStateView(
                    symbol: "suitcase",
                    title: "No trip scheduled",
                    message: "Add a block to start mapping out your trip.",
                    actionTitle: "Add a block",
                    action: { presentedSheet = .create(suggestedInterval()) }
                )
            } else {
                ScrollView {
                    VStack(spacing: Theme.Spacing.m) {
                        SummaryCard(summary: summary)
                        VStack(spacing: Theme.Spacing.s) {
                            ForEach(summary.days) { day in
                                Button {
                                    onSelectDay(day.date)
                                } label: {
                                    DayRow(day: day)
                                }
                                .buttonStyle(.pressable)
                                .accessibilityLabel(dayAccessibility(day))
                                .accessibilityHint("Double tap to view that day's timeline")
                            }
                        }
                    }
                    .padding(Theme.Spacing.l)
                }
                .scrollIndicators(.hidden)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .create(let interval):
                BlockEditorView(editing: nil, suggested: interval)
            case .edit(let block):
                BlockEditorView(editing: block, suggested: nil)
            }
        }
    }

    private func suggestedInterval() -> DateInterval {
        DateInterval(start: Date(), duration: 3600)
    }

    private func dayAccessibility(_ day: DaySummary) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        let blockCount = day.blocks.count
        return "\(f.string(from: day.date)). \(blockCount) \(blockCount == 1 ? "block" : "blocks")."
    }
}

// MARK: - Summary model

struct DaySummary: Identifiable {
    let date: Date
    let blocks: [Block]

    var id: Date { date }

    static let windowStartHour = 7
    static let windowEndHour = 24

    var dayStart: Date {
        Calendar.current.date(bySettingHour: Self.windowStartHour, minute: 0, second: 0, of: date)
            ?? Calendar.current.startOfDay(for: date)
    }

    var dayEnd: Date {
        let next = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        return Calendar.current.startOfDay(for: next)
    }

    var windowMinutes: Double {
        dayEnd.timeIntervalSince(dayStart) / 60.0
    }

    var scheduledMinutesInWindow: Double {
        blocks.reduce(0.0) { sum, b in
            let s = max(b.start, dayStart)
            let e = min(b.end, dayEnd)
            return sum + max(0, e.timeIntervalSince(s) / 60.0)
        }
    }

    var openMinutes: Double {
        max(0, windowMinutes - scheduledMinutesInWindow)
    }
}

private struct TripSummary {
    let days: [DaySummary]
    let totalBlocks: Int
    let totalOpenMinutes: Double
    let thinnestDay: DaySummary?

    init(blocks: [Block]) {
        let cal = Calendar.current
        guard let firstStart = blocks.map(\.start).min(),
              let lastEnd = blocks.map(\.end).max() else {
            self.days = []
            self.totalBlocks = 0
            self.totalOpenMinutes = 0
            self.thinnestDay = nil
            return
        }

        let first = cal.startOfDay(for: firstStart)
        let last = cal.startOfDay(for: lastEnd)

        var built: [DaySummary] = []
        var cursor = first
        while cursor <= last {
            let dayStart = cursor
            let dayEnd = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor
            let blocksThisDay = blocks
                .filter { $0.start < dayEnd && $0.end > dayStart }
                .sorted { $0.start < $1.start }
            built.append(DaySummary(date: dayStart, blocks: blocksThisDay))
            cursor = dayEnd
        }

        self.days = built
        self.totalBlocks = built.reduce(0) { $0 + $1.blocks.count }
        self.totalOpenMinutes = built.reduce(0) { $0 + $1.openMinutes }

        // Only call out a thinnest day when there's more than one to compare.
        if built.count > 1 {
            self.thinnestDay = built.max(by: { lhs, rhs in
                if lhs.openMinutes != rhs.openMinutes {
                    return lhs.openMinutes < rhs.openMinutes
                }
                return lhs.date > rhs.date
            })
        } else {
            self.thinnestDay = nil
        }
    }
}

// MARK: - Summary card

private struct SummaryCard: View {
    let summary: TripSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("TRIP OVERVIEW")
                .font(Theme.Font.caption)
                .tracking(1.4)
                .foregroundStyle(Theme.Color.textSecondary)
            HStack(alignment: .top, spacing: Theme.Spacing.xl) {
                stat(value: "\(summary.totalBlocks)", label: "BLOCKS")
                stat(value: openHoursLabel, label: "OPEN")
                Spacer(minLength: 0)
            }
            if let thin = summary.thinnestDay {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                    Text("Thinnest day:")
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                    Text(formatThinnest(thin.date))
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.l)
        .background(Theme.Color.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(Theme.Font.titleLarge.monospacedDigit())
                .foregroundStyle(Theme.Color.textPrimary)
            Text(label)
                .font(Theme.Font.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.Color.textSecondary)
        }
    }

    private var openHoursLabel: String {
        let total = Int(summary.totalOpenMinutes.rounded())
        let h = total / 60
        let m = total % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private func formatThinnest(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f.string(from: date)
    }
}

// MARK: - Day row

private struct DayRow: View {
    let day: DaySummary

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                Text(weekday)
                    .font(Theme.Font.titleLarge)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text(dateLabel)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textTertiary)
            }
            DensityBar(day: day)
                .frame(height: 14)
            Text(countLine)
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .padding(Theme.Spacing.m)
        .frame(minHeight: Theme.Size.minTapTarget)
        .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    private var weekday: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: day.date)
    }

    private var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: day.date)
    }

    private var countLine: String {
        let count = day.blocks.count
        let blocksWord = count == 1 ? "block" : "blocks"
        return "\(count) \(blocksWord) · \(formatOpen(day.openMinutes)) open"
    }

    private func formatOpen(_ minutes: Double) -> String {
        let total = Int(minutes.rounded())
        let h = total / 60
        let m = total % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

// MARK: - Density bar

private struct DensityBar: View {
    let day: DaySummary

    private struct Segment: Identifiable {
        enum Kind { case block(BlockCategory), open }
        let id: Int
        let kind: Kind
        let widthFraction: Double
    }

    private var segments: [Segment] {
        var out: [Segment] = []
        var idx = 0
        var cursor = day.dayStart

        for b in day.blocks.sorted(by: { $0.start < $1.start }) {
            let bs = max(b.start, day.dayStart)
            let be = min(b.end, day.dayEnd)
            if bs > cursor {
                let gap = bs.timeIntervalSince(cursor) / 60.0
                if gap > 0 {
                    out.append(Segment(id: idx, kind: .open, widthFraction: gap / day.windowMinutes))
                    idx += 1
                }
            }
            if be > bs {
                let dur = be.timeIntervalSince(bs) / 60.0
                out.append(Segment(id: idx, kind: .block(b.category), widthFraction: dur / day.windowMinutes))
                idx += 1
                cursor = be
            }
        }

        if day.dayEnd > cursor {
            let gap = day.dayEnd.timeIntervalSince(cursor) / 60.0
            if gap > 0 {
                out.append(Segment(id: idx, kind: .open, widthFraction: gap / day.windowMinutes))
            }
        }

        return out
    }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(segments) { seg in
                    Rectangle()
                        .fill(color(for: seg))
                        .frame(width: max(0, geo.size.width * seg.widthFraction))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.small / 2))
        .accessibilityHidden(true)
    }

    private func color(for seg: Segment) -> Color {
        switch seg.kind {
        case .block(let cat): return cat.color
        case .open: return Theme.Color.hourRule
        }
    }
}

#Preview {
    TripTabView(onSelectDay: { _ in })
        .modelContainer(for: Block.self, inMemory: true)
}
