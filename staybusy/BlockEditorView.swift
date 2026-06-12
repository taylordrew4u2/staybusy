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
                VStack(alignment: .leading, spacing: 18) {
                    titleSection
                    categorySection
                    timeSection
                    locationSection
                    moreSection
                    if editing != nil { deleteButton }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background)
            .navigationTitle(editing == nil ? "New Block" : "Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .font(.system(.body, design: .rounded).weight(.heavy))
                        .foregroundStyle(canSave ? Theme.accent : Theme.textMuted)
                        .disabled(!canSave)
                }
            }
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .onAppear(perform: hydrate)
        .onChange(of: locationQuery) { _, newValue in
            if locationFocused {
                addressSearch.update(query: newValue)
            }
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
        }
        try? context.save()
        dismiss()
    }

    private func delete() {
        guard let b = editing else { return }
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
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("TITLE")
            TextField("e.g. Soundcheck", text: $title)
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
                .focused($titleFocused)
                .submitLabel(.done)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("CATEGORY")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("TIME")
            VStack(spacing: 12) {
                timeRow("STARTS") {
                    DatePicker("", selection: $start, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(Theme.accent)
                }
                timeRow("ENDS") {
                    DatePicker("", selection: $end, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(Theme.accent)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(durationOptions, id: \.self) { m in
                            DurationChip(minutes: m, isSelected: minutesBetween == m) {
                                applyDuration(m)
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
                if !timeIsValid {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("End must be after start")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(Theme.accent)
                }
            }
            .padding(14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("LOCATION (OPTIONAL)")
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundStyle(Theme.textSecondary)
                    TextField("Search address or place", text: $locationQuery)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .focused($locationFocused)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                    if !locationQuery.isEmpty {
                        Button(action: clearLocation) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.textMuted)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)

                if locationFocused && !addressSearch.results.isEmpty {
                    Divider().background(Theme.textMuted.opacity(0.2))
                    ForEach(
                        Array(addressSearch.results.prefix(5).enumerated()),
                        id: \.offset
                    ) { _, res in
                        Button {
                            Task { await selectLocation(res) }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(res.title)
                                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                                    .foregroundStyle(Theme.textPrimary)
                                if !res.subtitle.isEmpty {
                                    Text(res.subtitle)
                                        .font(.system(.caption, design: .rounded).weight(.medium))
                                        .foregroundStyle(Theme.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                    }
                } else if !address.isEmpty && address != locationQuery {
                    Divider().background(Theme.textMuted.opacity(0.2))
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(Theme.textMuted)
                        Text(address)
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3)) { showMore.toggle() }
            } label: {
                HStack {
                    sectionLabel("MORE")
                    Spacer()
                    Image(systemName: showMore ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .buttonStyle(.plain)

            if showMore {
                VStack(alignment: .leading, spacing: 14) {
                    confirmationField
                    notesField
                    linksField
                }
                .padding(14)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var confirmationField: some View {
        VStack(alignment: .leading, spacing: 6) {
            miniLabel("CONFIRMATION CODE")
            TextField("e.g. DL-AB12CD", text: $confirmationCode)
                .font(.system(.body, design: .rounded).weight(.semibold).monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.characters)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            miniLabel("NOTES")
            TextField("Add notes…", text: $notes, axis: .vertical)
                .lineLimit(3...8)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private var linksField: some View {
        VStack(alignment: .leading, spacing: 8) {
            miniLabel("LINKS")
            ForEach(Array(links.enumerated()), id: \.offset) { idx, link in
                HStack(spacing: 8) {
                    Image(systemName: "link")
                        .foregroundStyle(Theme.textSecondary)
                    Text(link)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button {
                        links.remove(at: idx)
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .foregroundStyle(Theme.accent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
            }
            HStack(spacing: 8) {
                TextField("https://", text: $newLink)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .onSubmit { addLink() }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
                Button(action: addLink) {
                    let isEmpty = newLink.trimmingCharacters(in: .whitespaces).isEmpty
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.accent.opacity(isEmpty ? 0.4 : 1))
                }
                .buttonStyle(.plain)
                .disabled(newLink.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive, action: delete) {
            HStack(spacing: 8) {
                Image(systemName: "trash.fill")
                Text("Delete block")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(Theme.accent)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption2, design: .rounded).weight(.heavy))
            .tracking(1.4)
            .foregroundStyle(Theme.textSecondary)
    }

    private func miniLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption2, design: .rounded).weight(.heavy))
            .tracking(1.2)
            .foregroundStyle(Theme.textMuted)
    }

    @ViewBuilder
    private func timeRow<Content: View>(_ text: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(text)
                .font(.system(.caption, design: .rounded).weight(.heavy))
                .tracking(1.0)
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 64, alignment: .leading)
            Spacer()
            content()
        }
    }
}

// MARK: - Chips

private struct CategoryChip: View {
    let category: BlockCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.symbol)
                    .font(.system(size: 12, weight: .heavy))
                Text(category.label)
                    .font(.system(.subheadline, design: .rounded).weight(.heavy))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                isSelected ? category.color : Theme.surface,
                in: Capsule()
            )
            .foregroundStyle(isSelected ? Color.white : Theme.textPrimary)
            .overlay {
                Capsule()
                    .stroke(category.color.opacity(isSelected ? 0 : 0.55), lineWidth: 1.2)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct DurationChip: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(.subheadline, design: .rounded).weight(.heavy).monospacedDigit())
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Theme.accent : Theme.surfaceElevated,
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? Color.white : Theme.textPrimary)
        }
        .buttonStyle(.plain)
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
