//
//  MobileWalletSecureStorageCleaner.swift
//  TangemMobileWalletSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Security
import TangemFoundation

/// Deletes every Keychain item the mobile wallet SDK persists — private info, encryption keys and public info,
/// together with their Secure Enclave keys. The caller passes in the already-enumerated Keychain contents;
/// items are matched by the SDK's own key prefixes, which cover the biometrics and Secure Enclave variants too.
public struct MobileWalletSecureStorageCleaner {
    private let keychainItemPrefixes: [String] = [
        UserWalletId.Constants.privateInfoPrefix,
        UserWalletId.Constants.encryptionKeyPrefix,
        UserWalletId.Constants.publicInfoPrefix,
    ]

    public init() {}

    public func clean(genericPasswordAccounts: [String], secureEnclaveKeyTags: [String]) {
        for account in genericPasswordAccounts where hasKnownPrefix(account) {
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: account,
            ]
            _ = SecItemDelete(deleteQuery as CFDictionary)
        }

        for tag in secureEnclaveKeyTags where hasKnownPrefix(tag) {
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: tag,
                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            ]
            _ = SecItemDelete(deleteQuery as CFDictionary)
        }
    }

    private func hasKnownPrefix(_ value: String) -> Bool {
        keychainItemPrefixes.contains { value.hasPrefix($0) }
    }
}
