//
//  LiveActivityAttributes.swift
//  staybusy
//
//  Shared between the app target and the widget extension target.
//  Add this file to BOTH targets via Xcode's File Inspector.
//

import ActivityKit
import Foundation

public struct StayBusyActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var currentTitle: String?
        public var currentStart: Date?
        public var currentEnd: Date?
        public var currentCategoryRaw: String?
        public var currentLocationName: String?

        public var nextTitle: String?
        public var nextStart: Date?
        public var nextCategoryRaw: String?

        public init(
            currentTitle: String? = nil,
            currentStart: Date? = nil,
            currentEnd: Date? = nil,
            currentCategoryRaw: String? = nil,
            currentLocationName: String? = nil,
            nextTitle: String? = nil,
            nextStart: Date? = nil,
            nextCategoryRaw: String? = nil
        ) {
            self.currentTitle = currentTitle
            self.currentStart = currentStart
            self.currentEnd = currentEnd
            self.currentCategoryRaw = currentCategoryRaw
            self.currentLocationName = currentLocationName
            self.nextTitle = nextTitle
            self.nextStart = nextStart
            self.nextCategoryRaw = nextCategoryRaw
        }
    }

    public init() {}
}

public enum StayBusyAppGroup {
    public static let identifier = "group.com.staybusy.app"
}
