//
//  RemainingBlocksWidget.swift
//  StayBusyWidgets
//
//  Belongs to the StayBusyWidgets target ONLY.
//  Requires Block.swift, BlockCategory.swift, Theme.swift, and
//  LiveActivityAttributes.swift (for StayBusyAppGroup) to be added to this
//  target via Target Membership.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget

struct RemainingBlocksWidget: Widget {
    let kind: String = "RemainingBlocksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RemainingBlocksProvider()) { entry in
            RemainingBlocksView(entry: entry)
                .containerBackground(Theme.Color.background, for: .widget)
        }
        .configurationDisplayName("Remaining today")
        .description("Blocks left on your schedule today.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Snapshot value type (avoids passing @Model objects across timeline entries)

struct BlockSnapshot: Hashable, Identifiable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let categoryRaw: String
    let locationName: String

    var category: BlockCategory {
        BlockCategory(rawValue: categoryRaw) ?? .admin
    }
}

// MARK: - Timeline entry

struct RemainingBlocksEntry: TimelineEntry {
    let date: Date
    let blocks: [BlockSnapshot]
}

// MARK: - Provider

struct RemainingBlocksProvider: TimelineProvider {
    func placeholder(in context: Context) -> RemainingBlocksEntry {
        RemainingBlocksEntry(
            date: .now,
            blocks: [
                BlockSnapshot(
                    id: "1",
                    title: "Soundcheck",
                    start: .now,
                    end: .now.addingTimeInterval(3600),
                    categoryRaw: BlockCategory.gig.rawValue,
                    locationName: "Brooklyn Steel"
                ),
                BlockSnapshot(
                    id: "2",
                    title: "Show",
                    start: .now.addingTimeInterval(10800),
                    end: .now.addingTimeInterval(18000),
                    categoryRaw: BlockCategory.gig.rawValue,
                    locationName: "Brooklyn Steel"
                ),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (RemainingBlocksEntry) -> Void) {
        completion(makeEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RemainingBlocksEntry>) -> Void) {
        let now = Date()
        let cal = Calendar.current
        let allToday = fetchBlocks(forDayContaining: now)

        var entries: [RemainingBlocksEntry] = []
        entries.append(makeEntry(at: now, allToday: allToday))

        // Add an entry at every remaining block boundary so the widget refreshes
        // as blocks end and drop off the list.
        let boundaries = allToday
            .flatMap { [$0.start, $0.end] }
            .filter { $0 > now }
            .sorted()

        for boundary in boundaries {
            entries.append(makeEntry(at: boundary, allToday: allToday))
        }

        // After the last entry, reload at the start of the next day so a new
        // day's blocks appear.
        let nextDayStart = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now) ?? now)
        let timeline = Timeline(entries: entries, policy: .after(nextDayStart))
        completion(timeline)
    }

    // MARK: - Helpers

    private func makeEntry(at date: Date) -> RemainingBlocksEntry {
        makeEntry(at: date, allToday: fetchBlocks(forDayContaining: date))
    }

    private func makeEntry(at date: Date, allToday: [BlockSnapshot]) -> RemainingBlocksEntry {
        let remaining = allToday.filter { $0.end > date }
        return RemainingBlocksEntry(date: date, blocks: remaining)
    }

    private func fetchBlocks(forDayContaining date: Date) -> [BlockSnapshot] {
        guard let container = try? sharedContainer() else { return [] }
        let context = ModelContext(container)
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = cal.date(byAdding: .day, value: 1, to: dayStart) ?? date

        let descriptor = FetchDescriptor<Block>(
            predicate: #Predicate<Block> { block in
                block.start >= dayStart && block.start < dayEnd
            },
            sortBy: [SortDescriptor(\.start)]
        )

        let blocks = (try? context.fetch(descriptor)) ?? []
        return blocks.map { block in
            BlockSnapshot(
                id: block.notificationID.isEmpty
                    ? "\(block.start.timeIntervalSinceReferenceDate)-\(block.title)"
                    : block.notificationID,
                title: block.title,
                start: block.start,
                end: block.end,
                categoryRaw: block.categoryRaw,
                locationName: block.locationName
            )
        }
    }

    private func sharedContainer() throws -> ModelContainer {
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: StayBusyAppGroup.identifier
        ) {
            let storeURL = groupURL.appendingPathComponent("staybusy.sqlite")
            // Widget reads the local copy of the store that the main app keeps
            // in sync with CloudKit; the widget itself does not sync.
            let config = ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
            return try ModelContainer(for: Block.self, configurations: config)
        }
        // Fallback (no App Group capability): widget will see an empty store.
        return try ModelContainer(for: Block.self)
    }
}

// MARK: - View

struct RemainingBlocksView: View {
    let entry: RemainingBlocksEntry

    var body: some View {
        if entry.blocks.isEmpty {
            emptyState
        } else {
            populated
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("ALL DONE")
                .font(Theme.Font.caption)
                .tracking(1.4)
                .foregroundStyle(Theme.Color.textSecondary)
            Text("No more blocks today")
                .font(Theme.Font.title)
                .foregroundStyle(Theme.Color.textPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var populated: some View {
        let displayed = Array(entry.blocks.prefix(4))
        return VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text("REMAINING TODAY")
                .font(Theme.Font.caption)
                .tracking(1.3)
                .foregroundStyle(Theme.Color.textSecondary)
            VStack(spacing: Theme.Spacing.xs) {
                ForEach(displayed) { b in
                    HStack(spacing: Theme.Spacing.s) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(b.category.color)
                            .frame(width: 3, height: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(b.title)
                                .font(Theme.Font.body)
                                .foregroundStyle(Theme.Color.textPrimary)
                                .lineLimit(1)
                            Text(timeRange(b))
                                .font(Theme.Font.caption)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func timeRange(_ b: BlockSnapshot) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: b.start)) – \(f.string(from: b.end))"
    }
}
