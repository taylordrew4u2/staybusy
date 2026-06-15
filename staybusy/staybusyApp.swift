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
            container = try ModelContainer(
                for: Block.self, Ticket.self, BlockAttachment.self, Trip.self,
                configurations: cloudConfig
            )
        } catch {
            // CloudKit setup can fail when iCloud isn't signed in, the container
            // isn't provisioned, or the simulator can't reach CloudKit. Fall back
            // to a local-only store so the app still launches.
            do {
                let localConfig = ModelConfiguration(url: storeURL)
                container = try ModelContainer(
                    for: Block.self, Ticket.self, BlockAttachment.self, Trip.self,
                    configurations: localConfig
                )
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }

    enum StayBusyCloudKit {
        static let containerIdentifier = "iCloud.com.staybusy.app"
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    UbiquitousSettings.shared.start()
                    SampleData.purgeSeededBlocksIfNeeded(context: container.mainContext)
                    await syncCalendarIfEnabled()
                    // Catch up any pre-existing imported blocks whose
                    // location strings never got coordinates — they'd
                    // otherwise be invisible on the map.
                    await GeocodingService.shared
                        .geocodeMissingCoordinates(in: container.mainContext)
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        Task { await syncCalendarIfEnabled() }
                    }
                }
        }
        .modelContainer(container)
    }

    /// Pull Calendar events into the local store when the user has
    /// opted in. Runs on launch and on each `.active` scenePhase
    /// transition. When the user has an active trip we sync scoped to
    /// that trip's date range and attach pulled events to it; with no
    /// active trip we fall back to the rolling default window.
    @MainActor
    private func syncCalendarIfEnabled() async {
        let enabled = UserDefaults.standard.bool(forKey: "calendarSyncEnabled")
        guard enabled else { return }
        let service = CalendarSyncService.shared
        guard service.isAuthorized else { return }
        let context = container.mainContext
        await service.sync(context: context, trip: activeTrip(in: context))
    }

    /// Resolve the persisted `activeTripID` to its `Trip` model in the
    /// given context, falling back to the most recent trip when the
    /// stored ID doesn't match anything.
    @MainActor
    private func activeTrip(in context: ModelContext) -> Trip? {
        let descriptor = FetchDescriptor<Trip>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        guard let trips = try? context.fetch(descriptor), !trips.isEmpty else {
            return nil
        }
        let raw = UserDefaults.standard.string(forKey: "activeTripID") ?? ""
        if let id = PersistentIdentifier.decode(raw),
           let trip = trips.first(where: { $0.persistentModelID == id }) {
            return trip
        }
        return trips.first
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
