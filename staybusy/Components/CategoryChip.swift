//
//  CategoryChip.swift
//  staybusy
//
//  Selector chip used in the editor's category row and anywhere else
//  a category is chosen. Color is never the only signal — the symbol
//  appears alongside the color so the chip remains identifiable when
//  Increase Contrast or Differentiate Without Color is enabled.
//

import SwiftUI

struct CategoryChip: View {
    let category: BlockCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: category.symbol)
                    .font(Theme.Font.caption)
                Text(category.label)
                    .font(Theme.Font.body)
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .frame(minWidth: Theme.Size.minTapTarget, minHeight: Theme.Size.minTapTarget)
            .background(
                isSelected ? category.color : Theme.Color.surface,
                in: Capsule()
            )
            .foregroundStyle(isSelected ? Color.white : Theme.Color.textPrimary)
            .overlay {
                Capsule()
                    .stroke(category.color.opacity(isSelected ? 0 : 0.55), lineWidth: 1.2)
            }
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(category.label)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
