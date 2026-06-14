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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                Theme.Color.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    DayPickerBar(selectedDate: $selectedDate)
                    ZStack(alignment: .topTrailing) {
                        mapView
                        polylineButton
                            .padding(.top, Theme.Spacing.m)
                            .padding(.trailing, Theme.Spacing.l)
                    }
                }

                if let selected = selectedBlock {
                    BottomCard(
                        block: selected,
                        onDismiss: dismissSelection,
                        onShowDetail: {
                            dismissSelection()
                            navigationPath.append(selected)
                        }
                    )
                    .padding(.horizontal, Theme.Spacing.l)
                    .padding(.bottom, Theme.Spacing.l)
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
        .tint(Theme.Color.accent)
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
            dismissSelection()
            refitCamera()
        }
    }

    private func dismissSelection() {
        withAnimation(Theme.Motion.snap(reduceMotion: reduceMotion)) {
            selectedBlock = nil
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
                        withAnimation(Theme.Motion.snap(reduceMotion: reduceMotion)) {
                            selectedBlock = pair.element
                        }
                    }
                }
            }

            if showPolylines && indexed.count >= 2 {
                MapPolyline(coordinates: indexed.map { coord($0.element) })
                    .stroke(Theme.Color.accent, lineWidth: 2)
            }
        }
        .mapStyle(.standard(elevation: .flat))
        .overlay(alignment: .center) {
            if blocksWithCoords.isEmpty {
                emptyOverlay
            }
        }
    }

    @ViewBuilder
    private var emptyOverlay: some View {
        if blocksForDay.isEmpty {
            EmptyStateView(
                symbol: "mappin.slash",
                title: "Nothing scheduled",
                message: "Add a block to see it on the map.",
                actionTitle: "Add a block",
                action: { presentedSheet = .create(suggestedDefaultInterval()) }
            )
            .padding(Theme.Spacing.l)
            .background(Theme.Color.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .padding(Theme.Spacing.l)
        } else {
            EmptyStateView(
                symbol: "mappin.slash",
                title: "No locations yet",
                message: "Add a location to one of today's blocks to see it here.",
                actionTitle: "Add a block",
                action: { presentedSheet = .create(suggestedDefaultInterval()) }
            )
            .padding(Theme.Spacing.l)
            .background(Theme.Color.surface.opacity(0.92), in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
            .padding(Theme.Spacing.l)
        }
    }

    // MARK: - Polyline toggle

    private var polylineButton: some View {
        Button {
            withAnimation(Theme.Motion.snap(reduceMotion: reduceMotion)) {
                showPolylines.toggle()
            }
        } label: {
            Image(systemName: "point.3.connected.trianglepath.dotted")
                .font(Theme.Font.title)
                .foregroundStyle(showPolylines ? Color.white : Theme.Color.textPrimary)
                .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                .background(
                    showPolylines ? Theme.Color.accent : Theme.Color.surfaceElevated.opacity(0.92),
                    in: Circle()
                )
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
        }
        .buttonStyle(.pressable)
        .accessibilityLabel(showPolylines ? "Hide route lines" : "Show route lines")
    }

    // MARK: - Helpers

    private func coord(_ b: Block) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: b.latitude ?? 0, longitude: b.longitude ?? 0)
    }

    private func suggestedDefaultInterval() -> DateInterval {
        let cal = Calendar.current
        let base = cal.isDateInToday(selectedDate)
            ? Date()
            : (cal.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate)
        return DateInterval(start: base, duration: 3600)
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
        withAnimation(Theme.Motion.gentle(reduceMotion: reduceMotion)) {
            cameraPosition = .region(region)
        }
    }
}

// MARK: - Numbered pin

private struct NumberedPin: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
                .font(Theme.Font.body.monospacedDigit())
                .foregroundStyle(Color.white)
        }
        .animation(Theme.Motion.snap(reduceMotion: reduceMotion), value: isSelected)
        .accessibilityLabel("Block \(number)")
    }
}

// MARK: - Bottom card

private struct BottomCard: View {
    let block: Block
    let onDismiss: () -> Void
    let onShowDetail: () -> Void

    private var coordinate: CLLocationCoordinate2D? {
        guard let lat = block.latitude, let lng = block.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(alignment: .top, spacing: Theme.Spacing.s) {
                BlockCard(block: block, variant: .compact)
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(Theme.Font.title)
                        .foregroundStyle(Theme.Color.textTertiary)
                        .frame(width: Theme.Size.minTapTarget, height: Theme.Size.minTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("Dismiss")
            }

            if let coordinate {
                DirectionsButtonRow(
                    coordinate: coordinate,
                    destinationName: block.locationName.isEmpty ? block.title : block.locationName,
                    layout: .driveAndDetails(detailsAction: onShowDetail)
                )
            } else {
                SecondaryButton(title: "Details", systemImage: "arrow.up.right", action: onShowDetail)
            }
        }
        .padding(Theme.Spacing.m)
        .background(Theme.Color.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.medium))
        .shadow(color: .black.opacity(0.5), radius: 12, y: -4)
    }
}
