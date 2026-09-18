//
//  UserDefaultsUserWalletRegistrationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class Foundation.UserDefaults
import struct TangemFoundation.UserWalletId

/// - Note: besides the fact that UserDefaults operations are individually thread-safe, ``persist(isRegistered:id:)`` is not atomic.
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

    func persist(isRegistered: Bool, id: UserWalletId) {
        var registeredUserWalletIDs = retrieveRegisteredUserWalletIDs()

        if isRegistered {
            registeredUserWalletIDs.insert(id.hashedStringValue(message: Self.key))
        } else {
            registeredUserWalletIDs.remove(id.hashedStringValue(message: Self.key))
        }

        userDefaults.set(Array(registeredUserWalletIDs), forKey: Self.key)
    }

    private func retrieveRegisteredUserWalletIDs() -> Set<String> {
        Set(userDefaults.stringArray(forKey: Self.key) ?? [])
    }
}
