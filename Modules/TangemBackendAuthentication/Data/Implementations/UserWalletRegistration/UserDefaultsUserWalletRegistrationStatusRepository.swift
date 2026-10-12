//
//  UserDefaultsUserWalletRegistrationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class Foundation.UserDefaults
import struct TangemFoundation.UserWalletId

/// - Note: besides the fact that UserDefaults operations are individually thread-safe,
/// ``persist(registeredID:)`` and ``remove(registeredID:)`` are not atomic.
actor UserDefaultsUserWalletRegistrationStatusRepository: UserWalletRegistrationStatusRepository {
    private static let key = "com.tangem.backendAuthentication.registeredUserWalletIDs"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        assert(type(of: userDefaults) == UserDefaults.self, "Expected a non-subclassed UserDefaults instance.")

        self.userDefaults = userDefaults
    }

    func retrieve(id: UserWalletId) -> Bool {
        retrieveRegisteredUserWalletIDs().contains(id.hashedStringValue(message: Self.key))
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
    }
}
