//
//  SampleData.swift
//  staybusy
//
//  Demo data is no longer seeded into production. This file now hosts
//  a one-shot cleanup that removes the previously-shipped sample
//  blocks from any user's store on first launch. It's also used by
//  Xcode previews to populate an in-memory container.
//

import Foundation
import SwiftData

enum SampleData {
    /// (title, locationName) pairs that uniquely identify the blocks
    /// the old `seedIfNeeded` planted. Matching on both fields keeps us
    /// from accidentally deleting a real user's block that happens to
    /// share one of these titles.
    private static let knownSeedFingerprints: [(title: String, location: String)] = [
        ("Hotel breakfast", "The Standard"),
        ("Travel to venue", "Brooklyn Steel"),
        ("Soundcheck", "Brooklyn Steel"),
        ("Green room rest", "Brooklyn Steel"),
        ("Show", "Brooklyn Steel"),
        ("Flight LGA → ORD", "LaGuardia Airport"),
        ("Lunch w/ promoter", "Au Cheval"),
        ("Radio interview", "WBEZ Studios"),
    ]

    private static let cleanupKey = "staybusy.didCleanupSampleData_v1"

    /// One-shot cleanup. Idempotent per device — the guard flag in
    /// `UserDefaults` makes re-runs no-ops. Tickets and attachments
    /// cascade with the block delete.
    @MainActor
    static func purgeSeededBlocksIfNeeded(context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: cleanupKey) else { return }

        let descriptor = FetchDescriptor<Block>()
        guard let blocks = try? context.fetch(descriptor) else {
            defaults.set(true, forKey: cleanupKey)
            return
        }

        var removed = 0
        for block in blocks where isLikelyAFakeSeed(block) {
            NotificationManager.shared.blockDeleted(block)
            context.delete(block)
            removed += 1
        }
        if removed > 0 {
            try? context.save()
        }
        defaults.set(true, forKey: cleanupKey)
    }

    private static func isLikelyAFakeSeed(_ block: Block) -> Bool {
        // Calendar-imported blocks are real user data even if a title
        // happens to match a fingerprint. Only purge native (non-iCal)
        // blocks.
        guard !block.isFromCalendar else { return false }
        return knownSeedFingerprints.contains { fingerprint in
            block.title == fingerprint.title
                && block.locationName == fingerprint.location
        }
    }

    /// Hard reset — used by the Settings "Delete all blocks" action.
    /// Removes every Block (and via cascade rules every Ticket and
    /// BlockAttachment) but leaves trips intact so the user's date
    /// containers survive.
    @MainActor
    static func deleteAllBlocks(context: ModelContext) {
        let descriptor = FetchDescriptor<Block>()
        guard let blocks = try? context.fetch(descriptor) else { return }
        for block in blocks {
            NotificationManager.shared.blockDeleted(block)
            context.delete(block)
        }
        try? context.save()
    }
}

// MARK: - Preview seeding
//
// Used by SwiftUI previews via `SampleData.seedIfNeeded(context:)` —
// keeps developer tooling working while production no longer seeds
// anything on launch.

extension SampleData {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Block>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: today) else { return }

        func at(_ day: Date, _ hour: Int, _ minute: Int = 0) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        let plan: [(Block, [Ticket])] = [
            (
                Block(
                    title: "Hotel breakfast",
                    start: at(today, 8, 0),
                    end: at(today, 9, 0),
                    category: .food,
                    locationName: "The Standard",
                    address: "25 Cooper Square, New York, NY",
                    cost: 28
                ),
                []
            ),
            (
                Block(
                    title: "Soundcheck",
                    start: at(today, 14, 0),
                    end: at(today, 15, 30),
                    category: .gig,
                    locationName: "Brooklyn Steel",
                    address: "319 Frost St, Brooklyn, NY",
                    confirmationCode: "BS-44721",
                    notes: "Backline ready."
                ),
                [
                    Ticket(name: "Crew pass", confirmationCode: "BS-44721", sortOrder: 0)
                ]
            ),
            (
                Block(
                    title: "Flight LGA → ORD",
                    start: at(tomorrow, 9, 30),
                    end: at(tomorrow, 12, 0),
                    category: .travel,
                    locationName: "LaGuardia Airport",
                    confirmationCode: "DL-AB12CD"
                ),
                [
                    Ticket(
                        name: "Boarding pass",
                        confirmationCode: "DL-AB12CD",
                        seat: "12A",
                        gate: "B23",
                        sortOrder: 0
                    )
                ]
            ),
        ]

        for (block, tickets) in plan {
            context.insert(block)
            for ticket in tickets {
                ticket.block = block
                context.insert(ticket)
            }
        }
    }
}
