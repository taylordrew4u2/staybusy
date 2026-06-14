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
        WidgetCenter.shared.reloadAllTimelines()
    }

    func blockUpdated(_ block: Block) async {
        await scheduleStartAndWarning(for: block)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func blockDeleted(_ block: Block) {
        center.removePendingNotificationRequests(withIdentifiers: allIDs(for: block))
        WidgetCenter.shared.reloadAllTimelines()
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
        [startID(for: block), warningID(for: block), leaveByID(for: block)]
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

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}
