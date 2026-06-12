//
//  LiveActivityManager.swift
//  staybusy
//

import Foundation
import ActivityKit
import WidgetKit

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private var activity: Activity<StayBusyActivityAttributes>?
    private var lastState: StayBusyActivityAttributes.ContentState?

    /// Single entry point: pass the current set of blocks (app's @Query result).
    /// Internally figures out start / update / end based on today's blocks vs now.
    func sync(blocks: [Block]) {
        let now = Date()
        let cal = Calendar.current
        let todayBlocks = blocks
            .filter { cal.isDate($0.start, inSameDayAs: now) }
            .sorted { $0.start < $1.start }

        let current = todayBlocks.first { $0.start <= now && now < $0.end }
        let next = todayBlocks.first { $0.start > now }

        adoptExistingActivityIfNeeded()

        let isDayDone: Bool = {
            guard let lastEnd = todayBlocks.last?.end else { return true }
            return now >= lastEnd
        }()

        if isDayDone {
            endActivity()
            return
        }

        let state = makeState(current: current, next: next)

        if activity == nil {
            // Per spec: start the activity when a block becomes current.
            guard current != nil else { return }
            startActivity(state: state)
        } else {
            updateActivity(state: state)
        }
    }

    // MARK: - Private

    private func adoptExistingActivityIfNeeded() {
        if activity == nil, let existing = Activity<StayBusyActivityAttributes>.activities.first {
            activity = existing
        }
    }

    private func makeState(
        current: Block?,
        next: Block?
    ) -> StayBusyActivityAttributes.ContentState {
        StayBusyActivityAttributes.ContentState(
            currentTitle: current?.title,
            currentStart: current?.start,
            currentEnd: current?.end,
            currentCategoryRaw: current?.categoryRaw,
            currentLocationName: current?.locationName,
            nextTitle: next?.title,
            nextStart: next?.start,
            nextCategoryRaw: next?.categoryRaw
        )
    }

    private func startActivity(state: StayBusyActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            let new = try Activity<StayBusyActivityAttributes>.request(
                attributes: StayBusyActivityAttributes(),
                content: ActivityContent(state: state, staleDate: nil),
                pushType: nil
            )
            activity = new
            lastState = state
        } catch {
            // Common reasons: user disabled, frequency limit, missing entitlement
        }
    }

    private func updateActivity(state: StayBusyActivityAttributes.ContentState) {
        guard let activity else { return }
        guard lastState != state else { return }
        lastState = state
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    private func endActivity() {
        guard let activity else { return }
        let final = lastState ?? StayBusyActivityAttributes.ContentState()
        Task {
            await activity.end(
                ActivityContent(state: final, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
        self.activity = nil
        self.lastState = nil
    }
}
