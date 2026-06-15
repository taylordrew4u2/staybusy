//
//  SettingsView.swift
//  staybusy
//
//  App settings sheet. Exposes:
//  - the dark / warm theme picker (persisted via @AppStorage and
//    applied to the view tree by `.appTheme()`)
//  - the iOS Calendar sync toggle + manual "Sync now" action
//

import SwiftUI
import SwiftData
import EventKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage("themeMode") private var themeModeRaw: String = ThemeMode.dark.rawValue
    @AppStorage("calendarSyncEnabled") private var calendarSyncEnabled: Bool = false

    @State private var syncStatus: SyncStatus = .idle
    @State private var lastSummary: String?

    private var mode: ThemeMode {
        get { ThemeMode(rawValue: themeModeRaw) ?? .dark }
    }

    private enum SyncStatus: Equatable {
        case idle
        case requestingAccess
        case syncing
        case denied
        case ok
        case failed(String)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                        SectionLabel(title: "APPEARANCE")
                            .padding(.horizontal, Theme.Spacing.l)

                        VStack(spacing: Theme.Spacing.m) {
                            ForEach(ThemeMode.allCases) { option in
                                ThemeOptionRow(
                                    option: option,
                                    isSelected: option == mode,
                                    onSelect: { select(option) }
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.l)

                        SectionLabel(title: "CALENDAR")
                            .padding(.horizontal, Theme.Spacing.l)

                        calendarSection
                            .padding(.horizontal, Theme.Spacing.l)
                    }
                    .padding(.top, Theme.Spacing.l)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.Color.accent)
                        .font(Theme.Font.title)
                }
            }
            .toolbarBackground(Theme.Color.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .appTheme()
        .tint(Theme.Color.accent)
    }

    private func select(_ option: ThemeMode) {
        guard option != mode else { return }
        themeModeRaw = option.rawValue
        Theme.Haptic.blockSaved()
    }

    // MARK: - Calendar section

    @ViewBuilder
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                Image(systemName: "calendar")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.accent)
                    .frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sync with iOS Calendar")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("Pull events from your iPhone Calendar into the timeline.")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Toggle("", isOn: $calendarSyncEnabled)
                    .labelsHidden()
                    .tint(Theme.Color.accent)
                    .onChange(of: calendarSyncEnabled) { _, enabled in
                        if enabled { Task { await syncNow() } }
                    }
            }

            if calendarSyncEnabled {
                Button(action: { Task { await syncNow() } }) {
                    HStack(spacing: Theme.Spacing.s) {
                        if case .syncing = syncStatus {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(Theme.Color.accent)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text(syncButtonTitle)
                            .font(Theme.Font.title)
                    }
                    .foregroundStyle(Theme.Color.accent)
                    .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
                    .padding(.vertical, Theme.Spacing.s)
                    .background(
                        Theme.Color.accent.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    )
                }
                .buttonStyle(.pressable)
                .disabled(syncStatus == .syncing || syncStatus == .requestingAccess)

                if let summary = statusLabel {
                    Text(summary)
                        .font(Theme.Font.caption)
                        .foregroundStyle(summaryColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(Theme.Spacing.l)
        .background(
            Theme.Color.surface,
            in: RoundedRectangle(cornerRadius: Theme.Radius.medium)
        )
    }

    private var syncButtonTitle: String {
        switch syncStatus {
        case .syncing: return "Syncing\u{2026}"
        case .requestingAccess: return "Requesting access\u{2026}"
        default: return "Sync now"
        }
    }

    private var statusLabel: String? {
        switch syncStatus {
        case .idle:
            return lastSummary
        case .ok:
            return lastSummary ?? "Up to date"
        case .denied:
            return "Calendar access denied. Enable it in iOS Settings → StayBusy → Calendars."
        case .failed(let message):
            return message
        case .requestingAccess, .syncing:
            return nil
        }
    }

    private var summaryColor: Color {
        switch syncStatus {
        case .denied, .failed: return Theme.Color.warning
        default: return Theme.Color.textSecondary
        }
    }

    @MainActor
    private func syncNow() async {
        let service = CalendarSyncService.shared
        if !service.isAuthorized {
            syncStatus = .requestingAccess
            let granted = await service.requestAccess()
            if !granted {
                syncStatus = .denied
                calendarSyncEnabled = false
                return
            }
        }
        syncStatus = .syncing
        let result = await service.sync(context: context)
        lastSummary = result.summary
        syncStatus = .ok
        Theme.Haptic.blockSaved()
    }
}

// MARK: - Theme option row

private struct ThemeOptionRow: View {
    let option: ThemeMode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.Spacing.m) {
                ThemeSwatch(option: option)

                VStack(alignment: .leading, spacing: 2) {
                    Text(option.label)
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text(option.subtitle)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(Theme.Font.titleLarge)
                    .foregroundStyle(
                        isSelected
                            ? Theme.Color.accent
                            : Theme.Color.textTertiary
                    )
            }
            .padding(Theme.Spacing.m)
            .frame(minHeight: Theme.Size.minTapTarget)
            .background(
                Theme.Color.surface,
                in: RoundedRectangle(cornerRadius: Theme.Radius.medium)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.medium)
                    .stroke(
                        isSelected ? Theme.Color.accent : Color.clear,
                        lineWidth: Theme.Stroke.currentBlockBorder
                    )
            )
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("\(option.label) theme")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Theme swatch
//
// Renders a 3-block mini timeline preview using the option's palette so
// the user sees what each theme looks like before selecting it. The
// preview uses a fixed local palette (not `Theme.Color`) so each row
// shows its own theme regardless of the currently active one.

private struct ThemeSwatch: View {
    let option: ThemeMode

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.Radius.small)
                .fill(palette.background)

            VStack(alignment: .leading, spacing: 4) {
                Capsule()
                    .fill(palette.muted)
                    .frame(height: 6)
                Capsule()
                    .fill(palette.accent)
                    .frame(height: 8)
                Capsule()
                    .fill(palette.muted)
                    .frame(height: 6)
            }
            .padding(8)
        }
        .frame(width: 56, height: 56)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.small)
                .stroke(palette.border, lineWidth: 0.5)
        )
    }

    private var palette: SwatchPalette {
        switch option {
        case .dark:
            return SwatchPalette(
                background: Color(red: 0x0D / 255, green: 0x0D / 255, blue: 0x0F / 255),
                muted:      Color(red: 0x3A / 255, green: 0x3A / 255, blue: 0x41 / 255),
                accent:     Color(red: 0xE5 / 255, green: 0x39 / 255, blue: 0x35 / 255),
                border:     Color.white.opacity(0.08)
            )
        case .warm:
            return SwatchPalette(
                background: Color(red: 0xFE / 255, green: 0xF9 / 255, blue: 0xF5 / 255),
                muted:      Color(red: 0xE8 / 255, green: 0xD4 / 255, blue: 0xC4 / 255),
                accent:     Color(red: 0xFF / 255, green: 0x6B / 255, blue: 0x35 / 255),
                border:     Color.black.opacity(0.08)
            )
        }
    }
}

private struct SwatchPalette {
    let background: Color
    let muted: Color
    let accent: Color
    let border: Color
}

// MARK: - Section label

private struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(Theme.Font.caption)
            .tracking(1.5)
            .foregroundStyle(Theme.Color.textSecondary)
    }
}

#Preview {
    SettingsView()
}
