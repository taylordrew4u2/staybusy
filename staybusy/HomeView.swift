//
//  HomeView.swift
//  staybusy
//
//  Calm landing screen. Hands the dense timeline off to the Today tab and
//  surfaces only what you need at a glance: greeting, Now/Next, upcoming
//  blocks, and quick jumps into the other tabs.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Block.start, order: .forward) private var allBlocks: [Block]

    let onSelectTab: (TabSelection) -> Void
    @Binding var selectedDate: Date

    @State private var presentedSheet: EditorSheet?
    @State private var showingSettings = false
    @State private var navigationPath = NavigationPath()

    // Boarding-pass import state
    @State private var boardingPassItem: PhotosPickerItem?
    @State private var boardingPassPickerOpen = false
    @State private var isImportingPass = false
    @State private var importBanner: String?

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Theme.Color.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        GreetingHeader(
                            date: Date(),
                            onOpenSettings: { showingSettings = true }
                        )
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.top, Theme.Spacing.s)

                        NowNextBar(allBlocks: allBlocks)
                            .padding(.horizontal, Theme.Spacing.l)

                        BoardingPassImportCard(
                            isImporting: isImportingPass,
                            statusMessage: importBanner,
                            onTap: { boardingPassPickerOpen = true }
                        )
                        .padding(.horizontal, Theme.Spacing.l)

                        UpNextSection(
                            blocks: upcomingBlocks,
                            onSeeAll: {
                                selectedDate = Calendar.current.startOfDay(for: Date())
                                onSelectTab(.today)
                            },
                            onSelectBlock: { block in
                                navigationPath.append(block)
                            }
                        )

                        QuickActionsSection(
                            onAdd: {
                                presentedSheet = .create(suggestedDefaultInterval())
                            },
                            onToday: {
                                selectedDate = Calendar.current.startOfDay(for: Date())
                                onSelectTab(.today)
                            },
                            onMap: { onSelectTab(.map) },
                            onTrip: { onSelectTab(.trip) }
                        )

                        TodaySummary(
                            blockCount: blocksToday.count,
                            scheduledMinutes: scheduledMinutesToday
                        )
                        .padding(.horizontal, Theme.Spacing.l)
                        .padding(.bottom, Theme.Spacing.xl)
                    }
                }
            }
            .navigationBarHidden(true)
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
                BlockEditorView(editing: block, suggested: nil)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .photosPicker(
            isPresented: $boardingPassPickerOpen,
            selection: $boardingPassItem,
            matching: .images
        )
        .onChange(of: boardingPassItem) { _, item in
            guard let item else { return }
            Task { await importBoardingPass(from: item) }
        }
    }

    // MARK: - Boarding pass import
    //
    // Turn a single photo into a fully-formed Travel block: OCR fills
    // ticket fields, the image becomes a synced attachment, and the
    // user lands in the block's detail view ready to adjust times.

    @MainActor
    private func importBoardingPass(from item: PhotosPickerItem) async {
        defer { boardingPassItem = nil }
        isImportingPass = true
        importBanner = "Reading boarding pass\u{2026}"

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            isImportingPass = false
            importBanner = "Couldn't read that photo. Try another one."
            return
        }

        let draft = await TicketScanner.scan(image)

        // Pick reasonable defaults — round to the next hour, default
        // two-hour window so it's visible on the timeline. The user can
        // adjust once they land in the editor.
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month, .day, .hour], from: now)
        let nextHour = cal.date(from: comps)?.addingTimeInterval(3600) ?? now
        let title = draft.name.isEmpty ? "Flight" : draft.name

        let block = Block(
            title: title,
            start: nextHour,
            end: nextHour.addingTimeInterval(2 * 3600),
            category: .travel
        )
        context.insert(block)

        // Persist the image as a synced attachment.
        if let jpegData = image.jpegData(compressionQuality: 0.85),
           let url = AttachmentStore.attach(
               data: jpegData,
               extension: "jpg",
               to: block,
               in: context
           ) {
            block.attachmentFilenames.append(url.lastPathComponent)
        }

        // Persist the ticket itself if OCR produced anything.
        if !draft.isEmpty {
            let ticket = Ticket(
                name: draft.name,
                confirmationCode: draft.confirmationCode,
                seat: draft.seat,
                gate: draft.gate,
                holderName: draft.holderName,
                sortOrder: 0
            )
            ticket.block = block
            context.insert(ticket)
        }

        try? context.save()

        await NotificationManager.shared.blockCreated(block)

        isImportingPass = false
        importBanner = draft.isEmpty
            ? "Photo added — confirm the details."
            : "Ticket filled — confirm the time."
        Theme.Haptic.blockSaved()
        navigationPath.append(block)
    }

    // MARK: - Derived data

    private var blocksToday: [Block] {
        let cal = Calendar.current
        let today = Date()
        return allBlocks.filter { cal.isDate($0.start, inSameDayAs: today) }
    }

    private var upcomingBlocks: [Block] {
        let now = Date()
        let cal = Calendar.current
        let endOfTomorrow = cal.date(
            byAdding: .day,
            value: 2,
            to: cal.startOfDay(for: now)
        ) ?? now
        return allBlocks
            .filter { $0.end > now && $0.start < endOfTomorrow }
            .sorted { $0.start < $1.start }
    }

    private var scheduledMinutesToday: Int {
        blocksToday.reduce(0) { partial, block in
            partial + Int(block.end.timeIntervalSince(block.start) / 60)
        }
    }

    private func suggestedDefaultInterval() -> DateInterval {
        let cal = Calendar.current
        let base = cal.date(bySettingHour: 0, minute: 0, second: 0, of: Date()) ?? Date()
        let now = Date()
        let start = max(now, base)
        let rounded = roundUpToFive(start)
        return DateInterval(start: rounded, duration: 3600)
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

// MARK: - Greeting

private struct GreetingHeader: View {
    let date: Date
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(greeting)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                Text(longDate)
                    .font(Theme.Font.titleLarge)
                    .foregroundStyle(Theme.Color.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onOpenSettings) {
                Image(systemName: "gearshape.fill")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .frame(
                        width: Theme.Size.minTapTarget,
                        height: Theme.Size.minTapTarget
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Settings")
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Hello"
        }
    }

    private var longDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }
}

// MARK: - Up Next

private struct UpNextSection: View {
    let blocks: [Block]
    let onSeeAll: () -> Void
    let onSelectBlock: (Block) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(title: "UP NEXT", trailingTitle: "See all", trailingAction: onSeeAll)
                .padding(.horizontal, Theme.Spacing.l)

            if blocks.isEmpty {
                EmptyUpNext()
                    .padding(.horizontal, Theme.Spacing.l)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.m) {
                        ForEach(Array(blocks.prefix(5)), id: \.persistentModelID) { block in
                            Button {
                                onSelectBlock(block)
                            } label: {
                                UpNextCard(block: block)
                                    .frame(width: 240)
                            }
                            .buttonStyle(.pressable)
                            .accessibilityLabel("\(block.title), \(block.category.label)")
                            .accessibilityHint("Double tap to open block details")
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.l)
                }
            }
        }
    }
}

private struct UpNextCard: View {
    let block: Block

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: block.category.symbol)
                    .font(Theme.Font.caption)
                    .foregroundStyle(block.category.textOnSurface)
                Text(block.category.label.uppercased())
                    .font(Theme.Font.caption)
                    .tracking(1.2)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            Text(block.title)
                .font(Theme.Font.title)
                .foregroundStyle(Theme.Color.textPrimary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            Spacer(minLength: 0)
            if hasFlags {
                HStack(spacing: Theme.Spacing.xs) {
                    if ticketCount > 0 {
                        flag(symbol: "ticket.fill", label: ticketCount > 1 ? "\(ticketCount)" : "Ticket")
                    } else if !block.confirmationCode.isEmpty {
                        flag(symbol: "ticket.fill", label: "Code")
                    }
                    if !block.notes.isEmpty {
                        flag(symbol: "note.text", label: "Notes")
                    }
                    if !block.attachmentFilenames.isEmpty {
                        flag(symbol: "paperclip", label: "\(block.attachmentFilenames.count)")
                    }
                }
            }
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "clock")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textTertiary)
                Text(timeLabel)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        }
        .padding(Theme.Spacing.m)
        .frame(height: 156, alignment: .topLeading)
        .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(block.category.color)
                .frame(width: Theme.Size.categoryStripeWidth)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                .padding(.vertical, Theme.Spacing.s)
        }
    }

    private var ticketCount: Int { block.orderedTickets.count }

    private var hasFlags: Bool {
        ticketCount > 0
            || !block.confirmationCode.isEmpty
            || !block.notes.isEmpty
            || !block.attachmentFilenames.isEmpty
    }

    private func flag(symbol: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
            Text(label)
        }
        .font(Theme.Font.caption)
        .foregroundStyle(Theme.Color.textSecondary)
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, 3)
        .background(Theme.Color.surfaceElevated, in: Capsule())
    }

    private var timeLabel: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        let cal = Calendar.current
        let dayTag: String
        if cal.isDateInToday(block.start) {
            dayTag = "Today"
        } else if cal.isDateInTomorrow(block.start) {
            dayTag = "Tomorrow"
        } else {
            let day = DateFormatter()
            day.dateFormat = "EEE"
            dayTag = day.string(from: block.start)
        }
        return "\(dayTag) · \(f.string(from: block.start))"
    }
}

private struct EmptyUpNext: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "sparkles")
                .font(Theme.Font.title)
                .foregroundStyle(Theme.Color.textTertiary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Nothing coming up")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                Text("Add a block to fill the day.")
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }
}

// MARK: - Quick Actions

private struct QuickActionsSection: View {
    let onAdd: () -> Void
    let onToday: () -> Void
    let onMap: () -> Void
    let onTrip: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.m),
        GridItem(.flexible(), spacing: Theme.Spacing.m)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(title: "QUICK ACTIONS")
                .padding(.horizontal, Theme.Spacing.l)

            LazyVGrid(columns: columns, spacing: Theme.Spacing.m) {
                QuickActionTile(
                    title: "Add block",
                    symbol: "plus.circle.fill",
                    tint: Theme.Color.accent,
                    action: onAdd
                )
                QuickActionTile(
                    title: "Today",
                    symbol: "calendar.day.timeline.left",
                    tint: Theme.Color.Category.work,
                    action: onToday
                )
                QuickActionTile(
                    title: "Map",
                    symbol: "map.fill",
                    tint: Theme.Color.Category.travel,
                    action: onMap
                )
                QuickActionTile(
                    title: "Trip",
                    symbol: "suitcase.fill",
                    tint: Theme.Color.Category.explore,
                    action: onTrip
                )
            }
            .padding(.horizontal, Theme.Spacing.l)
        }
    }
}

private struct QuickActionTile: View {
    let title: String
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.small)
                        .fill(tint.opacity(0.18))
                        .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                    Image(systemName: symbol)
                        .font(Theme.Font.title)
                        .foregroundStyle(tint)
                }
                Text(title)
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.m)
            .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(title)
    }
}

// MARK: - Today Summary

private struct TodaySummary: View {
    let blockCount: Int
    let scheduledMinutes: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            SectionHeader(title: "TODAY AT A GLANCE")
            HStack(spacing: Theme.Spacing.m) {
                StatTile(
                    value: "\(blockCount)",
                    label: blockCount == 1 ? "Block" : "Blocks",
                    symbol: "rectangle.stack.fill"
                )
                StatTile(
                    value: durationLabel,
                    label: "Scheduled",
                    symbol: "clock.fill"
                )
            }
        }
    }

    private var durationLabel: String {
        let h = scheduledMinutes / 60
        let m = scheduledMinutes % 60
        if h == 0 { return "\(m)m" }
        if m == 0 { return "\(h)h" }
        return "\(h)h \(m)m"
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Image(systemName: symbol)
                .font(Theme.Font.title)
                .foregroundStyle(Theme.Color.textSecondary)
            Text(value)
                .font(Theme.Font.titleLarge)
                .foregroundStyle(Theme.Color.textPrimary)
            Text(label.uppercased())
                .font(Theme.Font.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.Color.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.m)
        .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }
}

// MARK: - Boarding pass import card
//
// Tap → photo library. Lifts the ticket-scan flow out of the
// per-block editor so importing a boarding pass is two taps from cold:
// open StayBusy → tap this card → pick the photo.

private struct BoardingPassImportCard: View {
    let isImporting: Bool
    let statusMessage: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack(alignment: .top, spacing: Theme.Spacing.m) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.Radius.small)
                            .fill(Theme.Color.accent.opacity(0.18))
                            .frame(width: 40, height: 40)
                        Image(systemName: "airplane.departure")
                            .font(Theme.Font.title)
                            .foregroundStyle(Theme.Color.accent)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Scan a boarding pass")
                            .font(Theme.Font.title)
                            .foregroundStyle(Theme.Color.textPrimary)
                        Text("Pick from photos — StayBusy fills the flight, gate, seat, and code.")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.textTertiary)
                }
                if isImporting {
                    HStack(spacing: Theme.Spacing.s) {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(Theme.Color.accent)
                        Text(statusMessage ?? "Reading\u{2026}")
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                    }
                } else if let statusMessage {
                    Text(statusMessage)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(Theme.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Theme.Color.surface,
                in: RoundedRectangle(cornerRadius: Theme.Radius.medium)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .stroke(Theme.Color.accent.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.pressable)
        .disabled(isImporting)
        .accessibilityLabel("Scan a boarding pass from photos")
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    var trailingTitle: String? = nil
    var trailingAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.Font.caption)
                .tracking(1.5)
                .foregroundStyle(Theme.Color.textSecondary)
            Spacer(minLength: Theme.Spacing.s)
            if let trailingTitle, let trailingAction {
                Button(action: trailingAction) {
                    Text(trailingTitle)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.accent)
                }
                .buttonStyle(.pressable)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Block.self, Ticket.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    SampleData.seedIfNeeded(context: container.mainContext)
    return HomeView(
        onSelectTab: { _ in },
        selectedDate: .constant(Date())
    )
    .modelContainer(container)
}
