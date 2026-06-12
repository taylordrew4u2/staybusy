//
//  StayBusyLiveActivity.swift
//  StayBusyWidgets
//
//  Belongs to the StayBusyWidgets target ONLY.
//  Requires LiveActivityAttributes.swift, BlockCategory.swift, and Theme.swift
//  to be added to this target via Target Membership.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct StayBusyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StayBusyActivityAttributes.self) { ctx in
            LockScreenLiveActivityView(state: ctx.state)
                .padding(16)
                .background(Theme.background)
        } dynamicIsland: { ctx in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    expandedLeading(state: ctx.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    expandedTrailing(state: ctx.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    expandedBottom(state: ctx.state)
                }
            } compactLeading: {
                if let cat = currentCategory(ctx.state) {
                    Image(systemName: cat.symbol)
                        .foregroundStyle(cat.color)
                }
            } compactTrailing: {
                if let end = ctx.state.currentEnd {
                    Text(timerInterval: Date()...max(end, Date().addingTimeInterval(1)), countsDown: true)
                        .monospacedDigit()
                        .foregroundStyle(Theme.accent)
                        .frame(maxWidth: 64)
                }
            } minimal: {
                if let cat = currentCategory(ctx.state) {
                    Image(systemName: cat.symbol)
                        .foregroundStyle(cat.color)
                }
            }
        }
    }

    // MARK: - Helpers

    private func currentCategory(_ s: StayBusyActivityAttributes.ContentState) -> BlockCategory? {
        s.currentCategoryRaw.flatMap { BlockCategory(rawValue: $0) }
    }

    private func nextCategory(_ s: StayBusyActivityAttributes.ContentState) -> BlockCategory? {
        s.nextCategoryRaw.flatMap { BlockCategory(rawValue: $0) }
    }

    // MARK: - Dynamic Island expanded regions

    @ViewBuilder
    private func expandedLeading(state: StayBusyActivityAttributes.ContentState) -> some View {
        if let title = state.currentTitle, let cat = currentCategory(state) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(cat.color)
                    .frame(width: 4, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("NOW")
                        .font(.system(.caption2, design: .rounded).weight(.heavy))
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .lineLimit(1)
                }
            }
        }
    }

    @ViewBuilder
    private func expandedTrailing(state: StayBusyActivityAttributes.ContentState) -> some View {
        if let end = state.currentEnd {
            VStack(alignment: .trailing, spacing: 2) {
                Text("ENDS IN")
                    .font(.system(.caption2, design: .rounded).weight(.heavy))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Text(timerInterval: Date()...max(end, Date().addingTimeInterval(1)), countsDown: true)
                    .font(.system(.title3, design: .rounded).weight(.heavy).monospacedDigit())
                    .foregroundStyle(Theme.accent)
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 90, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    private func expandedBottom(state: StayBusyActivityAttributes.ContentState) -> some View {
        if let title = state.nextTitle, let start = state.nextStart, let cat = nextCategory(state) {
            HStack(spacing: 8) {
                Image(systemName: cat.symbol)
                    .foregroundStyle(cat.color)
                Text("NEXT")
                    .font(.system(.caption2, design: .rounded).weight(.heavy))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .lineLimit(1)
                Spacer()
                Text(start, style: .time)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Lock screen view

private struct LockScreenLiveActivityView: View {
    let state: StayBusyActivityAttributes.ContentState

    private var currentCategory: BlockCategory? {
        state.currentCategoryRaw.flatMap { BlockCategory(rawValue: $0) }
    }

    private var nextCategory: BlockCategory? {
        state.nextCategoryRaw.flatMap { BlockCategory(rawValue: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title = state.currentTitle,
               let end = state.currentEnd,
               let cat = currentCategory {
                HStack(alignment: .center, spacing: 12) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(cat.color)
                        .frame(width: 5, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NOW")
                            .font(.system(.caption2, design: .rounded).weight(.heavy))
                            .tracking(1.4)
                            .foregroundStyle(Theme.textSecondary)
                        Text(title)
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ENDS IN")
                            .font(.system(.caption2, design: .rounded).weight(.heavy))
                            .tracking(1.4)
                            .foregroundStyle(Theme.textSecondary)
                        Text(timerInterval: Date()...max(end, Date().addingTimeInterval(1)), countsDown: true)
                            .font(.system(.title3, design: .rounded).weight(.heavy).monospacedDigit())
                            .foregroundStyle(Theme.accent)
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 96, alignment: .trailing)
                    }
                }
            } else {
                Text("StayBusy")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
            }

            if let nextTitle = state.nextTitle,
               let nextStart = state.nextStart,
               let nextCat = nextCategory {
                HStack(spacing: 10) {
                    Circle()
                        .fill(nextCat.color)
                        .frame(width: 8, height: 8)
                    Text("NEXT")
                        .font(.system(.caption2, design: .rounded).weight(.heavy))
                        .tracking(1.3)
                        .foregroundStyle(Theme.textSecondary)
                    Text(nextTitle)
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(nextStart, style: .time)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold).monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
    }
}
