//
//  UserDefaultsUserWalletRegistrationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class Foundation.UserDefaults
import struct Foundation.UUID
import struct TangemFoundation.UserWalletId

/// - Note: besides the fact that UserDefaults operations are individually thread-safe,
/// ``persist(registeredID:)`` and ``remove(registeredID:)`` are not atomic.
actor UserDefaultsUserWalletRegistrationStatusRepository: UserWalletRegistrationStatusRepository {
    private static let key = "com.tangem.backendAuthentication.registeredUserWalletIDs"

    private let userDefaults: UserDefaults
    private var subscribers: [UUID: Subscriber] = [:]

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        assert(type(of: userDefaults) == UserDefaults.self, "Expected a non-subclassed UserDefaults instance.")

        self.userDefaults = userDefaults
    }

    func retrieve(id: UserWalletId) -> Bool {
        retrieveRegisteredUserWalletIDs().contains(id.hashedStringValue(message: Self.key))
    }

    func updates(id: UserWalletId) -> AsyncStream<Bool> {
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self, bufferingPolicy: .bufferingNewest(1))
        let subscriberID = UUID()

        subscribers[subscriberID] = Subscriber(hashedID: id.hashedStringValue(message: Self.key), continuation: continuation)
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeSubscriber(id: subscriberID) }
        }
        continuation.yield(retrieve(id: id))

        return stream
    }

    func persist(registeredID: UserWalletId) {
        var registeredUserWalletIDs = retrieveRegisteredUserWalletIDs()
        registeredUserWalletIDs.insert(registeredID.hashedStringValue(message: Self.key))
        persist(registeredUserWalletIDs: registeredUserWalletIDs)
    }

    func replaceAll(with newRegisteredIDs: [UserWalletId]) {
        let registeredUserWalletIDs = Set(newRegisteredIDs.map { $0.hashedStringValue(message: Self.key) })
        persist(registeredUserWalletIDs: registeredUserWalletIDs)
    }

    func remove(registeredID: UserWalletId) {
        var registeredUserWalletIDs = retrieveRegisteredUserWalletIDs()
        registeredUserWalletIDs.remove(registeredID.hashedStringValue(message: Self.key))
        persist(registeredUserWalletIDs: registeredUserWalletIDs)
    }

    private func retrieveRegisteredUserWalletIDs() -> Set<String> {
        Set(userDefaults.stringArray(forKey: Self.key) ?? [])
    }

    private func persist(registeredUserWalletIDs: Set<String>) {
        userDefaults.set(Array(registeredUserWalletIDs), forKey: Self.key)

        for subscriber in subscribers.values {
            subscriber.continuation.yield(registeredUserWalletIDs.contains(subscriber.hashedID))
        }
    }

    private func removeSubscriber(id: UUID) {
        subscribers[id] = nil
    }
}

private extension UserDefaultsUserWalletRegistrationStatusRepository {
    struct Subscriber {
        let hashedID: String
        let continuation: AsyncStream<Bool>.Continuation
    }
}
