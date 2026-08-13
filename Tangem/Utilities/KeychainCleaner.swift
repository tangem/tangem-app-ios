//
//  KeychainCleaner.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Security
import TangemSdk
import TangemMobileWalletSdk

/// Wipes the Keychain state left over from a previous install. Called once on the app's first launch.
///
/// The Keychain is enumerated once here and the results are handed to each owner, which deletes only the
/// items it recognizes by its own keys. The backup payload is preserved by `TangemSdkSecureStorageCleaner`.
enum KeychainCleaner {
    static func cleanAllData() {
        TangemSdkSecureStorageCleaner().clean()

        let genericPasswordAccounts = allGenericPasswordAccounts()
        let secureEnclaveKeyTags = allSecureEnclaveKeyTags()

        MobileWalletSecureStorageCleaner().clean(
            genericPasswordAccounts: genericPasswordAccounts,
            secureEnclaveKeyTags: secureEnclaveKeyTags
        )

        UserWalletDataStorage().clean()
        UserWalletEncryptionKeyStorage().clean(genericPasswordAccounts: genericPasswordAccounts)
        FileEncryptionUtility().clean()
        SupportChatTokenStorage().clean()
        CommonVisaRefreshTokenRepository().clean(genericPasswordAccounts: genericPasswordAccounts)
        CommonTangemPayAuthorizationTokensRepository().clean(genericPasswordAccounts: genericPasswordAccounts)
        CommonMobileAccessCodeStorageManager().clean(
            genericPasswordAccounts: genericPasswordAccounts,
            secureEnclaveKeyTags: secureEnclaveKeyTags
        )
    }

    private static func allGenericPasswordAccounts() -> [String] {
        allItems(ofClass: kSecClassGenericPassword, attribute: kSecAttrAccount)
    }

    private static func allSecureEnclaveKeyTags() -> [String] {
        allItems(ofClass: kSecClassKey, attribute: kSecAttrApplicationTag)
    }

    private static func allItems(ofClass itemClass: CFString, attribute: CFString) -> [String] {
        let query: [String: Any] = [
            kSecClass as String: itemClass,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true,
        ]

        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }

        return items.compactMap { item -> String? in
            guard let value = item[attribute as String] else {
                return nil
            }

            if let data = value as? Data {
                return String(data: data, encoding: .utf8)
            }

            return value as? String
        }
    }
}
