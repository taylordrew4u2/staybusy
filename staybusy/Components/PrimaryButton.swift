//
//  PrimaryButton.swift
//  staybusy
//
//  Two button styles used by every action surface in the app. Both
//  guarantee the 44pt minimum tap target and route through Theme.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.s) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(Theme.Font.title)
                }
                Text(title)
                    .font(Theme.Font.title)
            }
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
            .padding(.vertical, Theme.Spacing.s)
            .background(Theme.Color.accent, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .foregroundStyle(Color.white)
        }
        .buttonStyle(.pressable)
    }
}

struct SecondaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.s) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(Theme.Font.title)
                }
                Text(title)
                    .font(Theme.Font.title)
            }
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
            .padding(.vertical, Theme.Spacing.s)
            .background(Theme.Color.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .foregroundStyle(Theme.Color.textPrimary)
        }
        .buttonStyle(.pressable)
    }
}
