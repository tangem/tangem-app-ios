//
//  UserDefaultsDeviceRegistrationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class Foundation.UserDefaults

struct UserDefaultsDeviceRegistrationStatusRepository: DeviceRegistrationStatusRepository {
    private static let key = "com.tangem.backendAuthentication.isDeviceRegistered"

    /// UserDefaults is documented as thread-safe, but Swift can't verify that of arbitrary subclasses.
    /// Safe here as long as callers only ever pass the base class, not a subclass.
    private nonisolated(unsafe) let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    func retrieve() -> Bool {
        userDefaults.bool(forKey: Self.key)
    }

    func persist(isRegistered: Bool) {
        userDefaults.set(isRegistered, forKey: Self.key)
    }
}
