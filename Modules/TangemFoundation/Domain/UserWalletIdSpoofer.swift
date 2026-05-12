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
        // Skip in test contexts so a spoof entry left in the simulator's UserDefaults from a
        // prior dev session can't silently affect XCTest / Swift Testing runs that share the
        // host app's defaults.
        guard AppEnvironment.current.isInternalOrDebug,
              !AppEnvironment.current.isUnitTest else {
            return nil
        }

        let originalHex = originalValue.hexString
        let map = (userDefaults.dictionary(forKey: storageKey) as? [String: Data]) ?? [:]

        return map[originalHex]
    }
}
