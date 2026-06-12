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
        HStack(spacing: 16) {
            chevron("chevron.left") { adjust(-1) }

            VStack(spacing: 2) {
                Text(headlineDate)
                    .font(.system(.title3, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                if isToday {
                    Text("TODAY")
                        .font(.system(.caption2, design: .rounded).weight(.heavy))
                        .tracking(1.6)
                        .foregroundStyle(Theme.accent)
                } else {
                    Button {
                        selectedDate = Calendar.current.startOfDay(for: Date())
                    } label: {
                        Text("JUMP TO TODAY")
                            .font(.system(.caption2, design: .rounded).weight(.heavy))
                            .tracking(1.4)
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)

            chevron("chevron.right") { adjust(1) }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private func chevron(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 17, weight: .heavy))
                .foregroundStyle(Theme.textPrimary)
                .frame(width: 38, height: 38)
                .background(Theme.surface, in: Circle())
        }
        .buttonStyle(.plain)
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
