//
//  TodayView.swift
//  staybusy
//

import SwiftUI
import SwiftData

// MARK: - Root

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Block.start, order: .forward) private var allBlocks: [Block]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var navigationPath = NavigationPath()
    @State private var presentedSheet: EditorSheet?

    private var blocksForSelectedDay: [Block] {
        let cal = Calendar.current
        return allBlocks.filter { cal.isDate($0.start, inSameDayAs: selectedDate) }
    }

    private var overlappingIDs: Set<PersistentIdentifier> {
        let sorted = blocksForSelectedDay.sorted { $0.start < $1.start }
        var result: Set<PersistentIdentifier> = []
        for i in 0..<sorted.count {
            for j in (i + 1)..<sorted.count {
                if sorted[j].start >= sorted[i].end { break }
                result.insert(sorted[i].persistentModelID)
                result.insert(sorted[j].persistentModelID)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottomTrailing) {
                Theme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    DayPickerBar(selectedDate: $selectedDate)
                    NowNextBar(allBlocks: allBlocks)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    TimelineScroll(
                        date: selectedDate,
                        blocks: blocksForSelectedDay,
                        overlappingIDs: overlappingIDs,
                        onTapOpen: { interval in
                            presentedSheet = .create(interval)
                        },
                        onTapBlock: { block in
                            navigationPath.append(block)
                        }
                    )
                }

                FloatingAddButton {
                    let start = suggestedStartForCreate()
                    presentedSheet = .create(DateInterval(start: start, duration: 3600))
                }
                .padding(20)
            }
            .navigationDestination(for: Block.self) { block in
                BlockDetailView(block: block) {
                    presentedSheet = .edit(block)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .create(let interval):
                BlockEditorView(editing: nil, suggested: interval)
            case .edit(let block):
                BlockEditorView(editing: block, suggested: nil) {
                    navigationPath = NavigationPath()
                }
            }
        }
        .onAppear {
            LiveActivityManager.shared.sync(blocks: allBlocks)
        }
        .onChange(of: allBlocks) { _, new in
            LiveActivityManager.shared.sync(blocks: new)
        }
    }

    private func suggestedStartForCreate() -> Date {
        let cal = Calendar.current
        let viewed = selectedDate
        let dayEnd = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: viewed)) ?? viewed

        let base: Date
        if let lastEnd = blocksForSelectedDay.map(\.end).max(), lastEnd < dayEnd {
            base = lastEnd
        } else if cal.isDateInToday(viewed) {
            base = Date()
        } else {
            base = cal.date(bySettingHour: 9, minute: 0, second: 0, of: viewed) ?? viewed
        }
        return roundUpToFive(base)
    }

    private func roundUpToFive(_ date: Date) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let minute = comps.minute ?? 0
        comps.minute = ((minute + 4) / 5) * 5
        comps.second = 0
        return cal.date(from: comps) ?? date
    }
}

// MARK: - Sheet model

enum EditorSheet: Identifiable {
    case create(DateInterval?)
    case edit(Block)

    var id: String {
        switch self {
        case .create(let i):
            let s = i?.start.timeIntervalSinceReferenceDate ?? 0
            let e = i?.end.timeIntervalSinceReferenceDate ?? 0
            return "create-\(s)-\(e)"
        case .edit(let b):
            return "edit-\(b.persistentModelID.hashValue)"
        }
    }
}

// MARK: - Now / Next pinned bar

private struct NowNextBar: View {
    let allBlocks: [Block]

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let now = ctx.date
            let current = allBlocks.first { $0.start <= now && now < $0.end }
            let next = allBlocks
                .filter { $0.start > now }
                .sorted { $0.start < $1.start }
                .first
            content(now: now, current: current, next: next)
                .task(id: snapshotKey(current: current, next: next)) {
                    LiveActivityManager.shared.sync(blocks: allBlocks)
                }
        }
        .padding(14)
        .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 16))
    }

    private func snapshotKey(current: Block?, next: Block?) -> String {
        let c = current.map {
            "\($0.persistentModelID.hashValue):\($0.title):\(Int($0.end.timeIntervalSince1970))"
        } ?? "nil"
        let n = next.map {
            "\($0.persistentModelID.hashValue):\($0.title):\(Int($0.start.timeIntervalSince1970))"
        } ?? "nil"
        return "\(c)|\(n)"
    }

    @ViewBuilder
    private func content(now: Date, current: Block?, next: Block?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let current {
                primaryRow(
                    color: current.category.color,
                    symbol: current.category.symbol,
                    eyebrow: "NOW",
                    title: current.title,
                    trailingLabel: "ENDS IN",
                    trailing: countdown(from: now, to: current.end),
                    trailingColor: Theme.textPrimary
                )
                if let next {
                    Divider().background(Theme.textMuted.opacity(0.25))
                    nextRow(next: next)
                }
            } else if let next {
                primaryRow(
                    color: Theme.textMuted,
                    symbol: "clock",
                    eyebrow: "FREE UNTIL",
                    title: next.title,
                    trailingLabel: "STARTS IN",
                    trailing: countdown(from: now, to: next.start),
                    trailingColor: Theme.accent
                )
                Divider().background(Theme.textMuted.opacity(0.25))
                HStack(spacing: 8) {
                    Circle().fill(next.category.color).frame(width: 8, height: 8)
                    Text(next.category.label.uppercased())
                        .font(.system(.caption2, design: .rounded).weight(.heavy))
                        .tracking(1.3)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(formatTime(next.start))
                        .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 22, weight: .heavy))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Nothing scheduled")
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }

    private func primaryRow(
        color: Color,
        symbol: String,
        eyebrow: String,
        title: String,
        trailingLabel: String,
        trailing: String,
        trailingColor: Color
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: symbol)
                    .font(.system(size: 19, weight: .heavy))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow)
                    .font(.system(.caption2, design: .rounded).weight(.heavy))
                    .tracking(1.5)
                    .foregroundStyle(Theme.textSecondary)
                Text(title)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(trailingLabel)
                    .font(.system(.caption2, design: .rounded).weight(.heavy))
                    .tracking(1.5)
                    .foregroundStyle(Theme.textSecondary)
                Text(trailing)
                    .font(.system(.title3, design: .rounded).weight(.heavy).monospacedDigit())
                    .foregroundStyle(trailingColor)
            }
        }
    }

    private func nextRow(next: Block) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(next.category.color)
                .frame(width: 8, height: 8)
            Text("NEXT")
                .font(.system(.caption2, design: .rounded).weight(.heavy))
                .tracking(1.5)
                .foregroundStyle(Theme.textSecondary)
            Text(next.title)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 8)
            Text(formatTime(next.start))
                .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func countdown(from: Date, to: Date) -> String {
        let total = max(0, Int(to.timeIntervalSince(from)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%dh %02dm", h, m)
        } else {
            return String(format: "%dm %02ds", m, s)
        }
    }

    private func formatTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: d)
    }
}

// MARK: - Timeline

private enum TimelineItem: Identifiable {
    case block(Block)
    case open(start: Date, end: Date)

    var id: AnyHashable {
        switch self {
        case .block(let b):
            return AnyHashable(b.persistentModelID)
        case .open(let s, let e):
            return AnyHashable("open-\(s.timeIntervalSince1970)-\(e.timeIntervalSince1970)")
        }
    }

    var start: Date {
        switch self {
        case .block(let b): return b.start
        case .open(let s, _): return s
        }
    }

    var end: Date {
        switch self {
        case .block(let b): return b.end
        case .open(_, let e): return e
        }
    }
}

private struct TimelineScroll: View {
    let date: Date
    let blocks: [Block]
    let overlappingIDs: Set<PersistentIdentifier>
    let onTapOpen: (DateInterval) -> Void
    let onTapBlock: (Block) -> Void

    private let startHour = 7
    private let endHour = 24
    private let pointsPerMinute: CGFloat = 1.5
    private let minBlockHeight: CGFloat = 44
    private let labelColumnWidth: CGFloat = 56
    private let rightPadding: CGFloat = 16

    private var dayStart: Date {
        Calendar.current.date(bySettingHour: startHour, minute: 0, second: 0, of: date)
            ?? Calendar.current.startOfDay(for: date)
    }

    private var dayEnd: Date {
        let next = Calendar.current.date(byAdding: .day, value: 1, to: date) ?? date
        return Calendar.current.startOfDay(for: next)
    }

    private var totalHeight: CGFloat {
        CGFloat((endHour - startHour) * 60) * pointsPerMinute
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    private func y(for time: Date) -> CGFloat {
        let mins = time.timeIntervalSince(dayStart) / 60.0
        return CGFloat(mins) * pointsPerMinute
    }

    private var items: [TimelineItem] {
        var result: [TimelineItem] = []
        var cursor = dayStart
        let sorted = blocks.sorted { $0.start < $1.start }

        for b in sorted {
            let s = max(b.start, dayStart)
            if s > cursor {
                let gapMinutes = s.timeIntervalSince(cursor) / 60.0
                if gapMinutes >= 10 {
                    result.append(.open(start: cursor, end: s))
                }
            }
            result.append(.block(b))
            let e = min(b.end, dayEnd)
            if e > cursor { cursor = e }
        }

        if dayEnd > cursor {
            let gapMinutes = dayEnd.timeIntervalSince(cursor) / 60.0
            if gapMinutes >= 10 {
                result.append(.open(start: cursor, end: dayEnd))
            }
        }
        return result
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    Color.clear
                        .frame(maxWidth: .infinity)
                        .frame(height: totalHeight + 40)

                    hourRuler

                    ForEach(items) { item in
                        cardView(for: item)
                            .padding(.leading, labelColumnWidth)
                            .padding(.trailing, rightPadding)
                            .frame(height: cardHeight(for: item), alignment: .top)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .offset(y: y(for: item.start))
                    }

                    if isToday {
                        TimelineView(.periodic(from: .now, by: 30)) { ctx in
                            let now = ctx.date
                            if now >= dayStart && now <= dayEnd {
                                NowLineView(labelInset: labelColumnWidth, rightInset: rightPadding)
                                    .offset(y: y(for: now))
                                    .id("nowLine")
                            }
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .onAppear {
                guard isToday else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo("nowLine", anchor: .center)
                    }
                }
            }
            .onChange(of: date) { _, _ in
                guard isToday else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo("nowLine", anchor: .center)
                    }
                }
            }
        }
    }

    private var hourRuler: some View {
        ForEach(startHour...endHour, id: \.self) { hour in
            HStack(spacing: 6) {
                Text(hourLabel(hour))
                    .font(.system(.caption2, design: .rounded).weight(.bold).monospacedDigit())
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: labelColumnWidth - 10, alignment: .trailing)
                Rectangle()
                    .fill(Theme.hourRule)
                    .frame(height: 1)
            }
            .padding(.trailing, rightPadding)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .offset(y: CGFloat(hour - startHour) * 60 * pointsPerMinute)
        }
    }

    @ViewBuilder
    private func cardView(for item: TimelineItem) -> some View {
        switch item {
        case .block(let b):
            BlockCardView(
                block: b,
                hasOverlap: overlappingIDs.contains(b.persistentModelID)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                onTapBlock(b)
            }
        case .open(let s, let e):
            OpenCardView(start: s, end: e) {
                onTapOpen(DateInterval(start: s, end: e))
            }
        }
    }

    private func cardHeight(for item: TimelineItem) -> CGFloat {
        let minutes = item.end.timeIntervalSince(item.start) / 60.0
        return max(minBlockHeight, CGFloat(minutes) * pointsPerMinute - 4)
    }

    private func hourLabel(_ hour: Int) -> String {
        let h = hour % 24
        switch h {
        case 0: return "12A"
        case 12: return "12P"
        default:
            if h < 12 { return "\(h)A" }
            return "\(h - 12)P"
        }
    }
}

// MARK: - Cards

private struct BlockCardView: View {
    let block: Block
    let hasOverlap: Bool

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(block.category.color)
                .frame(width: 5)
                .padding(.vertical, 6)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: block.category.symbol)
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(block.category.color)
                    Text(block.category.label.uppercased())
                        .font(.system(.caption2, design: .rounded).weight(.heavy))
                        .tracking(1.2)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer(minLength: 4)
                    if hasOverlap {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(Theme.accent)
                            .accessibilityLabel("Overlaps with another block")
                    }
                }
                Text(block.title)
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(timeRange)
                        .font(.system(.caption, design: .rounded).weight(.semibold).monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                    if !block.locationName.isEmpty {
                        Text("·")
                            .foregroundStyle(Theme.textMuted)
                        Text(block.locationName)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var timeRange: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: block.start)) – \(f.string(from: block.end))"
    }
}

private struct OpenCardView: View {
    let start: Date
    let end: Date
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("OPEN — \(durationString)")
                        .font(.system(.subheadline, design: .rounded).weight(.heavy))
                        .tracking(0.8)
                        .foregroundStyle(Theme.textMuted)
                    Text(timeRange)
                        .font(.system(.caption, design: .rounded).weight(.semibold).monospacedDigit())
                        .foregroundStyle(Theme.textMuted.opacity(0.8))
                }
                Spacer(minLength: 8)
                Image(systemName: "plus.circle")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        Theme.openBorder,
                        style: StrokeStyle(lineWidth: 1.2, dash: [5, 4])
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var durationString: String {
        let total = Int(end.timeIntervalSince(start) / 60)
        let h = total / 60
        let m = total % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private var timeRange: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }
}

// MARK: - Now line

private struct NowLineView: View {
    let labelInset: CGFloat
    let rightInset: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            Text("NOW")
                .font(.system(.caption2, design: .rounded).weight(.heavy))
                .tracking(1.2)
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 2)
                .background(Theme.accent, in: Capsule())
                .frame(width: labelInset - 10, alignment: .trailing)
                .padding(.trailing, 4)
            Circle()
                .fill(Theme.accent)
                .frame(width: 9, height: 9)
            Rectangle()
                .fill(Theme.accent)
                .frame(height: 2)
        }
        .padding(.trailing, rightInset)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Floating button

private struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Theme.accent, in: Circle())
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TodayView()
        .modelContainer(for: Block.self, inMemory: true)
}
