//
//  UserWalletIdSpoofer.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public final class UserWalletIdSpoofer: @unchecked Sendable {
    public static let shared = UserWalletIdSpoofer()

    public let storageKey = "user_wallet_id_spoof_map"
    public let userDefaults: UserDefaults = .standard

    private init() {}

    func resolve(_ originalValue: Data) -> Data? {
        guard AppEnvironment.current.isInternalOrDebug else {
            return nil
        }

        let originalHex = originalValue.hexEncodedString
        let map = (userDefaults.dictionary(forKey: storageKey) as? [String: Data]) ?? [:]

        return map[originalHex]
    }
}
