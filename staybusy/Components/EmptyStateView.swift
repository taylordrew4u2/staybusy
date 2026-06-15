//
//  EmptyStateView.swift
//  staybusy
//
//  Reusable empty state. The optional action enforces design law 1:
//  no dead-end screen — every empty state offers one button that starts
//  the user toward filling it.
//

import SwiftUI

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String?
    let actionTitle: String?
    let action: (() -> Void)?
    let secondaryActionTitle: String?
    let secondaryActionSymbol: String?
    let secondaryAction: (() -> Void)?

    init(
        symbol: String,
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        secondaryActionTitle: String? = nil,
        secondaryActionSymbol: String? = nil,
        secondaryAction: (() -> Void)? = nil
    ) {
        self.symbol = symbol
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.secondaryActionTitle = secondaryActionTitle
        self.secondaryActionSymbol = secondaryActionSymbol
        self.secondaryAction = secondaryAction
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            Image(systemName: symbol)
                .font(Theme.Font.displayCountdown)
                .foregroundStyle(Theme.Color.textSecondary)
            Text(title)
                .font(Theme.Font.titleLarge)
                .foregroundStyle(Theme.Color.textPrimary)
                .multilineTextAlignment(.center)
            if let message {
                Text(message)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                PrimaryButton(title: actionTitle, systemImage: "plus", action: action)
                    .frame(maxWidth: 260)
                    .padding(.top, Theme.Spacing.s)
            }
            if let secondaryActionTitle, let secondaryAction {
                Button(action: secondaryAction) {
                    HStack(spacing: Theme.Spacing.xs) {
                        if let secondaryActionSymbol {
                            Image(systemName: secondaryActionSymbol)
                        }
                        Text(secondaryActionTitle)
                    }
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.accent)
                    .frame(minHeight: Theme.Size.minTapTarget)
                    .padding(.horizontal, Theme.Spacing.m)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
