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

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        assert(type(of: userDefaults) == UserDefaults.self, "Expected a non-subclassed UserDefaults instance.")

        self.userDefaults = userDefaults
    }

    func retrieve() -> Bool {
        userDefaults.bool(forKey: Self.key)
    }

    func persist(isRegistered: Bool) {
        userDefaults.set(isRegistered, forKey: Self.key)
    }
}
