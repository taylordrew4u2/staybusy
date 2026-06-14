//
//  staybusyApp.swift
//  staybusy
//

import SwiftUI
import SwiftData

@main
struct staybusyApp: App {
    let container: ModelContainer

    init() {
        let storeURL = staybusyApp.makeStoreURL()
        let cloudConfig = ModelConfiguration(
            url: storeURL,
            cloudKitDatabase: .private(StayBusyCloudKit.containerIdentifier)
        )
        do {
            container = try ModelContainer(for: Block.self, configurations: cloudConfig)
        } catch {
            // CloudKit setup can fail when iCloud isn't signed in, the container
            // isn't provisioned, or the simulator can't reach CloudKit. Fall back
            // to a local-only store so the app still launches.
            do {
                let localConfig = ModelConfiguration(url: storeURL)
                container = try ModelContainer(for: Block.self, configurations: localConfig)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
        #if DEBUG
        SampleData.seedIfNeeded(context: container.mainContext)
        #endif
    }

    enum StayBusyCloudKit {
        static let containerIdentifier = "iCloud.com.staybusy.app"
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }

    /// Stores the SQLite file in the App Group container so the widget extension
    /// can read the same data. Falls back to Application Support when the App
    /// Group capability hasn't been added yet (the widget won't see data in that
    /// fallback, but the main app still works).
    private static func makeStoreURL() -> URL {
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: StayBusyAppGroup.identifier
        ) {
            return groupURL.appendingPathComponent("staybusy.sqlite")
        }
        let support = (try? FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("staybusy.sqlite")
    }
}
