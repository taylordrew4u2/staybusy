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
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: false)
            container = try ModelContainer(for: Block.self, configurations: config)
            #if DEBUG
            SampleData.seedIfNeeded(context: container.mainContext)
            #endif
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
