//
//  UserDefaultsAppAttestationStatusRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import class Foundation.UserDefaults

struct UserDefaultsAppAttestationStatusRepository: AppAttestationStatusRepository {
    private static let key = "com.tangem.backendAuthentication.isAppAttested"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = UserDefaults.standard) {
        assert(type(of: userDefaults) == UserDefaults.self, "Expected a non-subclassed UserDefaults instance.")

        self.userDefaults = userDefaults
    }

    func retrieve() -> Bool {
        userDefaults.bool(forKey: Self.key)
    }

    func persist(isAppAttested: Bool) {
        userDefaults.set(isAppAttested, forKey: Self.key)
    }
}
