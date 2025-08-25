//
//  KeychainCleaner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Security

enum KeychainCleaner {
    static func cleanAllData() {
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity,
        ]

        for itemClass in secItemClasses {
            let query: [String: Any] = [kSecClass as String: itemClass]
            SecItemDelete(query as CFDictionary)
        }
    }
}
