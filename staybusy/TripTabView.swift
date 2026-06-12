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

    var body: some View {
        let summary = TripSummary(blocks: allBlocks)
        ZStack {
            Theme.background.ignoresSafeArea()
            if summary.days.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        SummaryCard(summary: summary)
                        VStack(spacing: 10) {
                            ForEach(summary.days) { day in
                                Button {
                                    onSelectDay(day.date)
                                } label: {
                                    DayRow(day: day)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(16)
                }
                .scrollIndicators(.hidden)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "suitcase")
                .font(.system(size: 44, weight: .heavy))
                .foregroundStyle(Theme.textSecondary)
            Text("No trip scheduled")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Text("Add a block to start a trip")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
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
                // Tiebreak: earliest date wins.
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
        VStack(alignment: .leading, spacing: 14) {
            Text("TRIP OVERVIEW")
                .font(.system(.caption2, design: .rounded).weight(.heavy))
                .tracking(1.4)
                .foregroundStyle(Theme.textSecondary)
            HStack(alignment: .top, spacing: 28) {
                stat(value: "\(summary.totalBlocks)", label: "BLOCKS")
                stat(value: openHoursLabel, label: "OPEN")
                Spacer(minLength: 0)
            }
            if let thin = summary.thinnestDay {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("Thinnest day:")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Text(formatThinnest(thin.date))
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.accent)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 14))
    }

    private func stat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(.title, design: .rounded).weight(.heavy).monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
            Text(label)
                .font(.system(.caption2, design: .rounded).weight(.heavy))
                .tracking(1.2)
                .foregroundStyle(Theme.textSecondary)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(weekday)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(dateLabel)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Theme.textMuted)
            }
            DensityBar(day: day)
                .frame(height: 14)
            Text(countLine)
                .font(.system(.caption, design: .rounded).weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
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
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func color(for seg: Segment) -> Color {
        switch seg.kind {
        case .block(let cat): return cat.color
        case .open: return Theme.hourRule
        }
    }
}

#Preview {
    TripTabView(onSelectDay: { _ in })
        .modelContainer(for: Block.self, inMemory: true)
}
