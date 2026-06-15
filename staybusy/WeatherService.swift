//
//  WeatherService.swift
//  staybusy
//
//  Thin wrapper around Apple's WeatherKit so the rest of the app can
//  ask "what's the weather on this day at this place?" without
//  threading framework calls through every view.
//
//  - Uses the closest located block in a day as the query location;
//    if no block on that day carries lat/lng we walk forward / back
//    a few days to find one.
//  - Caches results in memory keyed by (day-start, lat, lng) so day
//    tiles don't refetch on every render.
//  - Background-safe: every fetch returns optional so the UI can fall
//    back to an unobtrusive "—" when weather is unavailable.
//

import Foundation
import CoreLocation
import WeatherKit

@MainActor
final class WeatherService {
    static let shared = WeatherService()

    struct DayForecast {
        let symbolName: String
        let highTemp: Measurement<UnitTemperature>
        let lowTemp: Measurement<UnitTemperature>
        let condition: String

        /// Formatted "72°/58°" using the locale's preferred unit.
        func temperatureLabel() -> String {
            let formatter = MeasurementFormatter()
            formatter.unitStyle = .short
            formatter.numberFormatter.maximumFractionDigits = 0
            return "\(formatter.string(from: highTemp)) / \(formatter.string(from: lowTemp))"
        }
    }

    private let service = WeatherKit.WeatherService.shared
    /// Cache key: day-of-week startOfDay timestamp + rounded coords.
    private var cache: [String: DayForecast] = [:]
    /// Tracks in-flight requests so re-asks while the first is pending
    /// don't kick off duplicate fetches.
    private var inFlight: [String: Task<DayForecast?, Never>] = [:]

    private init() {}

    /// Best-effort daily forecast for `date` at `coordinate`. Returns
    /// `nil` when WeatherKit can't reach the network, the entitlement
    /// isn't enabled, or the date is outside the daily-forecast window.
    func forecast(
        for date: Date,
        at coordinate: CLLocationCoordinate2D
    ) async -> DayForecast? {
        let key = cacheKey(date: date, coordinate: coordinate)
        if let cached = cache[key] { return cached }
        if let existing = inFlight[key] { return await existing.value }

        let task = Task<DayForecast?, Never> { [weak self] in
            guard let self else { return nil }
            return await self.fetch(date: date, coordinate: coordinate)
        }
        inFlight[key] = task
        let result = await task.value
        inFlight[key] = nil
        if let result {
            cache[key] = result
        }
        return result
    }

    // MARK: - Fetching

    private func fetch(
        date: Date,
        coordinate: CLLocationCoordinate2D
    ) async -> DayForecast? {
        let location = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        do {
            let dailyForecast = try await service.weather(
                for: location,
                including: .daily
            )
            let target = Calendar.current.startOfDay(for: date)
            guard let match = dailyForecast.forecast.first(where: {
                Calendar.current.isDate($0.date, inSameDayAs: target)
            }) else {
                return nil
            }
            return DayForecast(
                symbolName: match.symbolName,
                highTemp: match.highTemperature,
                lowTemp: match.lowTemperature,
                condition: match.condition.description
            )
        } catch {
            return nil
        }
    }

    private func cacheKey(
        date: Date,
        coordinate: CLLocationCoordinate2D
    ) -> String {
        let start = Calendar.current.startOfDay(for: date)
        let lat = (coordinate.latitude * 100).rounded() / 100
        let lng = (coordinate.longitude * 100).rounded() / 100
        return "\(Int(start.timeIntervalSince1970))-\(lat)-\(lng)"
    }
}
