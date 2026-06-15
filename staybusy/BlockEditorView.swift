//
//  BlockEditorView.swift
//  staybusy
//

import SwiftUI
import SwiftData
import MapKit
import Observation

// MARK: - Editor

struct BlockEditorView: View {
    let editing: Block?
    let suggested: DateInterval?
    let defaultTrip: Trip?
    let onDelete: (() -> Void)?

    init(
        editing: Block?,
        suggested: DateInterval?,
        defaultTrip: Trip? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.editing = editing
        self.suggested = suggested
        self.defaultTrip = defaultTrip
        self.onDelete = onDelete
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title: String = ""
    @State private var category: BlockCategory = .work
    @State private var start: Date = Date()
    @State private var end: Date = Date().addingTimeInterval(3600)
    @State private var locationName: String = ""
    @State private var address: String = ""
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    @State private var confirmationCode: String = ""
    @State private var notes: String = ""
    @State private var links: [String] = []
    @State private var newLink: String = ""
    @State private var ticketDrafts: [TicketDraft] = []
    @State private var costText: String = ""
    @State private var currencyCode: String = "USD"
    @State private var phone: String = ""
    @State private var website: String = ""

    @State private var locationQuery: String = ""
    @State private var addressSearch = AddressSearch()
    @State private var showMore: Bool = false
    @State private var didHydrate: Bool = false
    @State private var showingDeleteConfirm: Bool = false

    @FocusState private var titleFocused: Bool
    @FocusState private var locationFocused: Bool

    private let durationOptions: [Int] = [15, 30, 45, 60, 90, 120]

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var timeIsValid: Bool { end > start }
    private var titleIsValid: Bool { !trimmedTitle.isEmpty }
    private var canSave: Bool { titleIsValid && timeIsValid }

    private var minutesBetween: Int {
        Int((end.timeIntervalSince(start) / 60).rounded())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    titleSection
                    categorySection
                    timeSection
                    locationSection
                    ticketsSection
                    moreSection
                    if editing != nil { deleteButton }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.Color.background)
            .navigationTitle(editing == nil ? "New Block" : "Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .font(Theme.Font.title)
                        .foregroundStyle(canSave ? Theme.Color.accent : Theme.Color.textTertiary)
                        .disabled(!canSave)
                }
            }
            .toolbarBackground(Theme.Color.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .appTheme()
        .tint(Theme.Color.accent)
        .onAppear(perform: hydrate)
        .onChange(of: locationQuery) { _, newValue in
            if locationFocused {
                addressSearch.update(query: newValue)
            }
        }
        .confirmationDialog(
            "Delete this block?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: delete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    // MARK: - Hydrate

    private func hydrate() {
        guard !didHydrate else { return }
        if let b = editing {
            title = b.title
            category = b.category
            start = b.start
            end = b.end
            locationName = b.locationName
            address = b.address
            latitude = b.latitude
            longitude = b.longitude
            confirmationCode = b.confirmationCode
            notes = b.notes
            links = b.links
            ticketDrafts = b.orderedTickets.map(TicketDraft.init(from:))
            costText = b.cost > 0 ? formatCost(b.cost) : ""
            currencyCode = b.currencyCode
            phone = b.phone
            website = b.website
            locationQuery = b.locationName
        } else if let s = suggested {
            start = s.start
            end = s.end
        }
        didHydrate = true
        if editing == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                titleFocused = true
            }
        }
    }

    // MARK: - Persist

    private func save() {
        guard canSave else { return }
        let isCreate = editing == nil
        let resultBlock: Block
        let parsedCost = parseCost(costText)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedWebsite = website.trimmingCharacters(in: .whitespacesAndNewlines)
        if let b = editing {
            b.title = trimmedTitle
            b.start = start
            b.end = end
            b.category = category
            b.locationName = locationName
            b.address = address
            b.latitude = latitude
            b.longitude = longitude
            b.confirmationCode = confirmationCode
            b.notes = notes
            b.links = links
            b.cost = parsedCost
            b.currencyCode = currencyCode
            b.phone = trimmedPhone
            b.website = trimmedWebsite
            resultBlock = b
        } else {
            let new = Block(
                title: trimmedTitle,
                start: start,
                end: end,
                category: category,
                locationName: locationName,
                address: address,
                latitude: latitude,
                longitude: longitude,
                confirmationCode: confirmationCode,
                notes: notes,
                links: links,
                cost: parsedCost,
                currencyCode: currencyCode,
                phone: trimmedPhone,
                website: trimmedWebsite
            )
            context.insert(new)
            // Auto-associate with the trip the editor was opened from
            // so it appears in that trip's agenda without the user
            // having to manually file it.
            if let defaultTrip {
                new.trip = defaultTrip
            }
            resultBlock = new
        }
        syncTickets(into: resultBlock)
        try? context.save()
        Theme.Haptic.blockSaved()
        Task {
            if isCreate {
                await NotificationManager.shared.blockCreated(resultBlock)
            } else {
                await NotificationManager.shared.blockUpdated(resultBlock)
            }
        }
        dismiss()
    }

    private func delete() {
        guard let b = editing else { return }
        NotificationManager.shared.blockDeleted(b)
        onDelete?()
        dismiss()
        let ctx = context
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            ctx.delete(b)
            try? ctx.save()
        }
    }

    private func applyDuration(_ minutes: Int) {
        end = start.addingTimeInterval(TimeInterval(minutes * 60))
    }

    private func parseCost(_ text: String) -> Double {
        let cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(cleaned) ?? 0
    }

    private func formatCost(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
    }

    private func addLink() {
        let trimmed = newLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        links.append(trimmed)
        newLink = ""
    }

    // MARK: - Tickets

    private func addTicket() {
        ticketDrafts.append(TicketDraft())
    }

    private func removeTicket(at offset: Int) {
        guard ticketDrafts.indices.contains(offset) else { return }
        ticketDrafts.remove(at: offset)
    }

    /// Replace the block's tickets with the current drafts. Empty drafts
    /// are dropped (the user added a row and didn't fill it in). The
    /// simplest correct path: delete every existing ticket and insert
    /// fresh ones in the drafts' order — tickets are cheap, cascading
    /// from Block, and this avoids per-field diffing.
    private func syncTickets(into block: Block) {
        for existing in block.tickets ?? [] {
            context.delete(existing)
        }
        let kept = ticketDrafts.filter { !$0.isEmpty }
        block.tickets = []
        for (idx, draft) in kept.enumerated() {
            let ticket = Ticket(
                name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                confirmationCode: draft.confirmationCode
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                seat: draft.seat.trimmingCharacters(in: .whitespacesAndNewlines),
                gate: draft.gate.trimmingCharacters(in: .whitespacesAndNewlines),
                holderName: draft.holderName
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                sortOrder: idx
            )
            ticket.block = block
            context.insert(ticket)
        }
    }

    @MainActor
    private func selectLocation(_ result: MKLocalSearchCompletion) async {
        let resolved = await addressSearch.resolve(result)
        locationName = resolved.name
        address = resolved.address
        latitude = resolved.latitude
        longitude = resolved.longitude
        locationQuery = resolved.name
        locationFocused = false
    }

    private func clearLocation() {
        locationQuery = ""
        locationName = ""
        address = ""
        latitude = nil
        longitude = nil
        addressSearch.results = []
    }

    // MARK: - Sections

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionLabel("TITLE")
            TextField("e.g. Soundcheck", text: $title)
                .font(Theme.Font.titleLarge)
                .foregroundStyle(Theme.Color.textPrimary)
                .focused($titleFocused)
                .submitLabel(.done)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.m)
                .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionLabel("CATEGORY")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.s) {
                    ForEach(BlockCategory.allCases) { c in
                        CategoryChip(category: c, isSelected: c == category) {
                            category = c
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionLabel("TIME")
            VStack(spacing: Theme.Spacing.m) {
                timeRow("STARTS") {
                    DatePicker("", selection: $start, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(Theme.Color.accent)
                }
                timeRow("ENDS") {
                    DatePicker("", selection: $end, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(Theme.Color.accent)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.s) {
                        ForEach(durationOptions, id: \.self) { m in
                            DurationChip(minutes: m, isSelected: minutesBetween == m) {
                                applyDuration(m)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
                if !timeIsValid {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("End must be after start")
                            .font(Theme.Font.caption)
                    }
                    .foregroundStyle(Theme.Color.warning)
                }
                if looksLikeAirportDraft {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "airplane.departure")
                            .font(Theme.Font.caption)
                        Text(airportLabel)
                            .font(Theme.Font.caption)
                    }
                    .foregroundStyle(Theme.Color.accent)
                    .padding(.horizontal, Theme.Spacing.s)
                    .padding(.vertical, 4)
                    .background(
                        Theme.Color.accent.opacity(0.15),
                        in: Capsule()
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(Theme.Spacing.m)
            .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
    }

    /// Lightweight mirror of NotificationManager's airport detection,
    /// reading from the editor's local draft state so the hint updates
    /// live as the user fills in fields.
    private var looksLikeAirportDraft: Bool {
        guard category == .travel else { return false }
        if ticketDrafts.contains(where: { !$0.gate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
            return true
        }
        let lowered = (title + " " + locationName + " " + notes).lowercased()
        let signals = ["airport", "flight", "fly ", "boarding", "gate", "departure"]
        return signals.contains { lowered.contains($0) }
    }

    private var airportLabel: String {
        let lowered = (title + " " + locationName + " " + notes).lowercased()
        let isIntl = ["international", "intl ", "customs", "passport"]
            .contains { lowered.contains($0) }
        return isIntl
            ? "Airport departure — you'll be reminded 3h ahead"
            : "Airport departure — you'll be reminded 2h ahead"
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionLabel("LOCATION (OPTIONAL)")
            VStack(spacing: 0) {
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.textSecondary)
                    TextField("Search address or place", text: $locationQuery)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .focused($locationFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    if !locationQuery.isEmpty {
                        Button(action: clearLocation) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.Color.textTertiary)
                                .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.pressable)
                        .accessibilityLabel("Clear location")
                    }
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)

                if locationFocused && !addressSearch.results.isEmpty {
                    Divider().background(Theme.Color.textTertiary.opacity(0.2))
                    ForEach(
                        Array(addressSearch.results.prefix(5).enumerated()),
                        id: \.offset
                    ) { _, res in
                        Button {
                            Task { await selectLocation(res) }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(res.title)
                                    .font(Theme.Font.body)
                                    .foregroundStyle(Theme.Color.textPrimary)
                                if !res.subtitle.isEmpty {
                                    Text(res.subtitle)
                                        .font(Theme.Font.caption)
                                        .foregroundStyle(Theme.Color.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.vertical, Theme.Spacing.s)
                            .frame(minHeight: Theme.Size.minTapTarget)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.pressable)
                    }
                } else if !address.isEmpty && address != locationQuery {
                    Divider().background(Theme.Color.textTertiary.opacity(0.2))
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Theme.Color.textTertiary)
                        Text(address)
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.s)
                }
            }
            .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
    }

    private var ticketsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                sectionLabel("TICKETS (OPTIONAL)")
                Spacer()
                if !ticketDrafts.isEmpty {
                    Text("\(ticketDrafts.count)")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textTertiary)
                }
            }

            VStack(spacing: Theme.Spacing.m) {
                ForEach(Array(ticketDrafts.enumerated()), id: \.element.id) { idx, _ in
                    TicketEditorCard(
                        draft: $ticketDrafts[idx],
                        index: idx,
                        onRemove: { removeTicket(at: idx) }
                    )
                }

                Button(action: addTicket) {
                    HStack(spacing: Theme.Spacing.s) {
                        Image(systemName: "plus.circle.fill")
                            .font(Theme.Font.title)
                        Text(ticketDrafts.isEmpty ? "Add a ticket" : "Add another ticket")
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
                .accessibilityLabel("Add a ticket")
            }
        }
    }

    private var moreSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Button {
                withAnimation(Theme.Motion.snap()) { showMore.toggle() }
            } label: {
                HStack {
                    sectionLabel("MORE")
                    Spacer()
                    Image(systemName: showMore ? "chevron.up" : "chevron.down")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                .frame(minHeight: Theme.Size.minTapTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)

            if showMore {
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    costField
                    contactFields
                    confirmationField
                    notesField
                    linksField
                }
                .padding(Theme.Spacing.m)
                .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
            }
        }
    }

    private var costField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            miniLabel("COST")
            HStack(spacing: Theme.Spacing.s) {
                Text(currencySymbol)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textTertiary)
                    .frame(width: 18, alignment: .center)
                TextField("0", text: $costText)
                    .keyboardType(.decimalPad)
                    .font(Theme.Font.body.monospacedDigit())
                    .foregroundStyle(Theme.Color.textPrimary)
                    .frame(maxWidth: .infinity)
                Menu {
                    ForEach(supportedCurrencies, id: \.self) { code in
                        Button {
                            currencyCode = code
                        } label: {
                            if code == currencyCode {
                                Label(code, systemImage: "checkmark")
                            } else {
                                Text(code)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(currencyCode)
                            .font(Theme.Font.caption)
                            .foregroundStyle(Theme.Color.textSecondary)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(Theme.Color.textTertiary)
                    }
                    .padding(.horizontal, Theme.Spacing.s)
                    .padding(.vertical, 4)
                    .background(
                        Theme.Color.surface,
                        in: Capsule()
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.m)
            .padding(.vertical, Theme.Spacing.s)
            .background(
                Theme.Color.surfaceElevated,
                in: RoundedRectangle(cornerRadius: Theme.Radius.small)
            )
        }
    }

    private var contactFields: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                miniLabel("PHONE")
                TextField("e.g. (212) 555-1234", text: $phone)
                    .keyboardType(.phonePad)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.s)
                    .background(
                        Theme.Color.surfaceElevated,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.small)
                    )
            }
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                miniLabel("WEBSITE")
                TextField("e.g. brooklynsteel.com", text: $website)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.s)
                    .background(
                        Theme.Color.surfaceElevated,
                        in: RoundedRectangle(cornerRadius: Theme.Radius.small)
                    )
            }
        }
    }

    private var currencySymbol: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        return f.currencySymbol ?? "$"
    }

    private var supportedCurrencies: [String] {
        ["USD", "EUR", "GBP", "JPY", "CAD", "AUD", "MXN", "CHF"]
    }

    private var confirmationField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            miniLabel("CONFIRMATION CODE")
            TextField("e.g. DL-AB12CD", text: $confirmationCode)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .background(Theme.Color.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.Radius.small))
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            miniLabel("NOTES")
            TextField("Add notes…", text: $notes, axis: .vertical)
                .lineLimit(3...8)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .background(Theme.Color.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.Radius.small))
        }
    }

    private var linksField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            miniLabel("LINKS")
            ForEach(Array(links.enumerated()), id: \.offset) { idx, link in
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: "link")
                        .foregroundStyle(Theme.Color.textSecondary)
                    Text(link)
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button {
                        links.remove(at: idx)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Theme.Color.warning)
                            .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("Remove link")
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Color.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.Radius.small))
            }
            HStack(spacing: Theme.Spacing.s) {
                TextField("https://", text: $newLink)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .onSubmit { addLink() }
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.s)
                    .background(Theme.Color.surfaceElevated, in: RoundedRectangle(cornerRadius: Theme.Radius.small))
                Button(action: addLink) {
                    let isEmpty = newLink.trimmingCharacters(in: .whitespaces).isEmpty
                    Image(systemName: "plus.circle.fill")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.accent.opacity(isEmpty ? 0.4 : 1))
                        .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .disabled(newLink.trimmingCharacters(in: .whitespaces).isEmpty)
                .accessibilityLabel("Add link")
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            showingDeleteConfirm = true
        } label: {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: "trash.fill")
                Text("Delete block")
                    .font(Theme.Font.title)
            }
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
            .padding(.vertical, Theme.Spacing.s)
            .background(Theme.Color.accent.opacity(0.18), in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .foregroundStyle(Theme.Color.accent)
        }
        .buttonStyle(.pressable)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.caption)
            .tracking(1.4)
            .foregroundStyle(Theme.Color.textSecondary)
    }

    private func miniLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.caption)
            .tracking(1.2)
            .foregroundStyle(Theme.Color.textTertiary)
    }

    @ViewBuilder
    private func timeRow<Content: View>(_ text: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(text)
                .font(Theme.Font.caption)
                .tracking(1.0)
                .foregroundStyle(Theme.Color.textSecondary)
                .frame(width: 64, alignment: .leading)
            Spacer()
            content()
        }
    }
}

// MARK: - Duration chip

private struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Font.body.monospacedDigit())
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .frame(minHeight: Theme.Size.minTapTarget)
                .background(
                    isSelected ? Theme.Color.accent : Theme.Color.surfaceElevated,
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? Color.white : Theme.Color.textPrimary)
        }
        .buttonStyle(.pressable)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var label: String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            if m == 0 { return "\(h)h" }
            return "\(h)h \(m)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Address search

@Observable
final class AddressSearch: NSObject, MKLocalSearchCompleterDelegate {
    var results: [MKLocalSearchCompletion] = []

    @ObservationIgnored private let completer: MKLocalSearchCompleter

    override init() {
        self.completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func update(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            results = []
            return
        }
        completer.queryFragment = trimmed
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        results = []
    }

    func resolve(
        _ completion: MKLocalSearchCompletion
    ) async -> (name: String, address: String, latitude: Double?, longitude: Double?) {
        let request = MKLocalSearch.Request(completion: completion)
        do {
            let response = try await MKLocalSearch(request: request).start()
            if let item = response.mapItems.first {
                let name = item.name ?? completion.title
                let addr = formatAddress(from: item.placemark, fallback: completion.subtitle)
                let coord = item.placemark.coordinate
                return (name, addr, coord.latitude, coord.longitude)
            }
        } catch {
            // Network or routing failures fall through to the completion text.
        }
        return (completion.title, completion.subtitle, nil, nil)
    }

    private func formatAddress(from placemark: MKPlacemark, fallback: String) -> String {
        var parts: [String] = []
        let street = [placemark.subThoroughfare, placemark.thoroughfare]
            .compactMap { $0 }
            .joined(separator: " ")
        if !street.isEmpty { parts.append(street) }
        if let locality = placemark.locality, !locality.isEmpty { parts.append(locality) }
        if let admin = placemark.administrativeArea, !admin.isEmpty { parts.append(admin) }
        return parts.isEmpty ? fallback : parts.joined(separator: ", ")
    }
}

// MARK: - Ticket draft + editor card

struct TicketDraft: Identifiable, Equatable {
    let id: UUID
    var name: String
    var confirmationCode: String
    var seat: String
    var gate: String
    var holderName: String

    init(
        id: UUID = UUID(),
        name: String = "",
        confirmationCode: String = "",
        seat: String = "",
        gate: String = "",
        holderName: String = ""
    ) {
        self.id = id
        self.name = name
        self.confirmationCode = confirmationCode
        self.seat = seat
        self.gate = gate
        self.holderName = holderName
    }

    init(from ticket: Ticket) {
        self.init(
            name: ticket.name,
            confirmationCode: ticket.confirmationCode,
            seat: ticket.seat,
            gate: ticket.gate,
            holderName: ticket.holderName
        )
    }

    var isEmpty: Bool {
        name.isEmpty
            && confirmationCode.isEmpty
            && seat.isEmpty
            && gate.isEmpty
            && holderName.isEmpty
    }
}

private struct TicketEditorCard: View {
    @Binding var draft: TicketDraft
    let index: Int
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack {
                Text("TICKET \(index + 1)")
                    .font(Theme.Font.caption)
                    .tracking(1.2)
                    .foregroundStyle(Theme.Color.textTertiary)
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.warning)
                        .frame(
                            width: Theme.Size.minTapTarget,
                            height: Theme.Size.minTapTarget
                        )
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("Remove ticket \(index + 1)")
            }

            field("LABEL", placeholder: "e.g. Boarding pass") {
                TextField("e.g. Boarding pass", text: $draft.name)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
            }

            field("CONFIRMATION CODE", placeholder: "e.g. DL-AB12CD") {
                TextField("e.g. DL-AB12CD", text: $draft.confirmationCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }

            HStack(spacing: Theme.Spacing.s) {
                field("SEAT") {
                    TextField("12A", text: $draft.seat)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                field("GATE") {
                    TextField("B23", text: $draft.gate)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
            }

            field("HOLDER (OPTIONAL)") {
                TextField("Name on ticket", text: $draft.holderName)
                    .textInputAutocapitalization(.words)
            }
        }
        .padding(Theme.Spacing.m)
        .background(
            Theme.Color.surface,
            in: RoundedRectangle(cornerRadius: Theme.Radius.medium)
        )
    }

    @ViewBuilder
    private func field<Content: View>(
        _ label: String,
        placeholder: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.Font.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.Color.textTertiary)
            content()
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.s)
                .background(
                    Theme.Color.surfaceElevated,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.small)
                )
        }
    }
}

#Preview("Edit Block") {
    let container = try! ModelContainer(
        for: Block.self, Ticket.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    SampleData.seedIfNeeded(context: container.mainContext)
    let descriptor = FetchDescriptor<Block>(sortBy: [SortDescriptor(\.start)])
    let block = (try? container.mainContext.fetch(descriptor))?
        .first(where: { !$0.orderedTickets.isEmpty })
    return BlockEditorView(editing: block, suggested: nil)
        .modelContainer(container)
}

#Preview("New Block") {
    BlockEditorView(editing: nil, suggested: DateInterval(start: .now, duration: 3600))
        .modelContainer(for: Block.self, inMemory: true)
}
