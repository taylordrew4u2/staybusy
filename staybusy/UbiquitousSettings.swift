//
//  UbiquitousSettings.swift
//  staybusy
//
//  Mirrors a small set of `@AppStorage` keys to
//  `NSUbiquitousKeyValueStore` so user-facing preferences — theme,
//  calendar-sync toggle — show up the same way on every signed-in
//  device. SwiftUI binds to the same UserDefaults keys it always has;
//  this class just keeps the two stores in lockstep.
//
//  - Remote → local: listens for
//    `NSUbiquitousKeyValueStore.didChangeExternallyNotification`.
//  - Local → remote: listens for `UserDefaults.didChangeNotification`
//    and pushes any mirrored key that has drifted.
//

import Foundation

@MainActor
final class UbiquitousSettings: NSObject {
    static let shared = UbiquitousSettings()

    /// Keys mirrored to iCloud. Add cautiously — every key is round-
    /// tripped through KVS on every change.
    private let mirroredKeys: [String] = [
        "themeMode",
        "calendarSyncEnabled"
    ]

    private let cloud = NSUbiquitousKeyValueStore.default
    private var didStart = false
    /// Guards against the local-write trigger firing for a value we
    /// just wrote *from* a remote change (which would echo back up).
    private var suppressLocalPush = false

    private override init() {
        super.init()
    }

    func start() {
        guard !didStart else { return }
        didStart = true

        _ = cloud.synchronize()
        pullRemoteIntoLocal()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocalChange(_:)),
            name: UserDefaults.didChangeNotification,
            object: UserDefaults.standard
        )
    }

    // MARK: - Sync

    private func pullRemoteIntoLocal() {
        let defaults = UserDefaults.standard
        suppressLocalPush = true
        defer { suppressLocalPush = false }
        for key in mirroredKeys {
            guard let remote = cloud.object(forKey: key) else { continue }
            if let local = defaults.object(forKey: key),
               isEqual(local, remote) {
                continue
            }
            defaults.set(remote, forKey: key)
        }
    }

    private func pushLocalToRemote() {
        let defaults = UserDefaults.standard
        var didWrite = false
        for key in mirroredKeys {
            guard let local = defaults.object(forKey: key) else {
                if cloud.object(forKey: key) != nil {
                    cloud.removeObject(forKey: key)
                    didWrite = true
                }
                continue
            }
            if let remote = cloud.object(forKey: key), isEqual(local, remote) {
                continue
            }
            cloud.set(local, forKey: key)
            didWrite = true
        }
        if didWrite { _ = cloud.synchronize() }
    }

    @objc
    private func handleExternalChange(_ note: Notification) {
        Task { @MainActor in
            self.pullRemoteIntoLocal()
        }
    }

    @objc
    private func handleLocalChange(_ note: Notification) {
        guard !suppressLocalPush else { return }
        Task { @MainActor in
            self.pushLocalToRemote()
        }
    }

    private func isEqual(_ a: Any, _ b: Any) -> Bool {
        if let a = a as? NSObject, let b = b as? NSObject {
            return a.isEqual(b)
        }
        return false
    }
}
