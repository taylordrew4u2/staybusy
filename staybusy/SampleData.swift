//
//  SampleData.swift
//  staybusy
//

import Foundation
import SwiftData

enum SampleData {
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Block>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let tomorrow = cal.date(byAdding: .day, value: 1, to: today) else { return }

        func at(_ day: Date, _ hour: Int, _ minute: Int = 0) -> Date {
            cal.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }

        // (block, tickets-to-attach) — tickets are inserted after the
        // block so the relationship can be set in one place.
        let plan: [(Block, [Ticket])] = [
            (
                Block(
                    title: "Hotel breakfast",
                    start: at(today, 8, 0),
                    end: at(today, 9, 0),
                    category: .food,
                    locationName: "The Standard",
                    address: "25 Cooper Square, New York, NY",
                    cost: 28,
                    phone: "(212) 475-5700",
                    website: "standardhotels.com"
                ),
                []
            ),
            (
                Block(
                    title: "Travel to venue",
                    start: at(today, 11, 30),
                    end: at(today, 12, 30),
                    category: .travel,
                    locationName: "Brooklyn Steel",
                    cost: 32,
                    currencyCode: "USD"
                ),
                []
            ),
            (
                Block(
                    title: "Soundcheck",
                    start: at(today, 14, 0),
                    end: at(today, 15, 30),
                    category: .gig,
                    locationName: "Brooklyn Steel",
                    address: "319 Frost St, Brooklyn, NY",
                    confirmationCode: "BS-44721",
                    notes: "Backline ready. Talk to Mara about monitors.",
                    phone: "(347) 529-6696",
                    website: "bkstl.com"
                ),
                [
                    Ticket(
                        name: "Crew pass",
                        confirmationCode: "BS-44721",
                        holderName: "Crew",
                        sortOrder: 0
                    )
                ]
            ),
            (
                Block(
                    title: "Green room rest",
                    start: at(today, 16, 0),
                    end: at(today, 18, 30),
                    category: .rest,
                    locationName: "Brooklyn Steel"
                ),
                []
            ),
            (
                Block(
                    title: "Show",
                    start: at(today, 21, 0),
                    end: at(today, 23, 0),
                    category: .gig,
                    locationName: "Brooklyn Steel",
                    notes: "Doors 8, openers 8:30, on stage 9."
                ),
                []
            ),
            (
                Block(
                    title: "Flight LGA → ORD",
                    start: at(tomorrow, 9, 30),
                    end: at(tomorrow, 12, 0),
                    category: .travel,
                    locationName: "LaGuardia Airport",
                    confirmationCode: "DL-AB12CD",
                    cost: 248,
                    phone: "(800) 221-1212",
                    website: "delta.com"
                ),
                [
                    Ticket(
                        name: "Boarding pass",
                        confirmationCode: "DL-AB12CD",
                        seat: "12A",
                        gate: "B23",
                        holderName: "You",
                        sortOrder: 0
                    )
                ]
            ),
            (
                Block(
                    title: "Lunch w/ promoter",
                    start: at(tomorrow, 13, 30),
                    end: at(tomorrow, 14, 45),
                    category: .social,
                    locationName: "Au Cheval",
                    address: "800 W Randolph St, Chicago, IL",
                    cost: 65,
                    phone: "(312) 929-4580",
                    website: "auchevaldiner.com"
                ),
                []
            ),
            (
                Block(
                    title: "Radio interview",
                    start: at(tomorrow, 16, 0),
                    end: at(tomorrow, 16, 45),
                    category: .work,
                    locationName: "WBEZ Studios"
                ),
                [
                    Ticket(
                        name: "Studio entry",
                        confirmationCode: "WBEZ-5512",
                        gate: "North entrance",
                        holderName: "Guest list",
                        sortOrder: 0
                    )
                ]
            ),
        ]

        for (block, tickets) in plan {
            context.insert(block)
            for ticket in tickets {
                ticket.block = block
                context.insert(ticket)
            }
        }
    }
}
