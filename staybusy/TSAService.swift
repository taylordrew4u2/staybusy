//
//  TSAService.swift
//  staybusy
//
//  Surfaces TSA security-line context for airport-style blocks.
//
//  Honest scope: there is no public, stable, free TSA wait-times API.
//  Apple Maps and the MyTSA app talk to internal endpoints we can't
//  redistribute. So we do two things:
//
//  1. Estimate the wait from the flight's local time using documented
//     peak-hour patterns (TSA's own published travel tips identify
//     6–9am and 4–7pm as the busiest windows).
//  2. Link out to MyTSA — first the iOS app via `mytsa://`, then the
//     web (https://www.tsa.gov/travel/) — for authoritative live data.
//
//  The estimate is clearly labelled "Estimated" in the UI so the user
//  never confuses it for a live measurement.
//

import Foundation
import UIKit

enum TSAService {
    // MARK: - Severity

    enum Severity {
        case low
        case medium
        case high

        var label: String {
            switch self {
            case .low: return "Light"
            case .medium: return "Moderate"
            case .high: return "Busy"
            }
        }
    }

    struct Estimate {
        let minutes: Int
        let severity: Severity
        /// Free-form context the card uses as the eyebrow / subtitle.
        let context: String
    }

    /// Estimate the expected security-line wait at `block`'s departure
    /// time. Uses the documented peak-hour patterns; intentionally a
    /// rough heuristic so the UI can show *something* without lying
    /// about a live measurement.
    static func estimate(for block: Block) -> Estimate {
        let date = block.start
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: date) // 1 = Sun
        let hour = cal.component(.hour, from: date)

        let isWeekend = (weekday == 1 || weekday == 7)
        let isMondayOrFriday = (weekday == 2 || weekday == 6)
        let baseline = isWeekend ? 12 : 18

        // Peak hours per TSA travel tips.
        let isMorningPeak = (6...9).contains(hour)
        let isEveningPeak = (16...19).contains(hour)
        let isOvernight = (hour <= 4) || (hour >= 22)

        let minutes: Int
        let severity: Severity
        let context: String

        switch (isOvernight, isMorningPeak, isEveningPeak) {
        case (true, _, _):
            minutes = max(5, baseline - 10)
            severity = .low
            context = "Overnight — expect a short line."
        case (_, true, _):
            minutes = baseline + 12 + (isMondayOrFriday ? 6 : 0)
            severity = .high
            context = "Morning peak — plan extra time."
        case (_, _, true):
            minutes = baseline + 8 + (isMondayOrFriday ? 4 : 0)
            severity = isMondayOrFriday ? .high : .medium
            context = isMondayOrFriday
                ? "Friday evening rush — plan extra time."
                : "Evening peak — moderately busy."
        default:
            minutes = baseline + (isMondayOrFriday ? 4 : 0)
            severity = .medium
            context = isWeekend
                ? "Off-peak weekend — likely a manageable line."
                : "Off-peak — a typical wait."
        }

        return Estimate(minutes: minutes, severity: severity, context: context)
    }

    // MARK: - IATA + URLs

    /// Try to find a 3-letter IATA airport code in the block. Looks at
    /// the location name, address, and title, in that order. Restricted
    /// to a known list of major US airports + a few international ones
    /// so we don't accept arbitrary 3-letter words.
    static func iataCode(in block: Block) -> String? {
        let needle = "\(block.locationName) \(block.address) \(block.title)".uppercased()
        for code in knownIATAs where needle.range(of: "\\b\(code)\\b", options: .regularExpression) != nil {
            return code
        }
        return nil
    }

    /// `https://www.tsa.gov/travel/security-screening/whatcanibring/airports/<code>`
    /// is the public landing page for an airport's screening info. The
    /// MyTSA iOS app deep-links via `mytsa://airport/<code>` — we try
    /// that first.
    static func liveLineURL(for iata: String?) -> URL {
        if let iata,
           let appURL = URL(string: "mytsa://airport/\(iata)"),
           UIApplication.shared.canOpenURL(appURL) {
            return appURL
        }
        return URL(string: "https://www.tsa.gov/travel/passenger-support")!
    }

    /// Major US airports + a handful of international ones we expect
    /// users to fly through. Expanded as needed; keeping the list
    /// narrow avoids matching random 3-letter words ("BAR", "DAY", etc.)
    /// in titles.
    private static let knownIATAs: Set<String> = [
        // Major US hubs
        "ATL", "BOS", "BWI", "CLE", "CLT", "CVG", "DAL", "DCA", "DEN",
        "DFW", "DTW", "EWR", "FLL", "HNL", "HOU", "IAD", "IAH", "IND",
        "JFK", "LAS", "LAX", "LGA", "MCI", "MCO", "MDW", "MEM", "MIA",
        "MKE", "MSP", "MSY", "OAK", "OKC", "ORD", "PBI", "PDX", "PHL",
        "PHX", "PIT", "RDU", "SAN", "SAT", "SDF", "SEA", "SFO", "SJC",
        "SLC", "SMF", "STL", "TPA",
        // Major international
        "AMS", "ARN", "ATH", "AUH", "BCN", "BER", "BKK", "BNE", "BRU",
        "CDG", "CPH", "DEL", "DOH", "DUB", "DXB", "FCO", "FRA", "GIG",
        "GRU", "HEL", "HKG", "HND", "ICN", "IST", "JNB", "KIX", "KUL",
        "LAX", "LHR", "LIM", "LIS", "MAD", "MEL", "MEX", "MUC", "NRT",
        "OSL", "PEK", "PVG", "SIN", "SYD", "TLV", "VIE", "WAW", "YOW",
        "YUL", "YVR", "YYZ", "ZRH"
    ]
}
