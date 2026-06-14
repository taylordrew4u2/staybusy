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
                .padding(Theme.Spacing.l)
                .background(Theme.Color.background)
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
                        .foregroundStyle(Theme.Color.accent)
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
            HStack(spacing: Theme.Spacing.s) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(cat.color)
                    .frame(width: Theme.Size.categoryStripeWidth, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("NOW")
                        .font(Theme.Font.caption)
                        .tracking(1.2)
                        .foregroundStyle(.secondary)
                    Text(title)
                        .font(Theme.Font.title)
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
                    .font(Theme.Font.caption)
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Text(timerInterval: Date()...max(end, Date().addingTimeInterval(1)), countsDown: true)
                    .font(Theme.Font.titleLarge.monospacedDigit())
                    .foregroundStyle(Theme.Color.accent)
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 90, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    private func expandedBottom(state: StayBusyActivityAttributes.ContentState) -> some View {
        if let title = state.nextTitle, let start = state.nextStart, let cat = nextCategory(state) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: cat.symbol)
                    .foregroundStyle(cat.textOnSurface)
                Text("NEXT")
                    .font(Theme.Font.caption)
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(Theme.Font.body)
                    .lineLimit(1)
                Spacer()
                Text(start, style: .time)
                    .font(Theme.Font.caption)
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
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            if let title = state.currentTitle,
               let end = state.currentEnd,
               let cat = currentCategory {
                HStack(alignment: .center, spacing: Theme.Spacing.m) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(cat.color)
                        .frame(width: 5, height: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NOW")
                            .font(Theme.Font.caption)
                            .tracking(1.4)
                            .foregroundStyle(Theme.Color.textSecondary)
                        Text(title)
                            .font(Theme.Font.titleLarge)
                            .foregroundStyle(Theme.Color.textPrimary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: Theme.Spacing.s)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("ENDS IN")
                            .font(Theme.Font.caption)
                            .tracking(1.4)
                            .foregroundStyle(Theme.Color.textSecondary)
                        Text(timerInterval: Date()...max(end, Date().addingTimeInterval(1)), countsDown: true)
                            .font(Theme.Font.displayCountdown)
                            .foregroundStyle(Theme.Color.accent)
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 96, alignment: .trailing)
                    }
                }
            } else {
                Text("StayBusy")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)
            }

            if let nextTitle = state.nextTitle,
               let nextStart = state.nextStart,
               let nextCat = nextCategory {
                HStack(spacing: Theme.Spacing.s) {
                    Circle()
                        .fill(nextCat.color)
                        .frame(width: 8, height: 8)
                    Text("NEXT")
                        .font(Theme.Font.caption)
                        .tracking(1.3)
                        .foregroundStyle(Theme.Color.textSecondary)
                    Text(nextTitle)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: Theme.Spacing.s)
                    Text(nextStart, style: .time)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
        }
    }
}
