//
//  TripTabView.swift
//  staybusy
//
//  End-to-end trip agenda: every block in the trip, grouped by day, in
//  one scrollable view. Day headers stay pinned while scrolling so you
//  always know what day you're looking at. Tap a block to open its
//  detail; tap a day header to jump that day into the Today tab.
//

import SwiftUI
import SwiftData

// MARK: - Root

struct TripTabView: View {
    @Query(sort: \Block.start, order: .forward) private var allBlocks: [Block]
    @Query(sort: \Trip.startDate, order: .reverse) private var trips: [Trip]
    let onSelectDay: (Date) -> Void

    @State private var presentedSheet: EditorSheet?
    @State private var navigationPath = NavigationPath()
    @State private var pendingDelete: Block?
    @State private var searchText: String = ""
    @State private var showingSettings = false
    @State private var showingTripSheet = false
    @State private var tripBeingEdited: Trip?
    @Environment(\.modelContext) private var context
    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled: Bool = false
    @AppStorage("activeTripID") private var activeTripID: String = ""

    /// The trip whose agenda is on screen. We resolve the persisted
    /// `activeTripID` against the current `trips` list; if that ID
    /// doesn't match anything (deleted on another device, never set),
    /// fall back to the most recent trip.
    private var activeTrip: Trip? {
        if let id = PersistentIdentifier.decode(activeTripID),
           let trip = trips.first(where: { $0.persistentModelID == id }) {
            return trip
        }
        return trips.first
    }

    /// Blocks scoped to the active trip. With no trip selected, all
    /// blocks are in scope so previous behaviour is preserved.
    private var scopedBlocks: [Block] {
        guard let trip = activeTrip else { return allBlocks }
        let range = trip.dateRange
        return allBlocks.filter { block in
            if let t = block.trip, t.persistentModelID == trip.persistentModelID {
                return true
            }
            // Also include loose blocks that fall in the trip window so
            // you can still see ad-hoc additions without having to
            // manually attach them.
            return block.trip == nil
                && block.start < range.end
                && block.end > range.start
        }
    }

    private var filteredBlocks: [Block] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return scopedBlocks }
        return scopedBlocks.filter { $0.matches(query) }
    }

    /// Summary built from the active trip's blocks so trip-wide stats
    /// (days, totals, thinnest day, spend) reflect what's actually
    /// on screen.
    private var fullSummary: TripSummary {
        TripSummary(blocks: scopedBlocks)
    }

    /// Summary used by the agenda body. With a search active this only
    /// includes days that have matching blocks, so empty days drop out
    /// instead of leaving headers floating alone.
    private var visibleSummary: TripSummary {
        TripSummary(blocks: filteredBlocks)
    }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Theme.Color.background.ignoresSafeArea()

                if trips.isEmpty {
                    EmptyStateView(
                        symbol: "suitcase",
                        title: "Plan a trip",
                        message: "Create a trip to group your blocks. StayBusy can also pull events from those dates straight out of your iOS Calendar.",
                        actionTitle: "Create a trip",
                        action: { presentTripSheet(editing: nil) },
                        secondaryActionTitle: calendarSyncEnabled ? nil : "Turn on Calendar sync",
                        secondaryActionSymbol: calendarSyncEnabled ? nil : "calendar",
                        secondaryAction: calendarSyncEnabled ? nil : { showingSettings = true }
                    )
                } else if isSearching && visibleSummary.days.isEmpty {
                    EmptyStateView(
                        symbol: "magnifyingglass",
                        title: "No matches",
                        message: "No blocks match \u{201C}\(searchText)\u{201D}.",
                        actionTitle: "Clear search",
                        action: { searchText = "" }
                    )
                } else {
                    agenda(
                        summary: isSearching ? visibleSummary : fullSummary,
                        showSummaryCard: !isSearching
                    )
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search blocks, tickets, locations"
            )
            .navigationTitle(activeTrip?.name ?? "Trip")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !trips.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        tripSwitcherMenu
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            presentedSheet = .create(suggestedInterval())
                        } label: {
                            Image(systemName: "plus")
                                .font(Theme.Font.title)
                                .foregroundStyle(Theme.Color.accent)
                                .frame(
                                    width: Theme.Size.minTapTarget,
                                    height: Theme.Size.minTapTarget
                                )
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.pressable)
                        .accessibilityLabel("Add block")
                    }
                }
            }
            .toolbarBackground(Theme.Color.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                BlockEditorView(
                    editing: nil,
                    suggested: interval,
                    defaultTrip: activeTrip
                )
            case .edit(let block):
                BlockEditorView(editing: block, suggested: nil)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingTripSheet) {
            CreateTripSheet(editing: tripBeingEdited)
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
    }

    // MARK: - Trip switcher

    @ViewBuilder
    private var tripSwitcherMenu: some View {
        Menu {
            if let trip = activeTrip {
                Section(trip.name) {
                    Button {
                        presentTripSheet(editing: trip)
                    } label: {
                        Label("Edit trip", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        deleteTrip(trip)
                    } label: {
                        Label("Delete trip", systemImage: "trash")
                    }
                }
            }
            if trips.count > 1 {
                Section("Switch to") {
                    ForEach(trips) { trip in
                        Button {
                            switchToTrip(trip)
                        } label: {
                            if trip.persistentModelID == activeTrip?.persistentModelID {
                                Label(trip.name, systemImage: "checkmark")
                            } else {
                                Text(trip.name)
                            }
                        }
                    }
                }
            }
            Button {
                presentTripSheet(editing: nil)
            } label: {
                Label("New trip", systemImage: "plus")
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "suitcase.fill")
                    .font(Theme.Font.title)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundStyle(Theme.Color.accent)
            .frame(
                width: Theme.Size.minTapTarget + 12,
                height: Theme.Size.minTapTarget
            )
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Trip menu")
    }

    private func presentTripSheet(editing: Trip?) {
        tripBeingEdited = editing
        showingTripSheet = true
    }

    private func switchToTrip(_ trip: Trip) {
        activeTripID = trip.persistentModelID.encodedURIString
    }

    private func deleteTrip(_ trip: Trip) {
        // The `.nullify` rule on Trip.blocks means blocks survive and
        // become loose again — the user's schedule isn't lost just
        // because the trip wrapper goes away.
        context.delete(trip)
        try? context.save()
        if activeTripID == trip.persistentModelID.encodedURIString {
            activeTripID = ""
        }
    }

    // MARK: - Actions

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
        // Tickets are first-class data, not files — copy them too so
        // the duplicated block carries the same boarding passes /
        // confirmation entries forward.
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

    // MARK: - Agenda body

    @ViewBuilder
    private func agenda(summary: TripSummary, showSummaryCard: Bool) -> some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: Theme.Spacing.l,
                pinnedViews: [.sectionHeaders]
            ) {
                if showSummaryCard {
                    SummaryCard(summary: summary)
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.s)
                }

                ForEach(summary.days) { day in
                    Section {
                        DayAgenda(
                            day: day,
                            onSelectBlock: { block in
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
                        .padding(.horizontal, Theme.Spacing.l)
                    } header: {
                        DayHeader(
                            day: day,
                            onJumpToDay: { onSelectDay(day.date) }
                        )
                    }
                }

                Color.clear.frame(height: Theme.Spacing.xl)
            }
        }
        .scrollIndicators(.hidden)
    }

    private func suggestedInterval() -> DateInterval {
        DateInterval(start: Date(), duration: 3600)
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
    let totalTickets: Int
    let totalOpenMinutes: Double
    let thinnestDay: DaySummary?
    let firstDate: Date?
    let lastDate: Date?
    /// Total cost across all blocks, grouped by currency. Only currencies
    /// with a non-zero sum are kept — blocks with cost 0 (the default
    /// "untracked" sentinel) contribute nothing.
    let totalsByCurrency: [(currency: String, amount: Double)]

    init(blocks: [Block]) {
        let cal = Calendar.current
        guard let firstStart = blocks.map(\.start).min(),
              let lastEnd = blocks.map(\.end).max() else {
            self.days = []
            self.totalBlocks = 0
            self.totalTickets = 0
            self.totalOpenMinutes = 0
            self.thinnestDay = nil
            self.firstDate = nil
            self.lastDate = nil
            self.totalsByCurrency = []
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
        self.totalTickets = blocks.reduce(0) { $0 + $1.orderedTickets.count }
        self.totalOpenMinutes = built.reduce(0) { $0 + $1.openMinutes }
        self.firstDate = first
        self.lastDate = last

        var byCurrency: [String: Double] = [:]
        for block in blocks where block.cost > 0 {
            byCurrency[block.currencyCode, default: 0] += block.cost
        }
        // Sort largest currency first so the headline number is the dominant spend.
        self.totalsByCurrency = byCurrency
            .map { (currency: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }

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
            HStack(alignment: .firstTextBaseline) {
                Text("TRIP OVERVIEW")
                    .font(Theme.Font.caption)
                    .tracking(1.4)
                    .foregroundStyle(Theme.Color.textSecondary)
                Spacer()
                if let span = dateSpan {
                    Text(span)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }

            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                stat(value: "\(summary.days.count)", label: "DAYS")
                stat(value: "\(summary.totalBlocks)", label: "BLOCKS")
                stat(value: openHoursLabel, label: "OPEN")
                if let spend = primarySpendLabel {
                    stat(value: spend, label: "SPEND")
                }
            }
            if summary.totalsByCurrency.count > 1 {
                Text(otherCurrenciesLabel)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textTertiary)
            }

            if summary.totalTickets > 0 {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "ticket.fill")
                        .font(Theme.Font.caption)
                    Text(ticketsLabel)
                        .font(Theme.Font.caption)
                }
                .foregroundStyle(Theme.Color.textSecondary)
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
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(Theme.Font.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ticketsLabel: String {
        let n = summary.totalTickets
        return "\(n) ticket\(n == 1 ? "" : "s") attached"
    }

    private var primarySpendLabel: String? {
        guard let top = summary.totalsByCurrency.first else { return nil }
        return formatAmount(top.amount, currency: top.currency)
    }

    private var otherCurrenciesLabel: String {
        let rest = summary.totalsByCurrency.dropFirst()
        let parts = rest.map { formatAmount($0.amount, currency: $0.currency) }
        return "+ " + parts.joined(separator: " · ")
    }

    private func formatAmount(_ amount: Double, currency: String) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currency
        f.maximumFractionDigits = amount.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return f.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    private var openHoursLabel: String {
        let total = Int(summary.totalOpenMinutes.rounded())
        let h = total / 60
        let m = total % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private var dateSpan: String? {
        guard let first = summary.firstDate, let last = summary.lastDate else { return nil }
        let f = DateFormatter()
        let cal = Calendar.current
        if cal.isDate(first, equalTo: last, toGranularity: .day) {
            f.dateFormat = "MMM d"
            return f.string(from: first)
        }
        if cal.isDate(first, equalTo: last, toGranularity: .year) {
            let s = DateFormatter(); s.dateFormat = "MMM d"
            let e = DateFormatter(); e.dateFormat = "MMM d"
            return "\(s.string(from: first)) – \(e.string(from: last))"
        }
        f.dateFormat = "MMM d, yyyy"
        return "\(f.string(from: first)) – \(f.string(from: last))"
    }

    private func formatThinnest(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f.string(from: date)
    }
}

// MARK: - Day header (sticky)

private struct DayHeader: View {
    let day: DaySummary
    let onJumpToDay: () -> Void

    var body: some View {
        Button(action: onJumpToDay) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(eyebrow)
                        .font(Theme.Font.caption)
                        .tracking(1.4)
                        .foregroundStyle(Theme.Color.textSecondary)
                    HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                        Text(weekday)
                            .font(Theme.Font.titleLarge)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text(dateLabel)
                            .font(Theme.Font.body)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                }
                Spacer(minLength: 0)
                Text(countLine)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
                Image(systemName: "arrow.up.right")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textTertiary)
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Theme.Color.background
                    .overlay(
                        Rectangle()
                            .fill(Theme.Color.hourRule)
                            .frame(height: 0.5),
                        alignment: .bottom
                    )
            )
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(weekday), \(dateLabel). \(countLine)")
        .accessibilityHint("Double tap to view this day's timeline")
    }

    private var eyebrow: String {
        let cal = Calendar.current
        if cal.isDateInToday(day.date) { return "TODAY" }
        if cal.isDateInTomorrow(day.date) { return "TOMORROW" }
        if cal.isDateInYesterday(day.date) { return "YESTERDAY" }
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: day.date).uppercased()
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
        return "\(count) \(blocksWord)"
    }
}

// MARK: - Day agenda
//
// The density bar plus a vertical list of every block on this day.

private struct DayAgenda: View {
    let day: DaySummary
    let onSelectBlock: (Block) -> Void
    let onEditBlock: (Block) -> Void
    let onDuplicateBlock: (Block) -> Void
    let onDeleteBlock: (Block) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            DensityBar(day: day)
                .frame(height: 8)

            if day.blocks.isEmpty {
                EmptyDayRow()
            } else {
                VStack(spacing: Theme.Spacing.s) {
                    ForEach(day.blocks, id: \.persistentModelID) { block in
                        Button {
                            onSelectBlock(block)
                        } label: {
                            AgendaBlockRow(block: block)
                        }
                        .buttonStyle(.pressable)
                        .accessibilityLabel(accessibility(block))
                        .accessibilityHint("Double tap to open block details. Long press for more actions.")
                        .contextMenu {
                            Button {
                                onEditBlock(block)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button {
                                onDuplicateBlock(block)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            Button(role: .destructive) {
                                onDeleteBlock(block)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private func accessibility(_ block: Block) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(block.title). \(block.category.label). \(f.string(from: block.start)) to \(f.string(from: block.end))."
    }
}

// MARK: - Agenda block row

private struct AgendaBlockRow: View {
    let block: Block

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            Rectangle()
                .fill(block.category.color)
                .frame(width: Theme.Size.categoryStripeWidth)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
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
                    Spacer(minLength: 0)
                    Text(durationLabel)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textTertiary)
                }

                Text(block.title)
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(2)

                HStack(spacing: Theme.Spacing.s) {
                    Text(timeRangeLabel)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                    if !block.locationName.isEmpty {
                        Text("·")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textTertiary)
                        HStack(spacing: 2) {
                            Image(systemName: "mappin.circle.fill")
                                .font(Theme.Font.caption)
                            Text(block.locationName)
                                .lineLimit(1)
                        }
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                    }
                }

                if hasDetailFlags {
                    HStack(spacing: Theme.Spacing.s) {
                        if ticketCount > 0 {
                            DetailFlag(
                                symbol: "ticket.fill",
                                label: ticketCount > 1 ? "\(ticketCount) tickets" : "Ticket"
                            )
                        } else if !block.confirmationCode.isEmpty {
                            DetailFlag(symbol: "ticket.fill", label: "Code")
                        }
                        if !block.attachmentFilenames.isEmpty {
                            DetailFlag(
                                symbol: "paperclip",
                                label: "\(block.attachmentFilenames.count)"
                            )
                        }
                        if !block.notes.isEmpty {
                            DetailFlag(symbol: "note.text", label: "Notes")
                        }
                        if !block.links.isEmpty {
                            DetailFlag(
                                symbol: "link",
                                label: "\(block.links.count)"
                            )
                        }
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textTertiary)
                .padding(.top, 2)
        }
        .padding(Theme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Theme.Color.surface,
            in: RoundedRectangle(cornerRadius: Theme.Radius.medium)
        )
    }

    private var ticketCount: Int {
        block.orderedTickets.count
    }

    private var hasDetailFlags: Bool {
        ticketCount > 0
            || !block.confirmationCode.isEmpty
            || !block.attachmentFilenames.isEmpty
            || !block.notes.isEmpty
            || !block.links.isEmpty
    }

    private var timeRangeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: block.start)) – \(f.string(from: block.end))"
    }

    private var durationLabel: String {
        let mins = Int(block.end.timeIntervalSince(block.start) / 60)
        let h = mins / 60
        let m = mins % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }
}

private struct DetailFlag: View {
    let symbol: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(label)
        }
        .font(Theme.Font.caption)
        .foregroundStyle(Theme.Color.textSecondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Theme.Color.surfaceElevated,
            in: Capsule()
        )
    }
}

private struct EmptyDayRow: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: "sparkles")
                .font(Theme.Font.caption)
                .foregroundStyle(Theme.Color.textTertiary)
            Text("Nothing scheduled")
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textSecondary)
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Theme.Color.surface,
            in: RoundedRectangle(cornerRadius: Theme.Radius.medium)
        )
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
    let container = try! ModelContainer(
        for: Block.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    SampleData.seedIfNeeded(context: container.mainContext)
    return TripTabView(onSelectDay: { _ in })
        .modelContainer(container)
}
