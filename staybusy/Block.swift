//
//  Block.swift
//  staybusy
//

import Foundation
import SwiftData

@Model
final class Block {
    var title: String
    var start: Date
    var end: Date
    var categoryRaw: String
    var locationName: String
    var address: String
    var latitude: Double?
    var longitude: Double?
    var confirmationCode: String
    var notes: String
    var links: [String]
    var attachmentFilenames: [String]

    var category: BlockCategory {
        get { BlockCategory(rawValue: categoryRaw) ?? .admin }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        title: String,
        start: Date,
        end: Date,
        category: BlockCategory,
        locationName: String = "",
        address: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        confirmationCode: String = "",
        notes: String = "",
        links: [String] = [],
        attachmentFilenames: [String] = []
    ) {
        self.title = title
        self.start = start
        self.end = end
        self.categoryRaw = category.rawValue
        self.locationName = locationName
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.confirmationCode = confirmationCode
        self.notes = notes
        self.links = links
        self.attachmentFilenames = attachmentFilenames
    }
}
