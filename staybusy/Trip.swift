//
//  Trip.swift
//  staybusy
//
//  Explicit container for a multi-day trip — name, start, end. Blocks
//  attach to a Trip via the optional `Block.trip` relationship; the
//  Trip tab shows the active trip's agenda and the calendar-sync
//  service uses the active trip's date range to pull iCal events
//  scoped to that window.
//

import Foundation
import SwiftData

@Model
final class Trip {
    var name: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date()
    var createdAt: Date = Date()

    /// Blocks that belong to this trip. We nullify (not cascade) on
    /// delete so removing a trip wrapper doesn't wipe the user's
    /// schedule — blocks just become loose again.
    @Relationship(deleteRule: .nullify, inverse: \Block.trip)
    var blocks: [Block]? = []

    init(name: String, startDate: Date, endDate: Date) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = Date()
    }

    /// Date span as a half-open `[startOfDay(start), startOfNextDay(end))`
    /// interval. Used by the calendar sync to query iCal and by the
    /// agenda to filter blocks.
    var dateRange: DateInterval {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        let nextAfterEnd = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: endDate)) ?? endDate
        return DateInterval(start: start, end: nextAfterEnd)
    }

    /// Number of calendar days the trip spans (inclusive). 1 for a
    /// same-day trip.
    var dayCount: Int {
        let cal = Calendar.current
        let s = cal.startOfDay(for: startDate)
        let e = cal.startOfDay(for: endDate)
        return max(1, (cal.dateComponents([.day], from: s, to: e).day ?? 0) + 1)
    }
}
