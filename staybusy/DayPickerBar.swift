//
//  DayPickerBar.swift
//  staybusy
//

import SwiftUI

struct DayPickerBar: View {
    @Binding var selectedDate: Date

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.l) {
            chevron("chevron.left", label: "Previous day") { adjust(-1) }

            VStack(spacing: 2) {
                Text(headlineDate)
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.textPrimary)
                if isToday {
                    Text("TODAY")
                        .font(Theme.Font.caption)
                        .tracking(1.6)
                        .foregroundStyle(Theme.Color.accent)
                } else {
                    Button {
                        selectedDate = Calendar.current.startOfDay(for: Date())
                    } label: {
                        Text("JUMP TO TODAY")
                            .font(Theme.Font.caption)
                            .tracking(1.4)
                            .foregroundStyle(Theme.Color.accent)
                            .padding(.horizontal, Theme.Spacing.s)
                            .padding(.vertical, Theme.Spacing.xs)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("Jump to today")
                }
            }
            .frame(maxWidth: .infinity)

            chevron("chevron.right", label: "Next day") { adjust(1) }
        }
        .padding(.horizontal, Theme.Spacing.l)
        .padding(.top, Theme.Spacing.m)
        .padding(.bottom, Theme.Spacing.s)
    }

    private func chevron(_ system: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(Theme.Font.title)
                .foregroundStyle(Theme.Color.textPrimary)
                .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                .background(Theme.Color.surface, in: Circle())
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(label)
    }

    private func adjust(_ days: Int) {
        if let new = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = Calendar.current.startOfDay(for: new)
        }
    }

    private var headlineDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: selectedDate)
    }
}
