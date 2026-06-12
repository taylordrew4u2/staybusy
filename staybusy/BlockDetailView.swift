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

struct BlockDetailView: View {
    let block: Block
    let onEdit: () -> Void

    @State private var attachmentURLs: [URL] = []
    @State private var photosSelection: [PhotosPickerItem] = []
    @State private var showPhotosPicker = false
    @State private var showCamera = false
    @State private var showFilesPicker = false
    @State private var fullScreenSelection: IndexBox?
    @State private var leaveByModel = LeaveByModel()
    @State private var copiedCode = false

    private var blockCoordinate: CLLocationCoordinate2D? {
        guard let lat = block.latitude, let lng = block.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !attachmentURLs.isEmpty {
                    attachmentsCarousel
                }
                ingestionButtons
                if !block.confirmationCode.isEmpty {
                    confirmationSection
                }
                if !block.links.isEmpty {
                    linksSection
                }
                infoSection
                if let coord = blockCoordinate {
                    mapSection(coord)
                    directionsButtons(coord)
                    leaveBySection(coord)
                }
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(block.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: onEdit)
                    .foregroundStyle(Theme.accent)
                    .font(.system(.body, design: .rounded).weight(.heavy))
            }
        }
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .onAppear {
            attachmentURLs = AttachmentStore.urls(for: block.attachmentFilenames)
            if let coord = blockCoordinate {
                leaveByModel.start(target: coord, arriveBy: block.start)
            }
        }
        .onChange(of: block.attachmentFilenames) { _, names in
            attachmentURLs = AttachmentStore.urls(for: names)
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
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Ingestion buttons

    private var ingestionButtons: some View {
        HStack(spacing: 10) {
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
            VStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .heavy))
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.heavy))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundStyle(Theme.textPrimary)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
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

    private var confirmationSection: some View {
        Button {
            UIPasteboard.general.string = block.confirmationCode
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.25)) { copiedCode = true }
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    withAnimation(.spring(response: 0.25)) { copiedCode = false }
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("CONFIRMATION CODE")
                        .font(.system(.caption2, design: .rounded).weight(.heavy))
                        .tracking(1.4)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text(copiedCode ? "COPIED" : "TAP TO COPY")
                        .font(.system(.caption2, design: .rounded).weight(.heavy))
                        .tracking(1.0)
                        .foregroundStyle(copiedCode ? Color.white : Theme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            copiedCode ? Theme.accent : Theme.accent.opacity(0.18),
                            in: Capsule()
                        )
                }
                Text(block.confirmationCode)
                    .font(.system(size: 32, weight: .heavy, design: .monospaced))
                    .foregroundStyle(Theme.textPrimary)
                    .minimumScaleFactor(0.55)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Links

    private var linksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("LINKS")
            VStack(spacing: 8) {
                ForEach(Array(block.links.enumerated()), id: \.offset) { _, urlString in
                    if let url = makeURL(urlString) {
                        Link(destination: url) {
                            HStack(spacing: 10) {
                                Image(systemName: "safari.fill")
                                    .foregroundStyle(Theme.accent)
                                    .font(.system(size: 16, weight: .heavy))
                                Text(urlString)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .foregroundStyle(Theme.textSecondary)
                                    .font(.system(size: 12, weight: .heavy))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(block.category.color.opacity(0.18))
                        .frame(width: 30, height: 30)
                    Image(systemName: block.category.symbol)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(block.category.color)
                }
                Text(block.category.label.uppercased())
                    .font(.system(.caption, design: .rounded).weight(.heavy))
                    .tracking(1.3)
                    .foregroundStyle(Theme.textSecondary)
            }
            Text(timeRangeString)
                .font(.system(.title3, design: .rounded).weight(.heavy).monospacedDigit())
                .foregroundStyle(Theme.textPrimary)
            if !block.locationName.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(Theme.textSecondary)
                    Text(block.locationName)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            if !block.address.isEmpty {
                Text(block.address)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(Theme.textMuted)
            }
            if !block.notes.isEmpty {
                Text(block.notes)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
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
            .tint(Theme.accent)
        }
        .mapStyle(.standard(elevation: .flat))
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .allowsHitTesting(false)
    }

    // MARK: - Directions

    private func directionsButtons(_ coord: CLLocationCoordinate2D) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                directionsButton("Drive", "car.fill") {
                    openAppleMaps(coord: coord, mode: MKLaunchOptionsDirectionsModeDriving)
                }
                directionsButton("Transit", "tram.fill") {
                    openAppleMaps(coord: coord, mode: MKLaunchOptionsDirectionsModeTransit)
                }
            }
            if googleMapsInstalled {
                Button {
                    openGoogleMaps(coord: coord)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "g.circle.fill")
                            .font(.system(size: 16, weight: .heavy))
                        Text("Open in Google Maps")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Theme.textPrimary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func directionsButton(
        _ title: String,
        _ symbol: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .heavy))
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.heavy))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(Color.white)
        }
        .buttonStyle(.plain)
    }

    private var googleMapsInstalled: Bool {
        guard let url = URL(string: "comgooglemaps://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    private func openAppleMaps(coord: CLLocationCoordinate2D, mode: String) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coord))
        item.name = block.locationName.isEmpty ? "Destination" : block.locationName
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: mode])
    }

    private func openGoogleMaps(coord: CLLocationCoordinate2D) {
        let s = "comgooglemaps://?daddr=\(coord.latitude),\(coord.longitude)&directionsmode=driving"
        if let url = URL(string: s) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Leave by

    private func leaveBySection(_ coord: CLLocationCoordinate2D) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("LEAVE BY")
            leaveByContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var leaveByContent: some View {
        switch leaveByModel.state {
        case .idle:
            iconRow("location.fill", "Preparing…", iconTint: Theme.textSecondary)
        case .requestingPermission:
            iconRow(
                "location.fill",
                "Allow location to compute travel time",
                iconTint: Theme.textSecondary
            )
        case .computing:
            HStack(spacing: 10) {
                ProgressView()
                    .tint(Theme.textSecondary)
                Text("Calculating ETA…")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        case .denied:
            iconRow(
                "location.slash.fill",
                "Enable location in Settings to see Leave by",
                iconTint: Theme.textSecondary
            )
        case .ready(let leaveBy, let eta):
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Leave by \(formatTime(leaveBy))")
                        .font(.system(.title2, design: .rounded).weight(.heavy).monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                    Text("\(formatDuration(eta)) drive · 10 min buffer")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "car.fill")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(Theme.accent)
            }
        case .stale:
            iconRow(
                "exclamationmark.triangle.fill",
                "ETA unavailable — couldn't reach Apple Maps",
                iconTint: Theme.accent
            )
        }
    }

    private func iconRow(
        _ symbol: String,
        _ text: String,
        iconTint: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(iconTint)
            Text(text)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
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
            .font(.system(.caption2, design: .rounded).weight(.heavy))
            .tracking(1.4)
            .foregroundStyle(Theme.textSecondary)
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
                    .font(.system(size: 32, weight: .heavy))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .black.opacity(0.6))
                    .padding(20)
            }
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
                        withAnimation(.spring(response: 0.3)) { reset() }
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

// MARK: - Leave by model

@Observable
final class LeaveByModel: NSObject, CLLocationManagerDelegate {
    enum State {
        case idle
        case requestingPermission
        case denied
        case computing
        case ready(leaveBy: Date, eta: TimeInterval)
        case stale
    }

    var state: State = .idle

    @ObservationIgnored private let manager: CLLocationManager
    @ObservationIgnored private var target: CLLocationCoordinate2D?
    @ObservationIgnored private var arriveBy: Date?
    @ObservationIgnored private let bufferMinutes: Double = 10
    @ObservationIgnored private var didStart = false

    override init() {
        self.manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func start(target: CLLocationCoordinate2D, arriveBy: Date) {
        guard !didStart else { return }
        didStart = true
        self.target = target
        self.arriveBy = arriveBy

        switch manager.authorizationStatus {
        case .notDetermined:
            state = .requestingPermission
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            state = .denied
        case .authorizedAlways, .authorizedWhenInUse:
            requestLocation()
        @unknown default:
            state = .denied
        }
    }

    private func requestLocation() {
        state = .computing
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            requestLocation()
        case .denied, .restricted:
            state = .denied
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { [weak self] in
            await self?.computeETA(from: location.coordinate)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        state = .stale
    }

    @MainActor
    private func computeETA(from source: CLLocationCoordinate2D) async {
        guard let target = self.target, let arriveBy = self.arriveBy else { return }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: target))
        request.transportType = .automobile

        do {
            let response = try await MKDirections(request: request).calculateETA()
            let leave = arriveBy
                .addingTimeInterval(-response.expectedTravelTime)
                .addingTimeInterval(-bufferMinutes * 60)
            state = .ready(leaveBy: leave, eta: response.expectedTravelTime)
        } catch {
            state = .stale
        }
    }
}
