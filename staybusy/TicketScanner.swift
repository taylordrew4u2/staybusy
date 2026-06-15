//
//  TicketScanner.swift
//  staybusy
//
//  Reads a boarding-pass / event-ticket image with the Vision
//  framework, then walks the recognized text for the fields StayBusy
//  cares about: confirmation code, seat, gate, flight number, holder
//  name. Returns a partially-filled `TicketDraft` the editor can
//  populate. The user reviews + tweaks before saving — OCR is a head
//  start, not the final word.
//

import Foundation
import UIKit
import Vision
import PDFKit

/// Bundled result of a ticket scan — the ticket-shaped fields plus an
/// optional travel interval inferred from the boarding pass (date +
/// departure time + arrival time). When the times can't be confidently
/// resolved, `interval` is `nil` and the caller falls back to its own
/// defaults.
struct TicketScanResult {
    var draft: TicketDraft = TicketDraft()
    var interval: DateInterval?
    /// The flight number (e.g. "DL 1234") when one is detected. Used
    /// by the caller to set a nicer block title.
    var flightLabel: String?
}

enum TicketScanner {
    /// Run OCR on a UIImage and return a draft populated with anything
    /// we could confidently parse. Empty fields = nothing detected for
    /// that slot; the caller should keep the user's existing values for
    /// those.
    static func scan(_ image: UIImage) async -> TicketDraft {
        await scanFull(image).draft
    }

    /// Like `scan(_:)` but also returns the inferred travel interval
    /// and flight label. Used by the home-screen importer to create a
    /// new block with real times.
    static func scanFull(_ image: UIImage) async -> TicketScanResult {
        guard let cgImage = image.cgImage else { return TicketScanResult() }

        let lines = await recognizeText(in: cgImage)
        guard !lines.isEmpty else { return TicketScanResult() }

        let draft = parse(lines: lines)
        let interval = parseInterval(lines: lines)
        let flightLabel = findFlightNumber(in: lines, joinedUpper: lines.joined(separator: " ").uppercased())
        return TicketScanResult(draft: draft, interval: interval, flightLabel: flightLabel)
    }

    /// Scan a file at the given URL. Handles PDFs (renders the first
    /// page) and common image types via `UIImage`. Returns an empty
    /// draft when the file can't be read.
    static func scan(fileURL url: URL) async -> TicketDraft {
        await scanFull(fileURL: url).draft
    }

    /// File-URL counterpart to `scanFull(_:)`. Handles PDFs via PDFKit.
    static func scanFull(fileURL url: URL) async -> TicketScanResult {
        let needsScope = url.startAccessingSecurityScopedResource()
        defer { if needsScope { url.stopAccessingSecurityScopedResource() } }

        if url.pathExtension.lowercased() == "pdf" {
            guard let image = renderFirstPage(of: url) else { return TicketScanResult() }
            return await scanFull(image)
        }
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return TicketScanResult() }
        return await scanFull(image)
    }

    /// Render the first page of a PDF as a UIImage suitable for OCR.
    /// We aim for ~2000pt longest side — accurate enough for OCR
    /// without blowing through memory on huge boarding passes.
    private static func renderFirstPage(of url: URL) -> UIImage? {
        guard let document = PDFDocument(url: url),
              let page = document.page(at: 0) else { return nil }
        let bounds = page.bounds(for: .mediaBox)
        let longest = max(bounds.width, bounds.height)
        let scale = max(1, min(3, 2000 / longest))
        let size = CGSize(
            width: bounds.width * scale,
            height: bounds.height * scale
        )
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            ctx.cgContext.translateBy(x: 0, y: size.height)
            ctx.cgContext.scaleBy(x: scale, y: -scale)
            page.draw(with: .mediaBox, to: ctx.cgContext)
        }
    }

    // MARK: - Vision

    private static func recognizeText(in cgImage: CGImage) async -> [String] {
        // VNImageRequestHandler.perform(_:) is synchronous and does
        // internal dispatch — running it directly under the cooperative
        // thread pool produces "unsafeForcedSync called from Swift
        // Concurrent context" warnings. Move it onto a detached task
        // and resume the continuation from there.
        await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let request = VNRecognizeTextRequest { request, _ in
                    let observations = request.results as? [VNRecognizedTextObservation] ?? []
                    let lines = observations
                        .compactMap { $0.topCandidates(1).first?.string }
                    continuation.resume(returning: lines)
                }
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = false
                request.recognitionLanguages = ["en-US"]

                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    // MARK: - Parsing
    //
    // The parser scans every line for each field independently, then
    // also checks paired labels like "GATE: B23". This is intentionally
    // permissive — boarding passes from different airlines vary wildly
    // in layout, and false-negative is cheaper than false-positive
    // since the user reviews the result before saving.

    static func parse(lines: [String]) -> TicketDraft {
        var draft = TicketDraft()
        let joined = lines.joined(separator: " ")
        let upper = joined.uppercased()

        if let code = findConfirmationCode(in: lines, joinedUpper: upper) {
            draft.confirmationCode = code
        }
        if let seat = findSeat(in: lines, joinedUpper: upper) {
            draft.seat = seat
        }
        if let gate = findGate(in: lines, joinedUpper: upper) {
            draft.gate = gate
        }
        if let holder = findHolderName(in: lines) {
            draft.holderName = holder
        }
        if let flight = findFlightNumber(in: lines, joinedUpper: upper) {
            // Prefer flight number as the ticket label when we have one
            // and the user hasn't typed a custom one in yet — useful
            // for the Tickets section glance.
            if draft.name.isEmpty {
                draft.name = "Flight \(flight)"
            }
        } else if looksLikeFlightTicket(joined: joined) && draft.name.isEmpty {
            draft.name = "Boarding pass"
        }

        return draft
    }

    private static let confirmationRegex = #/\b([A-Z0-9]{6,8})\b/#
    private static let labelledConfirmationRegex = #/(?:CONFIRMATION|RECORD\s*LOCATOR|BOOKING\s*REF|PNR)[:\s]+([A-Z0-9-]{5,12})/#
    private static let seatRegex = #/\b(\d{1,3}[A-K])\b/#
    private static let labelledSeatRegex = #/SEAT[:\s]+(\d{1,3}[A-KL]?)/#
    private static let gateRegex = #/\bGATE\s*[:#]?\s*([A-Z]?\d{1,3}[A-Z]?)\b/#
    private static let flightNumberRegex = #/\b([A-Z]{2,3})\s*([0-9]{1,4})\b/#

    // MARK: - Time / date parsing
    //
    // Boarding passes vary wildly in how they print times: "10:35 AM",
    // "10:35", "1035", "1035A", and pretty much every separator under
    // the sun. We use `NSDataDetector` (which Apple maintains) for the
    // primary date/time pass, then fall back to regex extraction so
    // 24-hour times without dates still come through.

    private static func parseInterval(lines: [String]) -> DateInterval? {
        let joined = lines.joined(separator: "\n")
        let date = findDate(in: joined, lines: lines)
        let labelledTimes = findLabelledTimes(in: lines)

        let departure = labelledTimes.departure
        let arrival = labelledTimes.arrival

        // Need at least a departure time to be useful.
        guard let depTime = departure else { return nil }

        let depDate = combine(date: date ?? Date(), time: depTime)
        let arrDate: Date = {
            if let arrival {
                var combined = combine(date: date ?? depDate, time: arrival)
                // Roll past midnight if arrival looks earlier than
                // departure (common red-eye case).
                if combined <= depDate {
                    combined = Calendar.current.date(byAdding: .day, value: 1, to: combined) ?? combined
                }
                return combined
            }
            return depDate.addingTimeInterval(2 * 3600)
        }()

        return DateInterval(start: depDate, end: arrDate)
    }

    /// Find the first date in the OCR output via `NSDataDetector`, or
    /// scan lines with month-name + day shapes when the detector misses.
    private static func findDate(in joined: String, lines: [String]) -> Date? {
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) {
            let range = NSRange(joined.startIndex..., in: joined)
            for match in detector.matches(in: joined, options: [], range: range) {
                if let date = match.date { return Calendar.current.startOfDay(for: date) }
            }
        }
        return nil
    }

    private struct LabelledTimes {
        var departure: DateComponents?
        var arrival: DateComponents?
    }

    private static func findLabelledTimes(in lines: [String]) -> LabelledTimes {
        var result = LabelledTimes()
        for (index, line) in lines.enumerated() {
            let upper = line.uppercased()

            // Departure-aliases for flights, trains, buses, events.
            if result.departure == nil,
               isDepartureLine(upper) {
                if let time = firstTime(in: line)
                    ?? lookAheadTime(after: index, in: lines)
                {
                    result.departure = time
                }
            }

            if result.arrival == nil,
               isArrivalLine(upper) {
                if let time = firstTime(in: line)
                    ?? lookAheadTime(after: index, in: lines)
                {
                    result.arrival = time
                }
            }
        }

        // Fallback: if we still have no departure, take the first
        // standalone time on the ticket — typical layouts lead with
        // the departure prominently.
        if result.departure == nil {
            for line in lines {
                if let time = firstTime(in: line) {
                    result.departure = time
                    break
                }
            }
        }
        return result
    }

    private static func isDepartureLine(_ upper: String) -> Bool {
        let signals = [
            "DEPART", "DEPARTURE", "DEPARTS", "DEP ", "LEAVES",
            "BOARDING", "DOORS OPEN", "START TIME", "SHOW STARTS"
        ]
        return signals.contains { upper.contains($0) }
    }

    private static func isArrivalLine(_ upper: String) -> Bool {
        let signals = [
            "ARRIV", "ARRIVAL", "ARRIVES", "ARR ", "LANDS",
            "ENDS", "DOORS CLOSE", "END TIME", "SHOW ENDS"
        ]
        return signals.contains { upper.contains($0) }
    }

    private static func lookAheadTime(after index: Int, in lines: [String], window: Int = 2) -> DateComponents? {
        let upperBound = min(lines.count, index + 1 + window)
        for i in (index + 1)..<upperBound {
            if let time = firstTime(in: lines[i]) {
                return time
            }
        }
        return nil
    }

    /// 12- and 24-hour time matcher. Returns `(hour, minute)` in 24h.
    private static let twelveHourTimeRegex = #/\b(\d{1,2}):(\d{2})\s*(AM|PM|A|P)\b/#
    private static let twentyFourHourTimeRegex = #/\b([01]?\d|2[0-3]):([0-5]\d)\b/#
    private static let compactAirlineTimeRegex = #/\b(\d{4})\s*(A|P)\b/#

    private static func firstTime(in line: String) -> DateComponents? {
        let upper = line.uppercased()
        if let match = try? twelveHourTimeRegex.firstMatch(in: upper) {
            let hour = Int(match.output.1) ?? 0
            let minute = Int(match.output.2) ?? 0
            let isPM = String(match.output.3).hasPrefix("P")
            let normalized = normalize12HourHour(hour, isPM: isPM)
            return DateComponents(hour: normalized, minute: minute)
        }
        if let match = try? twentyFourHourTimeRegex.firstMatch(in: upper) {
            let hour = Int(match.output.1) ?? 0
            let minute = Int(match.output.2) ?? 0
            return DateComponents(hour: hour, minute: minute)
        }
        if let match = try? compactAirlineTimeRegex.firstMatch(in: upper) {
            // 4-digit airline format: "1035A" / "1035P".
            let digits = String(match.output.1)
            guard digits.count == 4 else { return nil }
            let hour = Int(digits.prefix(2)) ?? 0
            let minute = Int(digits.suffix(2)) ?? 0
            let isPM = String(match.output.2) == "P"
            let normalized = normalize12HourHour(hour, isPM: isPM)
            return DateComponents(hour: normalized, minute: minute)
        }
        return nil
    }

    private static func normalize12HourHour(_ hour: Int, isPM: Bool) -> Int {
        // 12 AM = midnight (0); 12 PM = noon (12); 1-11 PM = + 12.
        if hour == 12 { return isPM ? 12 : 0 }
        return isPM ? hour + 12 : hour
    }

    private static func combine(date: Date, time: DateComponents) -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = time.hour ?? 0
        comps.minute = time.minute ?? 0
        comps.second = 0
        return cal.date(from: comps) ?? date
    }

    private static func findConfirmationCode(in lines: [String], joinedUpper: String) -> String? {
        // Prefer labelled matches — they're unambiguous.
        if let match = try? labelledConfirmationRegex
            .firstMatch(in: joinedUpper)
        {
            return String(match.output.1)
        }
        // Otherwise, pick the most code-shaped token from a line that
        // looks like a confirmation row.
        for line in lines {
            let upper = line.uppercased()
            if upper.contains("CONFIRMATION") || upper.contains("PNR")
                || upper.contains("RECORD LOCATOR") || upper.contains("BOOKING")
            {
                if let match = try? confirmationRegex.firstMatch(in: upper) {
                    return String(match.output.1)
                }
            }
        }
        return nil
    }

    private static func findSeat(in lines: [String], joinedUpper: String) -> String? {
        if let match = try? labelledSeatRegex.firstMatch(in: joinedUpper) {
            return String(match.output.1)
        }
        for line in lines {
            let upper = line.uppercased()
            if upper.contains("SEAT") {
                if let match = try? seatRegex.firstMatch(in: upper) {
                    return String(match.output.1)
                }
            }
        }
        return nil
    }

    private static func findGate(in lines: [String], joinedUpper: String) -> String? {
        if let match = try? gateRegex.firstMatch(in: joinedUpper) {
            return String(match.output.1)
        }
        return nil
    }

    private static func findFlightNumber(in lines: [String], joinedUpper: String) -> String? {
        // Look on lines explicitly mentioning "FLIGHT" to avoid grabbing
        // random PNR-shaped tokens.
        for line in lines {
            let upper = line.uppercased()
            if upper.contains("FLIGHT") || upper.contains("FLT") {
                if let match = try? flightNumberRegex.firstMatch(in: upper) {
                    let prefix = String(match.output.1)
                    let number = String(match.output.2)
                    return "\(prefix) \(number)"
                }
            }
        }
        return nil
    }

    private static func findHolderName(in lines: [String]) -> String? {
        for (index, line) in lines.enumerated() {
            let upper = line.uppercased()
            if upper.contains("PASSENGER") || upper.contains("NAME OF") {
                // The name usually follows on the next line, or after a
                // separator on this one.
                if let separator = line.firstIndex(where: { $0 == ":" }) {
                    let candidate = line[line.index(after: separator)...]
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if isPlausibleName(candidate) { return candidate }
                }
                if index + 1 < lines.count {
                    let candidate = lines[index + 1]
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    if isPlausibleName(candidate) { return candidate }
                }
            }
        }
        return nil
    }

    private static func isPlausibleName(_ s: String) -> Bool {
        let stripped = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard stripped.count >= 3, stripped.count <= 60 else { return false }
        // Must contain at least one space and only letters / apostrophes / hyphens.
        guard stripped.contains(" ") else { return false }
        let allowed = stripped.unicodeScalars.allSatisfy { scalar in
            CharacterSet.letters.contains(scalar)
                || CharacterSet.whitespaces.contains(scalar)
                || scalar == "'" || scalar == "-"
        }
        return allowed
    }

    private static func looksLikeFlightTicket(joined: String) -> Bool {
        let upper = joined.uppercased()
        let signals = ["BOARDING PASS", "FLIGHT", "GATE", "DEPARTURE", "AIRLINE"]
        return signals.contains { upper.contains($0) }
    }
}
