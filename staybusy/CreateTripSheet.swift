//
//  CreateTripSheet.swift
//  staybusy
//
//  Sheet for creating or editing a Trip. On save, fires off a
//  trip-scoped iCal sync so any events the user already has on those
//  dates flow into the trip immediately.
//

import SwiftUI
import SwiftData

struct CreateTripSheet: View {
    let editing: Trip?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name: String = ""
    @State private var startDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var endDate: Date = Calendar.current.date(
        byAdding: .day,
        value: 2,
        to: Calendar.current.startOfDay(for: Date())
    ) ?? Date()
    @State private var didHydrate = false
    @State private var isSyncing = false
    @State private var statusMessage: String?

    @FocusState private var nameFocused: Bool

    @AppStorage("activeTripID") private var activeTripID: String = ""

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty && endDate >= startDate
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    field("TRIP NAME") {
                        TextField("e.g. Brooklyn run", text: $name)
                            .focused($nameFocused)
                            .textInputAutocapitalization(.words)
                    }

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        sectionLabel("DATES")
                        VStack(spacing: Theme.Spacing.m) {
                            dateRow("STARTS", date: $startDate)
                            dateRow("ENDS", date: $endDate)
                            if endDate < startDate {
                                HStack(spacing: Theme.Spacing.xs) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                    Text("End date must be on or after start.")
                                        .font(Theme.Font.caption)
                                }
                                .foregroundStyle(Theme.Color.warning)
                            } else {
                                Text(dayCountLabel)
                                    .font(Theme.Font.caption)
                                    .foregroundStyle(Theme.Color.textSecondary)
                            }
                        }
                        .padding(Theme.Spacing.m)
                        .background(
                            Theme.Color.surface,
                            in: RoundedRectangle(cornerRadius: Theme.Radius.medium)
                        )
                    }

                    if let statusMessage {
                        HStack(spacing: Theme.Spacing.s) {
                            if isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(Theme.Color.accent)
                            } else {
                                Image(systemName: "calendar.badge.checkmark")
                                    .foregroundStyle(Theme.Color.accent)
                            }
                            Text(statusMessage)
                                .font(Theme.Font.caption)
                                .foregroundStyle(Theme.Color.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.Color.background)
            .navigationTitle(editing == nil ? "New Trip" : "Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .font(Theme.Font.title)
                    .foregroundStyle(canSave ? Theme.Color.accent : Theme.Color.textTertiary)
                    .disabled(!canSave || isSyncing)
                }
            }
            .toolbarBackground(Theme.Color.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .appTheme()
        .tint(Theme.Color.accent)
        .onAppear(perform: hydrate)
    }

    // MARK: - Lifecycle

    private func hydrate() {
        guard !didHydrate else { return }
        if let trip = editing {
            name = trip.name
            startDate = trip.startDate
            endDate = trip.endDate
        }
        didHydrate = true
        if editing == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                nameFocused = true
            }
        }
    }

    @MainActor
    private func save() async {
        guard canSave else { return }
        let trip: Trip
        if let existing = editing {
            existing.name = trimmedName
            existing.startDate = startDate
            existing.endDate = endDate
            trip = existing
        } else {
            let new = Trip(name: trimmedName, startDate: startDate, endDate: endDate)
            context.insert(new)
            trip = new
        }
        try? context.save()
        activeTripID = trip.persistentModelID.encodedURIString

        // If calendar sync is on and authorized, pull events for the
        // trip window before dismissing — that way the new trip
        // immediately has anything the user already had on those days.
        let syncEnabled = UserDefaults.standard.bool(forKey: "calendarSyncEnabled")
        if syncEnabled, CalendarSyncService.shared.isAuthorized {
            isSyncing = true
            statusMessage = "Pulling events for those dates\u{2026}"
            let result = await CalendarSyncService.shared.sync(
                context: context,
                trip: trip
            )
            isSyncing = false
            statusMessage = result.summary
            // Give the user a beat to read the status before dismissing.
            try? await Task.sleep(nanoseconds: 600_000_000)
        }

        Theme.Haptic.blockSaved()
        dismiss()
    }

    // MARK: - Field helpers

    @ViewBuilder
    private func field<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionLabel(label)
            content()
                .font(Theme.Font.titleLarge)
                .foregroundStyle(Theme.Color.textPrimary)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.m)
                .background(
                    Theme.Color.surface,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.medium)
                )
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.caption)
            .tracking(1.4)
            .foregroundStyle(Theme.Color.textSecondary)
    }

    private func dateRow(_ label: String, date: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(Theme.Font.caption)
                .tracking(1.0)
                .foregroundStyle(Theme.Color.textSecondary)
                .frame(width: 64, alignment: .leading)
            Spacer()
            DatePicker(
                "",
                selection: date,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .tint(Theme.Color.accent)
        }
    }

    private var dayCountLabel: String {
        let cal = Calendar.current
        let s = cal.startOfDay(for: startDate)
        let e = cal.startOfDay(for: endDate)
        let days = max(1, (cal.dateComponents([.day], from: s, to: e).day ?? 0) + 1)
        return "\(days) day\(days == 1 ? "" : "s")"
    }
}

// MARK: - PersistentModelID <-> URI string

extension PersistentIdentifier {
    /// Encodes the identifier to a stable string for @AppStorage. The
    /// CloudKit-backed identifier supports `URIRepresentation` via
    /// `Codable`; we serialize through JSON to keep round-tripping
    /// straightforward.
    var encodedURIString: String {
        if let data = try? JSONEncoder().encode(self),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        return ""
    }

    static func decode(_ string: String) -> PersistentIdentifier? {
        guard !string.isEmpty,
              let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(PersistentIdentifier.self, from: data)
    }
}
