//
//  NotificationManager.swift
//  staybusy
//

import Foundation
import SwiftData
import UserNotifications
import WidgetKit

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let firstBlockKey = "staybusy.hasCreatedFirstBlock"

    private init() {}

    // MARK: - Public API

    func blockCreated(_ block: Block) async {
        if !UserDefaults.standard.bool(forKey: firstBlockKey) {
            UserDefaults.standard.set(true, forKey: firstBlockKey)
            _ = await requestAuthorization()
        }
        await scheduleStartAndWarning(for: block)
        await scheduleAirportDeparture(for: block)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func blockUpdated(_ block: Block) async {
        await scheduleStartAndWarning(for: block)
        await scheduleAirportDeparture(for: block)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func blockDeleted(_ block: Block) {
        center.removePendingNotificationRequests(withIdentifiers: allIDs(for: block))
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// True when the block looks like an airport / flight departure —
    /// surfaced in UI to indicate the longer-than-usual leave buffer.
    /// Heuristics: travel category + (ticket gate set OR title /
    /// location mentions airport/flight/airline signals).
    func isAirportDeparture(_ block: Block) -> Bool {
        airportBufferMinutes(for: block) != nil
    }

    func registerLeaveBy(_ leaveBy: Date, for block: Block) async {
        await scheduleLeaveByAlert(leaveBy: leaveBy, for: block)
    }

    // MARK: - Internal

    private func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    private func isAuthorized() async -> Bool {
        let s = await center.notificationSettings()
        return s.authorizationStatus == .authorized || s.authorizationStatus == .provisional
    }

    private func scheduleStartAndWarning(for block: Block) async {
        let pair = [startID(for: block), warningID(for: block)]
        center.removePendingNotificationRequests(withIdentifiers: pair)

        guard await isAuthorized() else { return }

        let now = Date()

        if block.start > now {
            let content = UNMutableNotificationContent()
            content.title = "Now: \(block.title)"
            content.body = block.locationName
            content.sound = .default
            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: block.start
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let req = UNNotificationRequest(
                identifier: startID(for: block),
                content: content,
                trigger: trigger
            )
            try? await center.add(req)
        }

        if block.category == .gig || block.category == .travel {
            let warningTime = block.start.addingTimeInterval(-10 * 60)
            if warningTime > now {
                let content = UNMutableNotificationContent()
                content.title = "Starts in 10 min: \(block.title)"
                content.body = block.locationName
                content.sound = .default
                let comps = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: warningTime
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let req = UNNotificationRequest(
                    identifier: warningID(for: block),
                    content: content,
                    trigger: trigger
                )
                try? await center.add(req)
            }
        }
    }

    /// Schedule a notification that fires when it's time to head out
    /// for an airport-style block. The lead time depends on whether
    /// the block looks international (3h), domestic flight (2h), or
    /// generic transit (skipped here — covered by the regular start
    /// + 10-min warning).
    private func scheduleAirportDeparture(for block: Block) async {
        let id = airportID(for: block)
        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard await isAuthorized() else { return }
        guard let bufferMinutes = airportBufferMinutes(for: block) else { return }

        let triggerTime = block.start.addingTimeInterval(-bufferMinutes * 60)
        guard triggerTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Leave for \(destinationLabel(block))"
        content.body = leaveBody(
            block: block,
            bufferMinutes: bufferMinutes
        )
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(req)
    }

    /// Returns the lead-time-minutes for airport blocks, or `nil` if
    /// the block isn't an airport departure (no notification scheduled).
    private func airportBufferMinutes(for block: Block) -> Double? {
        guard block.category == .travel else { return nil }
        guard looksLikeAirport(block) else { return nil }
        return isInternational(block) ? 180 : 120
    }

    private func looksLikeAirport(_ block: Block) -> Bool {
        // A flight ticket nearly always carries a gate; that's the
        // strongest signal we have.
        if block.orderedTickets.contains(where: { !$0.gate.isEmpty }) {
            return true
        }
        let signals = [
            "airport", "flight", "fly ", "boarding", "departure", "gate",
            "lga", "jfk", "ord", "lax", "sfo", "dfw", "atl", "bos",
            "sea", "mia", "iah", "dca", "phx", "den",
            "heathrow", "gatwick", "cdg", "fra", "nrt", "hnd",
            "delta", "united", "american", "jetblue", "southwest", "alaska",
            "british airways", "lufthansa", "air france", "ana", "ba "
        ]
        let lowered = (block.title + " " + block.locationName + " " + block.notes).lowercased()
        return signals.contains { lowered.contains($0) }
    }

    private func isInternational(_ block: Block) -> Bool {
        let signals = ["international", "intl ", "customs", "passport", "embassy"]
        let lowered = (block.title + " " + block.locationName + " " + block.notes).lowercased()
        return signals.contains { lowered.contains($0) }
    }

    private func destinationLabel(_ block: Block) -> String {
        if !block.locationName.isEmpty { return block.locationName }
        return block.title
    }

    private func leaveBody(block: Block, bufferMinutes: Double) -> String {
        let bufferText = bufferLabel(bufferMinutes)
        let startText = formatTime(block.start)
        if let gate = block.orderedTickets.first(where: { !$0.gate.isEmpty })?.gate {
            return "Departure \(startText). Gate \(gate). Plan for \(bufferText) at the airport."
        }
        return "Departure \(startText). Plan for \(bufferText) at the airport."
    }

    private func bufferLabel(_ minutes: Double) -> String {
        let h = Int(minutes / 60)
        let m = Int(minutes) % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    private func scheduleLeaveByAlert(leaveBy: Date, for block: Block) async {
        let id = leaveByID(for: block)
        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard await isAuthorized() else { return }

        let triggerTime = leaveBy.addingTimeInterval(-5 * 60)
        guard triggerTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Leave soon for \(block.title)"
        content.body = "Leave by \(formatTime(leaveBy))"
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try? await center.add(req)
    }

    // MARK: - Identifiers

    private func allIDs(for block: Block) -> [String] {
        [startID(for: block), warningID(for: block), leaveByID(for: block), airportID(for: block)]
    }

    private func baseID(for block: Block) -> String {
        if block.notificationID.isEmpty {
            block.notificationID = UUID().uuidString
            try? block.modelContext?.save()
        }
        return block.notificationID
    }

    private func startID(for block: Block) -> String {
        "block.\(baseID(for: block)).start"
    }

    private func warningID(for block: Block) -> String {
        "block.\(baseID(for: block)).warning"
    }

    private func leaveByID(for block: Block) -> String {
        "block.\(baseID(for: block)).leaveBy"
    }

    private func airportID(for block: Block) -> String {
        "block.\(baseID(for: block)).airport"
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}
