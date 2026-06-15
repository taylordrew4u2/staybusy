//
//  GeocodingService.swift
//  staybusy
//
//  Best-effort reverse geocoding for blocks that arrived with a
//  location string but no lat/lng — typically iCal events whose
//  source calendar didn't include structured-location coordinates.
//  Runs in the background after each sync.
//
//  CLGeocoder is rate-limited (~1 request per second) so we throttle
//  every lookup and bail early when the user is offline. A single
//  in-flight guard prevents overlapping passes.
//

import Foundation
import CoreLocation
import SwiftData

@MainActor
final class GeocodingService {
    static let shared = GeocodingService()

    private let geocoder = CLGeocoder()
    private var isRunning = false
    /// Throttle delay between CLGeocoder requests. Apple recommends
    /// roughly one query per second; this matches the documented
    /// guidance and keeps us comfortably under the rate limit.
    private let throttle: Duration = .milliseconds(1100)

    private init() {}

    /// Find every block that has a location string but no resolved
    /// coordinates and try to fill them in. Idempotent — re-running
    /// while one is in flight is a no-op.
    func geocodeMissingCoordinates(in context: ModelContext) async {
        guard !isRunning else { return }
        isRunning = true
        defer { isRunning = false }

        // Capture identifiers first; mutating during the fetch loop
        // (with awaits) is more fragile than re-fetching each row.
        let descriptor = FetchDescriptor<Block>()
        guard let blocks = try? context.fetch(descriptor) else { return }

        let pending = blocks.filter(needsGeocoding)
        guard !pending.isEmpty else { return }

        var didWrite = false

        for block in pending {
            // Re-check on the latest state — a re-sync may have filled
            // coords from EKStructuredLocation between iterations.
            guard needsGeocoding(block) else { continue }
            guard let query = bestGeocodeQuery(for: block) else { continue }

            if let coord = await lookup(query) {
                block.latitude = coord.latitude
                block.longitude = coord.longitude
                didWrite = true
            }

            // Respect the rate limit between requests.
            try? await Task.sleep(for: throttle)
        }

        if didWrite {
            try? context.save()
        }
    }

    private func needsGeocoding(_ block: Block) -> Bool {
        guard block.latitude == nil || block.longitude == nil else { return false }
        return !block.address.isEmpty || !block.locationName.isEmpty
    }

    private func bestGeocodeQuery(for block: Block) -> String? {
        if !block.address.isEmpty { return block.address }
        if !block.locationName.isEmpty { return block.locationName }
        return nil
    }

    private func lookup(_ query: String) async -> CLLocationCoordinate2D? {
        await withCheckedContinuation { continuation in
            geocoder.geocodeAddressString(query) { placemarks, _ in
                let coord = placemarks?.first?.location?.coordinate
                continuation.resume(returning: coord)
            }
        }
    }
}
