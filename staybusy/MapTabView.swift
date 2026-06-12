//
//  MapTabView.swift
//  staybusy
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

// MARK: - Root

struct MapTabView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Block.start, order: .forward) private var allBlocks: [Block]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var selectedBlock: Block?
    @State private var showPolylines = false
    @State private var navigationPath = NavigationPath()
    @State private var presentedSheet: EditorSheet?
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var blocksForDay: [Block] {
        allBlocks
            .filter { Calendar.current.isDate($0.start, inSameDayAs: selectedDate) }
            .sorted { $0.start < $1.start }
    }

    private var blocksWithCoords: [Block] {
        blocksForDay.filter { $0.latitude != nil && $0.longitude != nil }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottom) {
                Theme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    DayPickerBar(selectedDate: $selectedDate)
                    ZStack(alignment: .topTrailing) {
                        mapView
                        polylineButton
                            .padding(.top, 12)
                            .padding(.trailing, 16)
                    }
                }

                if let selected = selectedBlock {
                    BottomCard(
                        block: selected,
                        onDismiss: {
                            withAnimation(.spring(response: 0.3)) { selectedBlock = nil }
                        },
                        onShowDetail: {
                            withAnimation(.spring(response: 0.3)) { selectedBlock = nil }
                            navigationPath.append(selected)
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Block.self) { block in
                BlockDetailView(block: block) {
                    presentedSheet = .edit(block)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .create(let interval):
                BlockEditorView(editing: nil, suggested: interval)
            case .edit(let block):
                BlockEditorView(editing: block, suggested: nil) {
                    navigationPath = NavigationPath()
                }
            }
        }
        .onAppear { refitCamera() }
        .onChange(of: selectedDate) { _, _ in
            withAnimation(.spring(response: 0.3)) { selectedBlock = nil }
            refitCamera()
        }
    }

    // MARK: - Map

    private var mapView: some View {
        let indexed = Array(blocksWithCoords.enumerated())
        return Map(position: $cameraPosition) {
            ForEach(indexed, id: \.element.persistentModelID) { pair in
                Annotation(pair.element.title, coordinate: coord(pair.element)) {
                    NumberedPin(
                        number: pair.offset + 1,
                        color: pair.element.category.color,
                        isSelected: selectedBlock?.persistentModelID == pair.element.persistentModelID
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35)) {
                            selectedBlock = pair.element
                        }
                    }
                }
            }

            if showPolylines && indexed.count >= 2 {
                MapPolyline(coordinates: indexed.map { coord($0.element) })
                    .stroke(Theme.accent, lineWidth: 2)
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .overlay(alignment: .center) {
            if blocksWithCoords.isEmpty {
                emptyOverlay
            }
        }
    }

    private var emptyOverlay: some View {
        VStack(spacing: 6) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Theme.textSecondary)
            Text("No mapped blocks")
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.textSecondary)
            if blocksForDay.isEmpty {
                Text("Nothing scheduled this day")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textMuted)
            } else {
                Text("Add a location to a block to see it here")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .padding(20)
        .background(Theme.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: 14))
        .allowsHitTesting(false)
    }

    // MARK: - Polyline toggle

    private var polylineButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { showPolylines.toggle() }
        } label: {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(.system(size: 16, weight: .heavy))
                .foregroundStyle(showPolylines ? Color.white : Theme.textPrimary)
                .frame(width: 40, height: 40)
                .background(
                    showPolylines ? Theme.accent : Theme.surfaceElevated.opacity(0.92),
                    in: Circle()
                )
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showPolylines ? "Hide route lines" : "Show route lines")
    }

    // MARK: - Helpers

    private func coord(_ b: Block) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: b.latitude ?? 0, longitude: b.longitude ?? 0)
    }

    private func refitCamera() {
        let coords = blocksWithCoords.map(coord)
        guard !coords.isEmpty else { return }
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        guard let minLat = lats.min(), let maxLat = lats.max(),
              let minLon = lons.min(), let maxLon = lons.max() else { return }
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let latDelta = max(0.01, (maxLat - minLat) * 1.6)
        let lonDelta = max(0.01, (maxLon - minLon) * 1.6)
        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
        withAnimation(.easeInOut(duration: 0.35)) {
            cameraPosition = .region(region)
        }
    }
}

// MARK: - Numbered pin

private struct NumberedPin: View {
    let number: Int
    let color: Color
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: isSelected ? 44 : 32, height: isSelected ? 44 : 32)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
            Text("\(number)")
                .font(.system(size: isSelected ? 18 : 14, weight: .heavy, design: .rounded).monospacedDigit())
                .foregroundStyle(Color.white)
        }
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Bottom card

private struct BottomCard: View {
    let block: Block
    let onDismiss: () -> Void
    let onShowDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(block.category.color)
                    .frame(width: 4, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: block.category.symbol)
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(block.category.color)
                        Text(block.category.label.uppercased())
                            .font(.system(.caption2, design: .rounded).weight(.heavy))
                            .tracking(1.3)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Text(block.title)
                        .font(.system(.headline, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(2)
                    Text(timeRange)
                        .font(.system(.caption, design: .rounded).weight(.semibold).monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                    if !block.locationName.isEmpty {
                        Text(block.locationName)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.textMuted)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Button(action: openDrive) {
                    HStack(spacing: 6) {
                        Image(systemName: "car.fill")
                            .font(.system(size: 14, weight: .heavy))
                        Text("Drive")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Color.white)
                }
                .buttonStyle(.plain)

                Button(action: onShowDetail) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .heavy))
                        Text("Details")
                            .font(.system(.subheadline, design: .rounded).weight(.heavy))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.surfaceElevated, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Theme.textPrimary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.5), radius: 12, y: -4)
    }

    private func openDrive() {
        guard let lat = block.latitude, let lng = block.longitude else { return }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)))
        item.name = block.locationName.isEmpty ? block.title : block.locationName
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }

    private var timeRange: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: block.start)) – \(f.string(from: block.end))"
    }
}
