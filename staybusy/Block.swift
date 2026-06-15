//
//  Block.swift
//  staybusy
//

import Foundation
import SwiftData

@Model
final class Block {
    var title: String = ""
    var start: Date = Date()
    var end: Date = Date()
    var categoryRaw: String = BlockCategory.admin.rawValue
    var locationName: String = ""
    var address: String = ""
    var latitude: Double?
    var longitude: Double?
    var confirmationCode: String = ""
    var notes: String = ""
    var links: [String] = []
    var attachmentFilenames: [String] = []
    var notificationID: String = ""

    /// `EKEvent.eventIdentifier` for blocks imported from the system
    /// Calendar. Non-empty for synced blocks, empty for blocks created
    /// directly in StayBusy. Re-syncs use this as the dedupe key so
    /// existing imported blocks update in place instead of duplicating.
    var calendarEventID: String = ""

    /// Convenience predicate — true for blocks that originated from
    /// the system Calendar via `CalendarSyncService`.
    var isFromCalendar: Bool {
        !calendarEventID.isEmpty
    }

    /// Optional cost in `currencyCode`. Used for per-block budgets and
    /// rolled up into the trip total. `0` means "not tracked", not "free".
    var cost: Double = 0
    /// ISO 4217 currency code for `cost`. Defaults to USD; the app
    /// displays it via `NumberFormatter` so locale formatting is
    /// preserved even when several blocks ship different currencies.
    var currencyCode: String = "USD"
    /// Optional venue phone number — rendered as a tap-to-call link.
    var phone: String = ""
    /// Optional canonical website for the block (venue, airline,
    /// reservation page). Kept separate from generic `links` so it can
    /// be promoted in the detail UI.
    var website: String = ""

    /// Structured tickets attached to this block (boarding passes, event
    /// entries, etc.). Distinct from `attachmentFilenames` — tickets keep
    /// confirmation codes, seats, and gates first-class so they stay
    /// searchable and copy-pasteable.
    @Relationship(deleteRule: .cascade, inverse: \Ticket.block)
    var tickets: [Ticket]? = []

    /// CloudKit-synced binary payloads for `attachmentFilenames`. On
    /// any signed-in device, `AttachmentStore.materialize(...)` writes
    /// these to the local Documents directory so the existing
    /// URL-based view code finds the files. Cascade-deletes with the
    /// block.
    @Relationship(deleteRule: .cascade, inverse: \BlockAttachment.block)
    var attachments: [BlockAttachment]? = []

    /// Optional parent trip. Loose blocks (no trip) still render in
    /// Today and Map; the Trip tab filters by the active trip. The
    /// inverse lives on Trip so we can ask `trip.blocks?` directly.
    var trip: Trip?

    /// Convenience: the tickets sorted by `sortOrder`, with empty
    /// entries filtered out. Defensive against the optional array
    /// CloudKit requires us to declare.
    var orderedTickets: [Ticket] {
        (tickets ?? [])
            .filter { !$0.isEmpty }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    var category: BlockCategory {
        get { BlockCategory(rawValue: categoryRaw) ?? .admin }
        set { categoryRaw = newValue.rawValue }
    }

    /// Case-insensitive search across the human-typed fields on this
    /// block plus every attached ticket. Used by Trip's `.searchable`
    /// to find "DL-AB12CD", "brooklyn", "lunch" without the user
    /// remembering which field the term lives in.
    func matches(_ query: String) -> Bool {
        let needle = query.lowercased()
        guard !needle.isEmpty else { return true }
        let haystacks: [String] = [
            title,
            locationName,
            address,
            confirmationCode,
            notes,
            phone,
            website,
            category.label
        ] + links + (tickets ?? []).flatMap { ticket -> [String] in
            [
                ticket.name,
                ticket.confirmationCode,
                ticket.seat,
                ticket.gate,
                ticket.holderName
            ]
        }
        return haystacks.contains { $0.lowercased().contains(needle) }
    }

    /// Build a duplicate block from this one for "Duplicate" actions —
    /// all scalar fields are copied, but file attachments are *not*
    /// (they live in a per-block sandbox and can't be safely shared
    /// across two persistent IDs) and the title gets a `(copy)` suffix
    /// so the new block is findable. Tickets aren't copied here — the
    /// caller decides whether to clone them, since SwiftData
    /// relationships need a context to insert into.
    func makeDuplicate(timeOffset: TimeInterval = 0) -> Block {
        Block(
            title: title.isEmpty ? "Untitled (copy)" : "\(title) (copy)",
            start: start.addingTimeInterval(timeOffset),
            end: end.addingTimeInterval(timeOffset),
            category: category,
            locationName: locationName,
            address: address,
            latitude: latitude,
            longitude: longitude,
            confirmationCode: confirmationCode,
            notes: notes,
            links: links,
            attachmentFilenames: [],
            cost: cost,
            currencyCode: currencyCode,
            phone: phone,
            website: website
        )
    }

    init(
        title: String,
        start: Date,
        end: Date,
        category: BlockCategory,
        locationName: String = "",
        address: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        confirmationCode: String = "",
        notes: String = "",
        links: [String] = [],
        attachmentFilenames: [String] = [],
        cost: Double = 0,
        currencyCode: String = "USD",
        phone: String = "",
        website: String = ""
    ) {
        self.title = title
        self.start = start
        self.end = end
        self.categoryRaw = category.rawValue
        self.locationName = locationName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.confirmationCode = confirmationCode
        self.notes = notes
        self.links = links
        self.attachmentFilenames = attachmentFilenames
        self.cost = cost
        self.currencyCode = currencyCode
        self.phone = phone
        self.website = website
        self.notificationID = UUID().uuidString
    }
}
