//
//  CalendarSyncService.swift
//  staybusy
//
//  One-way pull from the system Calendar (EventKit) into StayBusy's
//  Block store. Lets the user "live in" iOS Calendar but pick up
//  StayBusy's per-block enrichments — tickets, cost, phone, website,
//  category — on top.
//
//  Sync semantics:
//  - Pulls events from every Calendar the user has access to, in a
//    rolling window (`pastDays` … `futureDays` around today).
//  - Uses `EKEvent.eventIdentifier` as the dedupe key, mirrored into
//    `Block.calendarEventID`.
//  - On re-sync we update **only** the fields the Calendar owns
//    (title, start, end, location, notes). StayBusy-only fields
//    (tickets, cost/currency, phone, website, category override,
//    attachments, links, confirmationCode) are preserved.
//  - Category for newly-imported events is inferred from the title
//    via simple keyword matching; existing blocks keep whatever
//    category the user picked.
//  - Orphans (blocks whose calendar event was deleted in iOS) inside
//    the sync window are removed locally.
//

import Foundation
import EventKit
import SwiftData
import CoreLocation

@MainActor
final class CalendarSyncService {
    static let shared = CalendarSyncService()

    private let store: EKEventStore
    private let pastDays: Int = 7
    private let futureDays: Int = 60

    private init(store: EKEventStore = EKEventStore()) {
        self.store = store
    }

    // MARK: - Authorization

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    var isAuthorized: Bool {
        switch authorizationStatus {
        case .fullAccess, .writeOnly, .authorized:
            return true
        default:
            return false
        }
    }

    /// Request access. iOS 17+ uses `requestFullAccessToEvents`; on
    /// older OSes we'd fall back to `requestAccess(to:)` but the app
    /// targets iOS 18+, so we don't need that branch.
    func requestAccess() async -> Bool {
        if isAuthorized { return true }
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    // MARK: - Sync

    /// Pulls events in the rolling window and upserts them into
    /// `context`. Returns the count of inserts / updates / deletes for
    /// surfacing in the UI. Throws nothing — failures map to no-ops.
    @discardableResult
    func sync(context: ModelContext) async -> SyncResult {
        await sync(context: context, trip: nil)
    }

    /// Trip-scoped variant: when `trip` is non-nil, the sync window is
    /// the trip's full date range (instead of the rolling default) and
    /// every imported event is attached to the trip.
    @discardableResult
    func sync(context: ModelContext, trip: Trip?) async -> SyncResult {
        guard isAuthorized else { return .init() }

        let now = Date()
        let cal = Calendar.current
        let windowStart: Date
        let windowEnd: Date
        if let trip {
            let range = trip.dateRange
            windowStart = range.start
            windowEnd = range.end
        } else {
            windowStart = cal.date(byAdding: .day, value: -pastDays, to: now) ?? now
            windowEnd = cal.date(byAdding: .day, value: futureDays, to: now) ?? now
        }

        let predicate = store.predicateForEvents(
            withStart: windowStart,
            end: windowEnd,
            calendars: nil // nil = every accessible calendar
        )
        let events = store.events(matching: predicate)
            // Exclude all-day events — they don't fit the timeline UI
            // (it's hour-precision) and would render as full-day blocks.
            .filter { !$0.isAllDay }

        // Existing imported blocks inside the window — used for upsert
        // and orphan detection.
        let descriptor = FetchDescriptor<Block>(
            predicate: #Predicate<Block> { block in
                block.calendarEventID != "" &&
                block.end >= windowStart &&
                block.start <= windowEnd
            }
        )
        let existingBlocks: [Block] = (try? context.fetch(descriptor)) ?? []
        var byEventID: [String: Block] = [:]
        for block in existingBlocks {
            byEventID[block.calendarEventID] = block
        }

        var result = SyncResult()
        var seenIDs: Set<String> = []

        for event in events {
            let id = event.eventIdentifier ?? ""
            guard !id.isEmpty else { continue }
            seenIDs.insert(id)

            if let block = byEventID[id] {
                if applyUpdates(from: event, to: block) {
                    result.updated += 1
                }
                // Late-attach to the trip if we synced loose events
                // before the trip existed.
                if let trip, block.trip == nil {
                    block.trip = trip
                }
            } else {
                let block = makeBlock(from: event)
                block.trip = trip
                context.insert(block)
                result.inserted += 1
            }
        }

        // Orphans: events removed from Calendar within the window.
        for (id, block) in byEventID where !seenIDs.contains(id) {
            NotificationManager.shared.blockDeleted(block)
            context.delete(block)
            result.deleted += 1
        }

        if result.touched > 0 {
            try? context.save()
        }

        // Background fill: any imported block without coordinates gets
        // reverse-geocoded so it can show up on the map. CLGeocoder is
        // rate-limited, so this runs detached and doesn't block the
        // sync return.
        Task { @MainActor in
            await GeocodingService.shared.geocodeMissingCoordinates(in: context)
        }

        return result
    }

    // MARK: - Export (StayBusy → iCal)

    /// Two-way push: write `block` into the user's default Calendar so
    /// the same item shows up in iCal too. Stores the resulting event
    /// identifier on `block.calendarEventID` so subsequent pulls
    /// recognize it as already-linked and don't double-insert.
    ///
    /// No-op when access is read-only or `block.calendarEventID` is
    /// already set (treat the iCal side as the source of truth in that
    /// case — we'd rather not fork the data).
    @discardableResult
    func exportBlock(_ block: Block, context: ModelContext) async -> Bool {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            return false
        }
        guard block.calendarEventID.isEmpty else { return false }
        guard let calendar = store.defaultCalendarForNewEvents else { return false }

        let event = EKEvent(eventStore: store)
        event.calendar = calendar
        event.title = block.title
        event.startDate = block.start
        event.endDate = block.end
        if !block.locationName.isEmpty {
            event.location = block.locationName
        }
        if !block.notes.isEmpty {
            event.notes = block.notes
        }
        if let lat = block.latitude, let lng = block.longitude {
            let location = EKStructuredLocation(title: block.locationName)
            location.geoLocation = CLLocation(latitude: lat, longitude: lng)
            event.structuredLocation = location
        }

        do {
            try store.save(event, span: .thisEvent, commit: true)
            block.calendarEventID = event.eventIdentifier ?? ""
            try? context.save()
            return true
        } catch {
            return false
        }
    }

    // MARK: - Mapping

    private func makeBlock(from event: EKEvent) -> Block {
        let block = Block(
            title: event.title ?? "Untitled",
            start: event.startDate,
            end: event.endDate,
            category: inferCategory(from: event),
            locationName: event.location ?? "",
            address: "",
            notes: event.notes ?? ""
        )
        block.calendarEventID = event.eventIdentifier ?? ""
        if let geo = event.structuredLocation?.geoLocation {
            block.latitude = geo.coordinate.latitude
            block.longitude = geo.coordinate.longitude
        }
        return block
    }

    /// Mutates `block` with the event's fields. Returns `true` when
    /// anything actually changed (used for the updated count).
    private func applyUpdates(from event: EKEvent, to block: Block) -> Bool {
        var changed = false
        let title = event.title ?? "Untitled"
        if block.title != title {
            block.title = title
            changed = true
        }
        if block.start != event.startDate {
            block.start = event.startDate
            changed = true
        }
        if block.end != event.endDate {
            block.end = event.endDate
            changed = true
        }
        let location = event.location ?? ""
        if block.locationName != location {
            block.locationName = location
            changed = true
        }
        // Adopt any updated structured-location coordinates iCal carries.
        if let geo = event.structuredLocation?.geoLocation {
            let lat = geo.coordinate.latitude
            let lng = geo.coordinate.longitude
            if block.latitude != lat || block.longitude != lng {
                block.latitude = lat
                block.longitude = lng
                changed = true
            }
        }
        let notes = event.notes ?? ""
        // Only sync notes if the user hasn't customized them — if the
        // local notes are empty or match what Calendar previously had,
        // adopt the new value. Otherwise leave local notes alone so
        // tickets/notes the user added stay safe.
        if block.notes.isEmpty || block.notes == notes {
            if block.notes != notes {
                block.notes = notes
                changed = true
            }
        }
        return changed
    }

    private func inferCategory(from event: EKEvent) -> BlockCategory {
        let text = ((event.title ?? "") + " " + (event.notes ?? "")).lowercased()
        if matches(text, ["flight", "train", "drive", "transit", "uber", "lyft", "taxi", "transfer"]) {
            return .travel
        }
        if matches(text, ["breakfast", "brunch", "lunch", "dinner", "coffee", "drinks", "meal"]) {
            return .food
        }
        if matches(text, ["show", "gig", "concert", "set", "performance", "soundcheck"]) {
            return .gig
        }
        if matches(text, ["meeting", "interview", "call", "1:1", "standup", "review", "sync"]) {
            return .work
        }
        if matches(text, ["rest", "sleep", "nap", "break", "downtime", "recover"]) {
            return .rest
        }
        if matches(text, ["tour", "explore", "sightsee", "visit", "museum", "walk"]) {
            return .explore
        }
        if matches(text, ["drinks", "party", "social", "hangout", "catchup", "friends"]) {
            return .social
        }
        return .admin
    }

    private func matches(_ text: String, _ keywords: [String]) -> Bool {
        for kw in keywords where text.contains(kw) { return true }
        return false
    }
}

// MARK: - Sync result

struct SyncResult: Equatable {
    var inserted: Int = 0
    var updated: Int = 0
    var deleted: Int = 0

    var touched: Int { inserted + updated + deleted }

    var summary: String {
        if touched == 0 { return "Already up to date" }
        var parts: [String] = []
        if inserted > 0 { parts.append("\(inserted) added") }
        if updated > 0 { parts.append("\(updated) updated") }
        if deleted > 0 { parts.append("\(deleted) removed") }
        return parts.joined(separator: " · ")
    }
}
