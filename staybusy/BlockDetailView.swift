//
//  BlockDetailView.swift
//  staybusy
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import PhotosUI
import PDFKit
import UniformTypeIdentifiers
import Observation
import UIKit

// MARK: - Detail view

/// Drives the inline ticket editor sheet from BlockDetailView — `.new`
/// creates a fresh ticket on the parent block, `.edit(_:)` opens an
/// existing one for changes or deletion. `Identifiable` so it pairs
/// with `.sheet(item:)`.
enum TicketSheetMode: Identifiable {
    case new
    case edit(Ticket)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let t): return "edit-\(t.persistentModelID.hashValue)"
        }
    }
}

struct BlockDetailView: View {
    let block: Block
    let onEdit: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var attachmentURLs: [URL] = []
    @State private var photosSelection: [PhotosPickerItem] = []
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    @State private var showFilesPicker = false
    @State private var fullScreenSelection: IndexBox?
    @State private var leaveByModel = LeaveByModel()
    @State private var copiedCode = false
    @State private var copiedTicketID: PersistentIdentifier?
    @State private var ticketSheet: TicketSheetMode?

    private var blockCoordinate: CLLocationCoordinate2D? {
        guard let lat = block.latitude, let lng = block.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                if !attachmentURLs.isEmpty {
                    attachmentsCarousel
                }
                ingestionButtons
                ticketsSection
                if !block.confirmationCode.isEmpty {
                    confirmationSection
                }
                if !block.links.isEmpty {
                    linksSection
                }
                infoSection
                if let coord = blockCoordinate {
                    mapSection(coord)
                    DirectionsButtonRow(
                        coordinate: coord,
                        destinationName: block.locationName.isEmpty ? "Destination" : block.locationName,
                        layout: .stacked
                    )
                    leaveBySection(coord)
                }
            }
            .padding(Theme.Spacing.l)
        }
        .scrollIndicators(.hidden)
        .background(Theme.Color.background.ignoresSafeArea())
        .navigationTitle(block.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: onEdit)
                    .foregroundStyle(Theme.Color.accent)
                    .font(Theme.Font.title)
            }
        }
        .toolbarBackground(Theme.Color.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .appTheme()
        .tint(Theme.Color.accent)
        .sheet(item: $ticketSheet) { mode in
            switch mode {
            case .new:
                TicketEditorSheet(block: block, editing: nil)
            case .edit(let ticket):
                TicketEditorSheet(block: block, editing: ticket)
            }
        }
        .onAppear {
            attachmentURLs = AttachmentStore.urls(for: block.attachmentFilenames)
            if let coord = blockCoordinate {
                leaveByModel.start(target: coord, arriveBy: block.start)
            }
        }
        .onChange(of: block.attachmentFilenames) { _, names in
            attachmentURLs = AttachmentStore.urls(for: names)
        }
        .onChange(of: leaveByModel.state) { _, newState in
            if case .ready(let leaveBy, _) = newState {
                Task {
                    await NotificationManager.shared.registerLeaveBy(leaveBy, for: block)
                }
            }
        }
        .photosPicker(
            isPresented: $showPhotosPicker,
            selection: $photosSelection,
            matching: .images
        )
        .onChange(of: photosSelection) { _, items in
            guard !items.isEmpty else { return }
            Task { await importFromPhotos(items) }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                showCamera = false
                if let img = image {
                    saveCameraImage(img)
                }
            }
            .ignoresSafeArea()
        }
        .fileImporter(
            isPresented: $showFilesPicker,
            allowedContentTypes: [.image, .pdf],
            allowsMultipleSelection: true,
            onCompletion: handleFilesImporter
        )
        .fullScreenCover(item: $fullScreenSelection) { box in
            FullScreenAttachmentView(urls: attachmentURLs, initialIndex: box.value)
        }
    }

    // MARK: - Attachments carousel

    private var attachmentsCarousel: some View {
        TabView {
            ForEach(Array(attachmentURLs.enumerated()), id: \.offset) { idx, url in
                AttachmentThumbnailView(url: url)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        fullScreenSelection = IndexBox(value: idx)
                    }
                    .tag(idx)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: attachmentURLs.count > 1 ? .always : .never))
        .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        .frame(height: 300)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    // MARK: - Ingestion buttons

    private var ingestionButtons: some View {
        HStack(spacing: Theme.Spacing.s) {
            ingestButton("Camera", "camera.fill") { showCamera = true }
            ingestButton("Photos", "photo.on.rectangle") { showPhotosPicker = true }
            ingestButton("Files", "doc.fill") { showFilesPicker = true }
        }
    }

    private func ingestButton(
        _ title: String,
        _ symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xs) {
                Image(systemName: symbol)
                    .font(Theme.Font.title)
                Text(title)
                    .font(Theme.Font.caption)
            }
            .frame(maxWidth: .infinity, minHeight: Theme.Size.minTapTarget)
            .padding(.vertical, Theme.Spacing.m)
            .foregroundStyle(Theme.Color.textPrimary)
            .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(title)
    }

    private func importFromPhotos(_ items: [PhotosPickerItem]) async {
        var newNames: [String] = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let url = AttachmentStore.save(data: data, extension: "jpg") {
                newNames.append(url.lastPathComponent)
            }
        }
        await MainActor.run {
            if !newNames.isEmpty {
                var current = block.attachmentFilenames
                current.append(contentsOf: newNames)
                block.attachmentFilenames = current
            }
            photosSelection = []
        }
    }

    private func saveCameraImage(_ img: UIImage) {
        guard let data = img.jpegData(compressionQuality: 0.85) else { return }
        if let url = AttachmentStore.save(data: data, extension: "jpg") {
            var current = block.attachmentFilenames
            current.append(url.lastPathComponent)
            block.attachmentFilenames = current
        }
    }

    private func handleFilesImporter(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result else { return }
        var newNames: [String] = []
        for src in urls {
            let didAccess = src.startAccessingSecurityScopedResource()
            defer { if didAccess { src.stopAccessingSecurityScopedResource() } }
            if let dest = AttachmentStore.copy(from: src) {
                newNames.append(dest.lastPathComponent)
            }
        }
        if !newNames.isEmpty {
            var current = block.attachmentFilenames
            current.append(contentsOf: newNames)
            block.attachmentFilenames = current
        }
    }

    // MARK: - Confirmation code

    // MARK: - Tickets

    private var ticketsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .firstTextBaseline) {
                sectionLabel("TICKETS")
                Spacer()
                if !block.orderedTickets.isEmpty {
                    Text("\(block.orderedTickets.count)")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textTertiary)
                }
            }

            if !block.orderedTickets.isEmpty {
                VStack(spacing: Theme.Spacing.s) {
                    ForEach(block.orderedTickets, id: \.persistentModelID) { ticket in
                        TicketCard(
                            ticket: ticket,
                            category: block.category,
                            isCopied: copiedTicketID == ticket.persistentModelID,
                            onCopy: { copyTicket(ticket) },
                            onEdit: { ticketSheet = .edit(ticket) }
                        )
                    }
                }
            }

            Button {
                ticketSheet = .new
            } label: {
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: "plus.circle.fill")
                        .font(Theme.Font.title)
                    Text(block.orderedTickets.isEmpty ? "Add a ticket" : "Add another ticket")
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

    private func copyTicket(_ ticket: Ticket) {
        let code = ticket.confirmationCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { return }
        UIPasteboard.general.string = code
        Theme.Haptic.codeCopied()
        let id = ticket.persistentModelID
        withAnimation(Theme.Motion.snap(reduceMotion: reduceMotion)) {
            copiedTicketID = id
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                if copiedTicketID == id {
                    withAnimation(Theme.Motion.snap(reduceMotion: reduceMotion)) {
                        copiedTicketID = nil
                    }
                }
            }
        }
    }

    private var confirmationSection: some View {
        Button {
            UIPasteboard.general.string = block.confirmationCode
            Theme.Haptic.codeCopied()
            withAnimation(Theme.Motion.snap(reduceMotion: reduceMotion)) { copiedCode = true }
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    withAnimation(Theme.Motion.snap(reduceMotion: reduceMotion)) { copiedCode = false }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack {
                    Text("CONFIRMATION CODE")
                        .font(Theme.Font.caption)
                        .tracking(1.4)
                        .foregroundStyle(Theme.Color.textSecondary)
                    Spacer()
                    Text(copiedCode ? "COPIED" : "TAP TO COPY")
                        .font(Theme.Font.caption)
                        .tracking(1.0)
                        .foregroundStyle(copiedCode ? Color.white : Theme.Color.accent)
                        .padding(.horizontal, Theme.Spacing.s)
                        .padding(.vertical, 3)
                        .background(
                            copiedCode ? Theme.Color.accent : Theme.Color.accent.opacity(0.18),
                            in: Capsule()
                        )
                }
                Text(block.confirmationCode)
                    .font(Theme.Font.codeHuge)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(Theme.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
        .buttonStyle(.pressable)
        .accessibilityLabel("Confirmation code \(block.confirmationCode)")
        .accessibilityHint(copiedCode ? "Copied" : "Double tap to copy")
    }

    // MARK: - Links

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            sectionLabel("LINKS")
            VStack(spacing: Theme.Spacing.s) {
                ForEach(Array(block.links.enumerated()), id: \.offset) { _, urlString in
                    if let url = makeURL(urlString) {
                        Link(destination: url) {
                            HStack(spacing: Theme.Spacing.s) {
                                Image(systemName: "safari.fill")
                                    .foregroundStyle(Theme.Color.accent)
                                    .font(Theme.Font.title)
                                Text(urlString)
                                    .font(Theme.Font.body)
                                    .foregroundStyle(Theme.Color.textPrimary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .foregroundStyle(Theme.Color.textSecondary)
                                    .font(Theme.Font.caption)
                            }
                            .padding(.horizontal, Theme.Spacing.m)
                            .padding(.vertical, Theme.Spacing.m)
                            .frame(minHeight: Theme.Size.minTapTarget)
                            .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
                        }
                    }
                }
            }
        }
    }

    private func makeURL(_ s: String) -> URL? {
        var input = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return nil }
        if !input.contains("://") { input = "https://" + input }
        return URL(string: input)
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.Radius.small)
                        .fill(block.category.color.opacity(0.18))
                        .frame(width: 30, height: 30)
                    Image(systemName: block.category.symbol)
                        .font(Theme.Font.caption)
                        .foregroundStyle(block.category.textOnSurface)
                }
                Text(block.category.label.uppercased())
                    .font(Theme.Font.caption)
                    .tracking(1.3)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
            Text(timeRangeString)
                .font(Theme.Font.title.monospacedDigit())
                .foregroundStyle(Theme.Color.textPrimary)
            if !block.locationName.isEmpty {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(Theme.Color.textSecondary)
                    Text(block.locationName)
                        .font(Theme.Font.body)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
            }
            if !block.address.isEmpty {
                Text(block.address)
                    .font(Theme.Font.caption)
                    .foregroundStyle(Theme.Color.textTertiary)
            }
            if hasContactRow {
                contactRow
                    .padding(.top, Theme.Spacing.xs)
            }
            if !block.notes.isEmpty {
                Text(block.notes)
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textPrimary)
                    .padding(.top, Theme.Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.l)
        .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
    }

    private var hasContactRow: Bool {
        block.cost > 0 || !block.phone.isEmpty || !block.website.isEmpty
    }

    private var contactRow: some View {
        FlowRow(spacing: Theme.Spacing.s) {
            if block.cost > 0 {
                Chip(
                    symbol: "creditcard.fill",
                    label: costLabel,
                    accentTint: true
                )
            }
            if !block.phone.isEmpty, let phoneURL = phoneURL {
                Link(destination: phoneURL) {
                    Chip(symbol: "phone.fill", label: block.phone)
                }
            }
            if !block.website.isEmpty, let websiteURL = websiteURL {
                Link(destination: websiteURL) {
                    Chip(symbol: "safari.fill", label: prettyDomain(block.website))
                }
            }
        }
    }

    private var costLabel: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = block.currencyCode
        f.maximumFractionDigits = block.cost.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return f.string(from: NSNumber(value: block.cost)) ?? "\(block.cost)"
    }

    private var phoneURL: URL? {
        let digits = block.phone.filter { $0.isNumber || $0 == "+" }
        return URL(string: "tel:\(digits)")
    }

    private var websiteURL: URL? {
        var s = block.website.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if !s.contains("://") { s = "https://" + s }
        return URL(string: s)
    }

    private func prettyDomain(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.replacingOccurrences(of: "https://", with: "")
        s = s.replacingOccurrences(of: "http://", with: "")
        if s.hasPrefix("www.") { s.removeFirst(4) }
        if let slash = s.firstIndex(of: "/") { s = String(s[..<slash]) }
        return s
    }

    private var timeRangeString: String {
        let day = DateFormatter()
        day.dateFormat = "EEE, MMM d"
        let time = DateFormatter()
        time.dateFormat = "h:mm a"
        return "\(day.string(from: block.start)) · \(time.string(from: block.start)) – \(time.string(from: block.end))"
    }

    // MARK: - Map

    private func mapSection(_ coord: CLLocationCoordinate2D) -> some View {
        Map(
            initialPosition: .region(MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )),
            interactionModes: []
        ) {
            Marker(
                block.locationName.isEmpty ? "Destination" : block.locationName,
                coordinate: coord
            )
            .tint(Theme.Color.accent)
        }
        .mapStyle(.standard(elevation: .flat))
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .allowsHitTesting(false)
    }

    // MARK: - Leave by

    private func leaveBySection(_ coord: CLLocationCoordinate2D) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            sectionLabel("LEAVE BY")
            leaveByContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.m)
                .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        }
    }

    @ViewBuilder
    private var leaveByContent: some View {
        switch leaveByModel.state {
        case .idle:
            iconRow("location.fill", "Preparing…", iconTint: Theme.Color.textSecondary)
        case .requestingPermission:
            iconRow(
                "location.fill",
                "Allow location to compute travel time",
                iconTint: Theme.Color.textSecondary
            )
        case .computing:
            HStack(spacing: Theme.Spacing.s) {
                ProgressView()
                    .tint(Theme.Color.textSecondary)
                Text("Calculating ETA…")
                    .font(Theme.Font.body)
                    .foregroundStyle(Theme.Color.textSecondary)
            }
        case .denied:
            iconRow(
                "location.slash.fill",
                "Enable location in Settings to see Leave by",
                iconTint: Theme.Color.textSecondary
            )
        case .ready(let leaveBy, let eta):
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Leave by \(formatTime(leaveBy))")
                        .font(Theme.Font.titleLarge.monospacedDigit())
                        .foregroundStyle(Theme.Color.textPrimary)
                    Text("\(formatDuration(eta)) drive · 10 min buffer")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                }
                Spacer()
                Image(systemName: "car.fill")
                    .font(Theme.Font.title)
                    .foregroundStyle(Theme.Color.accent)
            }
        case .stale:
            iconRow(
                "exclamationmark.triangle.fill",
                "ETA unavailable — couldn't reach Apple Maps",
                iconTint: Theme.Color.warning
            )
        }
    }

    private func iconRow(
        _ symbol: String,
        _ text: String,
        iconTint: Color
    ) -> some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: symbol)
                .foregroundStyle(iconTint)
            Text(text)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textSecondary)
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let total = Int(interval / 60)
        let h = total / 60
        let m = total % 60
        if h > 0 && m > 0 { return "\(h)h \(m)m" }
        if h > 0 { return "\(h)h" }
        return "\(m)m"
    }

    // MARK: - Section label

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.Font.caption)
            .tracking(1.4)
            .foregroundStyle(Theme.Color.textSecondary)
    }
}

// MARK: - Identifiable box for fullScreenCover

private struct IndexBox: Identifiable {
    let value: Int
    var id: Int { value }
}

// MARK: - Attachment thumbnail

private struct AttachmentThumbnailView: View {
    let url: URL
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            Color.black
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .task(id: url) {
            image = await AttachmentStore.thumbnail(for: url)
        }
    }
}

// MARK: - Full-screen viewer

private struct FullScreenAttachmentView: View {
    let urls: [URL]
    let initialIndex: Int
    @State private var index: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(urls: [URL], initialIndex: Int) {
        self.urls = urls
        self.initialIndex = initialIndex
        _index = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            TabView(selection: $index) {
                ForEach(Array(urls.enumerated()), id: \.offset) { idx, url in
                    ZoomableAttachmentView(url: url)
                        .tag(idx)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: urls.count > 1 ? .always : .never))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(Theme.Font.titleLarge)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.6))
                    .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                    .padding(Theme.Spacing.l)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Close")
        }
        .preferredColorScheme(.dark)
    }
}

private struct ZoomableAttachmentView: View {
    let url: URL
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(zoomGesture)
                    .simultaneousGesture(panGesture)
                    .onTapGesture(count: 2) {
                        withAnimation(Theme.Motion.snap(reduceMotion: reduceMotion)) { reset() }
                    }
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .task(id: url) {
            image = await AttachmentStore.thumbnail(for: url)
        }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = max(1, min(5, lastScale * value))
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private func reset() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }
}

// MARK: - Camera picker

private struct CameraPicker: UIViewControllerRepresentable {
    let onResult: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
        } else {
            picker.sourceType = .photoLibrary
        }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onResult: onResult)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onResult: (UIImage?) -> Void

        init(onResult: @escaping (UIImage?) -> Void) {
            self.onResult = onResult
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            onResult(info[.originalImage] as? UIImage)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onResult(nil)
        }
    }
}

// MARK: - Attachment storage

enum AttachmentStore {
    static var documentsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
    }

    static func urls(for filenames: [String]) -> [URL] {
        filenames.map { documentsDir.appendingPathComponent($0) }
    }

    static func save(data: Data, extension ext: String) -> URL? {
        let name = "\(UUID().uuidString).\(ext)"
        let dest = documentsDir.appendingPathComponent(name)
        do {
            try data.write(to: dest, options: .atomic)
            return dest
        } catch {
            return nil
        }
    }

    static func copy(from src: URL) -> URL? {
        let ext = src.pathExtension.isEmpty ? "dat" : src.pathExtension
        let name = "\(UUID().uuidString).\(ext)"
        let dest = documentsDir.appendingPathComponent(name)
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: src, to: dest)
            return dest
        } catch {
            return nil
        }
    }

    static func thumbnail(for url: URL) async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            guard FileManager.default.fileExists(atPath: url.path) else { return nil }
            let ext = url.pathExtension.lowercased()
            if ext == "pdf" {
                guard let doc = PDFDocument(url: url), let page = doc.page(at: 0) else { return nil }
                let bounds = page.bounds(for: .mediaBox)
                let scale: CGFloat = 2
                let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
                let renderer = UIGraphicsImageRenderer(size: size)
                return renderer.image { ctx in
                    UIColor.white.setFill()
                    ctx.fill(CGRect(origin: .zero, size: size))
                    ctx.cgContext.scaleBy(x: scale, y: scale)
                    ctx.cgContext.translateBy(x: 0, y: bounds.height)
                    ctx.cgContext.scaleBy(x: 1, y: -1)
                    page.draw(with: .mediaBox, to: ctx.cgContext)
                }
            } else {
                return UIImage(contentsOfFile: url.path)
            }
        }.value
    }
}

// MARK: - Chip + FlowRow
//
// Compact tap-target pill used in the info section for cost / phone /
// website. FlowRow wraps chips onto multiple lines when the row runs
// out of horizontal space.

private struct Chip: View {
    let symbol: String
    let label: String
    var accentTint: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(Theme.Font.caption)
            Text(label)
                .font(Theme.Font.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, 6)
        .foregroundStyle(
            accentTint ? Theme.Color.accent : Theme.Color.textPrimary
        )
        .background(
            accentTint
                ? Theme.Color.accent.opacity(0.18)
                : Theme.Color.surfaceElevated,
            in: Capsule()
        )
        .frame(minHeight: 28)
    }
}

private struct FlowRow: Layout {
    var spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            totalWidth = max(totalWidth, x - spacing)
        }
        return CGSize(width: totalWidth, height: y + rowHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Ticket card

private struct TicketCard: View {
    let ticket: Ticket
    let category: BlockCategory
    let isCopied: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void

    private var hasCode: Bool {
        !ticket.confirmationCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var label: String {
        ticket.name.isEmpty ? category.label : ticket.name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                Image(systemName: category.symbol)
                    .font(Theme.Font.caption)
                    .foregroundStyle(category.textOnSurface)
                Text(label.uppercased())
                    .font(Theme.Font.caption)
                    .tracking(1.2)
                    .foregroundStyle(Theme.Color.textSecondary)
                Spacer(minLength: 0)
                if hasCode {
                    Text(isCopied ? "COPIED" : "TAP TO COPY")
                        .font(Theme.Font.caption)
                        .tracking(1.0)
                        .foregroundStyle(isCopied ? Color.white : Theme.Color.accent)
                        .padding(.horizontal, Theme.Spacing.s)
                        .padding(.vertical, 3)
                        .background(
                            isCopied
                                ? Theme.Color.accent
                                : Theme.Color.accent.opacity(0.18),
                            in: Capsule()
                        )
                }
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(Theme.Font.caption)
                        .foregroundStyle(Theme.Color.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(
                            Theme.Color.surfaceElevated,
                            in: Circle()
                        )
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("Edit ticket")
            }

            if hasCode {
                Button(action: onCopy) {
                    Text(ticket.confirmationCode)
                        .font(Theme.Font.codeHuge)
                        .foregroundStyle(Theme.Color.textPrimary)
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("Confirmation code \(ticket.confirmationCode)")
                .accessibilityHint(isCopied ? "Copied" : "Double tap to copy")
            }

            if hasFacts {
                Divider()
                    .overlay(Theme.Color.hourRule)
                    .padding(.vertical, 2)
                HStack(spacing: Theme.Spacing.l) {
                    if !ticket.seat.isEmpty {
                        fact("SEAT", value: ticket.seat)
                    }
                    if !ticket.gate.isEmpty {
                        fact("GATE", value: ticket.gate)
                    }
                    if !ticket.holderName.isEmpty {
                        fact("FOR", value: ticket.holderName)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Theme.Color.surface,
            in: RoundedRectangle(cornerRadius: Theme.Radius.medium)
        )
    }

    private var hasFacts: Bool {
        !ticket.seat.isEmpty || !ticket.gate.isEmpty || !ticket.holderName.isEmpty
    }

    private func fact(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Theme.Font.caption)
                .tracking(1.2)
                .foregroundStyle(Theme.Color.textTertiary)
            Text(value)
                .font(Theme.Font.body)
                .foregroundStyle(Theme.Color.textPrimary)
                .lineLimit(1)
        }
    }
}

// MARK: - Preview

#Preview {
    let container = try! ModelContainer(
        for: Block.self, Ticket.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    SampleData.seedIfNeeded(context: container.mainContext)
    let descriptor = FetchDescriptor<Block>(sortBy: [SortDescriptor(\.start)])
    let block = (try? container.mainContext.fetch(descriptor))?
        .first(where: { !$0.orderedTickets.isEmpty })
        ?? Block(
            title: "Flight LGA → ORD",
            start: .now,
            end: .now.addingTimeInterval(3600),
            category: .travel
        )
    return NavigationStack {
        BlockDetailView(block: block, onEdit: { })
    }
    .modelContainer(container)
}
