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

enum TicketScanner {
    /// Run OCR on a UIImage and return a draft populated with anything
    /// we could confidently parse. Empty fields = nothing detected for
    /// that slot; the caller should keep the user's existing values for
    /// those.
    static func scan(_ image: UIImage) async -> TicketDraft {
        guard let cgImage = image.cgImage else { return TicketDraft() }

        let lines = await recognizeText(in: cgImage)
        guard !lines.isEmpty else { return TicketDraft() }

        return parse(lines: lines)
    }

    // MARK: - Vision

    private static func recognizeText(in cgImage: CGImage) async -> [String] {
        await withCheckedContinuation { continuation in
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
