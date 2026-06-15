//
//  LeaveByModel.swift
//  staybusy
//
//  Drives the "leave by" computation used on Block detail and in the
//  Now/Next bar. Asks Core Location for the user's current position,
//  asks MapKit for an automobile ETA to the target, and publishes a
//  `leaveBy` time equal to `arriveBy - eta - bufferMinutes`.
//
//  The model is `@Observable` so SwiftUI re-renders consumers when the
//  state transitions. A single instance can be re-targeted for a new
//  destination via `retarget(target:arriveBy:)` — used by NowNextBar
//  as the upcoming block rolls forward through the day.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit
import Observation

@Observable
final class LeaveByModel: NSObject, CLLocationManagerDelegate {
    enum State: Equatable {
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
    @ObservationIgnored private let bufferMinutes: Double
    @ObservationIgnored private var didStart = false

    init(bufferMinutes: Double = 10) {
        self.manager = CLLocationManager()
        self.bufferMinutes = bufferMinutes
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// One-shot entry used by BlockDetailView. Idempotent — safe to
    /// call from `.onAppear`. Prefer `retarget(...)` when the target
    /// can change while the view is alive (NowNextBar).
    func start(target: CLLocationCoordinate2D, arriveBy: Date) {
        guard !didStart else { return }
        didStart = true
        applyTarget(target, arriveBy: arriveBy)
    }

    /// Re-target the tracker. No-op when called with the same target +
    /// arriveBy — so callers can drive it from view body without
    /// thrashing the location manager every render.
    func retarget(target: CLLocationCoordinate2D, arriveBy: Date) {
        if let existingTarget = self.target,
           let existingArriveBy = self.arriveBy,
           areEqual(existingTarget, target),
           abs(existingArriveBy.timeIntervalSince(arriveBy)) < 1 {
            return
        }
        applyTarget(target, arriveBy: arriveBy)
    }

    /// Drop the current target and reset state to `.idle`. Used by
    /// NowNextBar when the next block is unrouteable (no location) or
    /// when all blocks are done.
    func clear() {
        target = nil
        arriveBy = nil
        if case .idle = state {
            return
        }
        state = .idle
    }

    private func applyTarget(_ target: CLLocationCoordinate2D, arriveBy: Date) {
        self.target = target
        self.arriveBy = arriveBy

        switch manager.authorizationStatus {
        case .notDetermined:
            state = .requestingPermission
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            state = .denied
        case .authorizedAlways, .authorizedWhenInUse:
            state = .computing
            manager.requestLocation()
        @unknown default:
            state = .denied
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if target != nil {
                state = .computing
                manager.requestLocation()
            }
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
        let mode = TransportMode.current
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: target))
        request.transportType = mode.mkType

        do {
            let response = try await MKDirections(request: request).calculateETA()
            let leave = arriveBy
                .addingTimeInterval(-response.expectedTravelTime)
                .addingTimeInterval(-bufferMinutes * 60)
            state = .ready(leaveBy: leave, eta: response.expectedTravelTime)
        } catch {
            // Transit isn't available everywhere; fall back to driving
            // once before giving up so the user still sees a useful
            // number when their region has no transit data.
            if mode == .transit {
                request.transportType = .automobile
                do {
                    let response = try await MKDirections(request: request).calculateETA()
                    let leave = arriveBy
                        .addingTimeInterval(-response.expectedTravelTime)
                        .addingTimeInterval(-bufferMinutes * 60)
                    state = .ready(leaveBy: leave, eta: response.expectedTravelTime)
                    return
                } catch {
                    state = .stale
                    return
                }
            }
            state = .stale
        }
    }

    /// Re-fire the ETA computation against the existing target. Called
    /// when the user flips the Transport Mode setting so the leave-by
    /// figure updates immediately.
    func refresh() {
        guard target != nil, arriveBy != nil else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            state = .computing
            manager.requestLocation()
        default:
            break
        }
    }

    // MARK: - Helpers

    private func areEqual(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Bool {
        abs(a.latitude - b.latitude) < 0.00001 && abs(a.longitude - b.longitude) < 0.00001
    }
}
