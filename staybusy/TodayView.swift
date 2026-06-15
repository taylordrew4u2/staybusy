//
//  TodayView.swift
//  staybusy
//

import SwiftUI
import SwiftData

// MARK: - Root

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Block.start, order: .forward) private var allBlocks: [Block]

    @Binding var selectedDate: Date
    @State private var navigationPath = NavigationPath()
    @State private var presentedSheet: EditorSheet?
    @State private var pendingDelete: Block?
    @State private var showingSettings = false
    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled: Bool = false

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
                Theme.Color.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    DayPickerBar(selectedDate: $selectedDate)
                    NowNextBar(allBlocks: allBlocks)
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.bottom, Theme.Spacing.s)
                    if blocksForSelectedDay.isEmpty {
                        EmptyStateView(
                            symbol: "calendar.badge.plus",
                            title: "Nothing scheduled",
                            message: calendarSyncEnabled
                                ? "Add a block to start mapping out your day."
                                : "Add a block, or pull events from your iOS Calendar.",
                            actionTitle: "Add a block",
                            action: { presentedSheet = .create(suggestedDefaultInterval()) },
                            secondaryActionTitle: calendarSyncEnabled ? nil : "Sync iOS Calendar",
                            secondaryActionSymbol: calendarSyncEnabled ? nil : "calendar",
                            secondaryAction: calendarSyncEnabled ? nil : { showingSettings = true }
                        )
                        .frame(maxHeight: .infinity)
                    } else {
                        TimelineScroll(
                            date: selectedDate,
                            blocks: blocksForSelectedDay,
                            overlappingIDs: overlappingIDs,
                            onTapOpen: { interval in
                                presentedSheet = .create(interval)
                            },
                            onTapBlock: { block in
                                navigationPath.append(block)
                            },
                            onEditBlock: { block in
                                presentedSheet = .edit(block)
                            },
                            onDuplicateBlock: { block in
                                duplicate(block)
                            },
                            onDeleteBlock: { block in
                                pendingDelete = block
                            }
                        )
                    }
                }

                FloatingAddButton {
                    presentedSheet = .create(DateInterval(start: suggestedStartForCreate(), duration: 3600))
                }
                .padding(Theme.Spacing.l)
            }
            .navigationDestination(for: Block.self) { block in
                BlockDetailView(block: block) {
                    presentedSheet = .edit(block)
                }
            }
        }
        .appTheme()
        .tint(Theme.Color.accent)
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
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .confirmationDialog(
            "Delete this block?",
            isPresented: deletionBinding,
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { block in
            Button("Delete \"\(block.title)\"", role: .destructive) {
                delete(block)
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: { _ in
            Text("This can't be undone.")
        }
        .onAppear {
            LiveActivityManager.shared.sync(blocks: allBlocks)
        }
        .onChange(of: allBlocks) { _, new in
            LiveActivityManager.shared.sync(blocks: new)
        }
    }

    private var deletionBinding: Binding<Bool> {
        Binding(
            get: { pendingDelete != nil },
            set: { isPresented in
                if !isPresented { pendingDelete = nil }
            }
        )
    }

    private func duplicate(_ block: Block) {
        let copy = block.makeDuplicate()
        context.insert(copy)
        for source in block.orderedTickets {
            let ticket = Ticket(
                name: source.name,
                confirmationCode: source.confirmationCode,
                seat: source.seat,
                gate: source.gate,
                holderName: source.holderName,
                sortOrder: source.sortOrder
            )
            ticket.block = copy
            context.insert(ticket)
        }
        try? context.save()
        Theme.Haptic.blockSaved()
    }

    private func delete(_ block: Block) {
        NotificationManager.shared.blockDeleted(block)
        context.delete(block)
        try? context.save()
        pendingDelete = nil
    }

    private func suggestedDefaultInterval() -> DateInterval {
        DateInterval(start: suggestedStartForCreate(), duration: 3600)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let date: Date
    let blocks: [Block]
    let overlappingIDs: Set<PersistentIdentifier>
    let onTapOpen: (DateInterval) -> Void
    let onTapBlock: (Block) -> Void
    let onEditBlock: (Block) -> Void
    let onDuplicateBlock: (Block) -> Void
    let onDeleteBlock: (Block) -> Void

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
                .padding(.top, Theme.Spacing.s)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .onAppear {
                guard isToday else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(Theme.Motion.gentle(reduceMotion: reduceMotion)) {
                        proxy.scrollTo("nowLine", anchor: .center)
                    }
                }
            }
            .onChange(of: date) { _, _ in
                guard isToday else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(Theme.Motion.gentle(reduceMotion: reduceMotion)) {
                        proxy.scrollTo("nowLine", anchor: .center)
                    }
                }
            }
        }
    }

    private var hourRuler: some View {
        ForEach(startHour...endHour, id: \.self) { hour in
            HStack(spacing: Theme.Spacing.xs) {
                Text(hourLabel(hour))
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textTertiary)
                    .frame(width: labelColumnWidth - 10, alignment: .trailing)
                Rectangle()
                    .fill(Theme.Color.hourRule)
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
            let now = Date()
            let isCurrent = isToday && b.start <= now && now < b.end
            let isPast = isToday && b.end <= now
            Button {
                onTapBlock(b)
            } label: {
                BlockCard(
                    block: b,
                    variant: .timeline,
                    isCurrent: isCurrent,
                    isPast: isPast,
                    hasOverlap: overlappingIDs.contains(b.persistentModelID)
                )
            }
            .buttonStyle(.pressable)
            .contextMenu {
                Button {
                    onEditBlock(b)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button {
                    onDuplicateBlock(b)
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                }
                Button(role: .destructive) {
                    onDeleteBlock(b)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        case .open(let s, let e):
            OpenSlotCard(start: s, end: e) {
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

// MARK: - Now line

private struct NowLineView: View {
    let labelInset: CGFloat
    let rightInset: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            Text("NOW")
                .font(Theme.Font.caption)
                .tracking(1.2)
                .foregroundStyle(.white)
                .padding(.horizontal, Theme.Spacing.s)
                .padding(.vertical, 2)
                .background(Theme.Color.accent, in: Capsule())
                .frame(width: labelInset - 10, alignment: .trailing)
                .padding(.trailing, Theme.Spacing.xs)
            Circle()
                .fill(Theme.Color.accent)
                .frame(width: 9, height: 9)
            Rectangle()
                .fill(Theme.Color.accent)
                .frame(height: 2)
        }
        .padding(.trailing, rightInset)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityHidden(true)
    }
}

// MARK: - Floating button

private struct FloatingAddButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(Theme.Font.titleLarge)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Theme.Color.accent, in: Circle())
                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Add block")
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Block.self, Ticket.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    SampleData.seedIfNeeded(context: container.mainContext)
    return TodayView(selectedDate: .constant(Date()))
        .modelContainer(container)
}
