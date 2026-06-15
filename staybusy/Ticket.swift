//
//  Ticket.swift
//  staybusy
//
//  A structured ticket attached to a Block — boarding pass, event entry,
//  ride reservation, etc. Captures the fields you reach for in the
//  moment: confirmation code, seat, gate, who it's for. Distinct from
//  the generic file attachments on Block so the data stays searchable
//  and copy-pasteable (instead of locked inside a PDF).
//

import Foundation
import SwiftData

@Model
final class Ticket {
    /// Short label shown in the Tickets section — e.g. "Flight", "Show",
    /// "Boarding pass". Optional; falls back to category-driven default
    /// in the UI when empty.
    var name: String = ""

    /// The code passengers copy & paste — confirmation number,
    /// reservation, record locator.
    var confirmationCode: String = ""

    /// Seat assignment (e.g. "12A", "GA"). Empty when not relevant.
    var seat: String = ""

    /// Gate / door / entrance (e.g. "B23", "Stage door").
    var gate: String = ""

    /// Who the ticket is for, when it isn't obvious. Useful for group
    /// trips and ride-share pickups.
    var holderName: String = ""

    /// Sort order within a block's ticket list — preserves the user's
    /// arrangement when there are multiple tickets per block.
    var sortOrder: Int = 0

    /// Parent block. Optional because CloudKit + SwiftData require the
    /// inverse side of the relationship to be nullable.
    var block: Block?

    init(
        name: String = "",
        confirmationCode: String = "",
        seat: String = "",
        gate: String = "",
        holderName: String = "",
        sortOrder: Int = 0
    ) {
        self.name = name
        self.confirmationCode = confirmationCode
        self.seat = seat
        self.gate = gate
        self.holderName = holderName
        self.sortOrder = sortOrder
    }

    /// True when there's nothing worth showing — used to gate empty
    /// tickets from saving and from rendering.
    var isEmpty: Bool {
        name.isEmpty
            && confirmationCode.isEmpty
            && seat.isEmpty
            && gate.isEmpty
            && holderName.isEmpty
    }
}
