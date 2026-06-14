//
//  DirectionsButtonRow.swift
//  staybusy
//
//  Drive / Transit (and optional Google Maps) buttons shared by the
//  Map tab's bottom card and the block-detail screen.
//

import SwiftUI
import MapKit
import UIKit

struct DirectionsButtonRow: View {
    let coordinate: CLLocationCoordinate2D
    let destinationName: String
    var layout: Layout = .stacked

    enum Layout {
        /// Drive | Transit in a row; Google (if installed) on its own line below.
        case stacked
        /// Drive and Details inline (used by the Map bottom card).
        case driveAndDetails(detailsAction: () -> Void)
    }

    var body: some View {
        switch layout {
        case .stacked:
            stackedLayout
        case .driveAndDetails(let detailsAction):
            inlineLayout(detailsAction: detailsAction)
        }
    }

    // MARK: - Stacked (block detail)

    private var stackedLayout: some View {
        VStack(spacing: Theme.Spacing.s) {
            HStack(spacing: Theme.Spacing.s) {
                PrimaryButton(title: "Drive", systemImage: "car.fill") {
                    openAppleMaps(mode: MKLaunchOptionsDirectionsModeDriving)
                }
                PrimaryButton(title: "Transit", systemImage: "tram.fill") {
                    openAppleMaps(mode: MKLaunchOptionsDirectionsModeTransit)
                }
            }
            if googleMapsInstalled {
                SecondaryButton(title: "Open in Google Maps", systemImage: "g.circle.fill", action: openGoogleMaps)
            }
        }
    }

    // MARK: - Inline (map bottom card)

    private func inlineLayout(detailsAction: @escaping () -> Void) -> some View {
        HStack(spacing: Theme.Spacing.s) {
            PrimaryButton(title: "Drive", systemImage: "car.fill") {
                openAppleMaps(mode: MKLaunchOptionsDirectionsModeDriving)
            }
            SecondaryButton(title: "Details", systemImage: "arrow.up.right", action: detailsAction)
        }
    }

    // MARK: - Actions

    private var googleMapsInstalled: Bool {
        guard let url = URL(string: "comgooglemaps://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    private func openAppleMaps(mode: String) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = destinationName.isEmpty ? "Destination" : destinationName
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: mode])
    }

    private func openGoogleMaps() {
        let s = "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving"
        if let url = URL(string: s) {
            UIApplication.shared.open(url)
        }
    }
}
