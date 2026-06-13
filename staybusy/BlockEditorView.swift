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
    let onDelete: (() -> Void)?

    init(
        editing: Block?,
        suggested: DateInterval?,
        onDelete: (() -> Void)? = nil
    ) {
        self.editing = editing
        self.suggested = suggested
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
        .preferredColorScheme(.dark)
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
                links: links
            )
            context.insert(new)
            resultBlock = new
        }
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

    private func addLink() {
        let trimmed = newLink.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        links.append(trimmed)
        newLink = ""
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
            }
            .padding(Theme.Spacing.m)
            .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
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
                    confirmationField
                    notesField
                    linksField
                }
                .padding(Theme.Spacing.m)
                .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
            }
        }
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

#Preview("New Block") {
    BlockEditorView(editing: nil, suggested: DateInterval(start: .now, duration: 3600))
        .modelContainer(for: Block.self, inMemory: true)
}
