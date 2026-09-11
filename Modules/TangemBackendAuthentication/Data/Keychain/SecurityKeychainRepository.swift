//
//  SecurityKeychainRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import struct Foundation.Data
private import Security

struct SecurityKeychainRepository: KeychainRepository {
    private let keychainService: String
    private let keychainAccount: String
    private let keychainFunctions: KeychainFunctions

    init(keychainService: String, keychainAccount: String, keychainFunctions: KeychainFunctions = .securityFramework) {
        self.keychainService = keychainService
        self.keychainAccount = keychainAccount
        self.keychainFunctions = keychainFunctions
    }

    @concurrent
    func insert(_ data: Data) async throws(KeychainRepositoryError) {
        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecUseDataProtectionKeychain: true,
        ]

        let status = keychainFunctions.secItemAdd(attributes as CFDictionary, nil)

        switch status {
        case errSecSuccess:
            return

        case errSecDuplicateItem:
            throw KeychainRepositoryError.duplicateItem

        default:
            throw KeychainRepositoryError.insertFailed(status: status)
        }
    }

    @concurrent
    func retrieve() async throws(KeychainRepositoryError) -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true,
            kSecUseDataProtectionKeychain: true,
        ]

        var result: CFTypeRef?
        let status = keychainFunctions.secItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw KeychainRepositoryError.itemCorrupted
            }

            return data

        case errSecItemNotFound:
            return nil

        default:
            throw KeychainRepositoryError.retrieveFailed(status: status)
        }
    }

    @concurrent
    func update(_ data: Data) async throws(KeychainRepositoryError) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecMatchLimit: kSecMatchLimitOne,
            kSecUseDataProtectionKeychain: true,
        ]
        let attributesToUpdate: [CFString: Any] = [kSecValueData: data]

        let status = keychainFunctions.secItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)

        guard status == errSecSuccess else {
            throw KeychainRepositoryError.updateFailed(status: status)
        }
    }

    @concurrent
    func delete() async throws(KeychainRepositoryError) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keychainAccount,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecUseDataProtectionKeychain: true,
        ]

        let status = keychainFunctions.secItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainRepositoryError.deleteFailed(status: status)
        }
    }
}

extension SecurityKeychainRepository {
    struct KeychainFunctions: Sendable {
        /// Adds one or more items to a keychain.
        let secItemAdd: @Sendable (_ attributes: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus

        /// Modifies items that match a search query.
        let secItemUpdate: @Sendable (_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus

        /// Returns one or more keychain items that match a search query, or copies attributes of specific keychain items.
        let secItemCopyMatching: @Sendable (_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus

        /// Deletes items that match a search query.
        let secItemDelete: @Sendable (_ query: CFDictionary) -> OSStatus

        static let securityFramework = KeychainFunctions(
            secItemAdd: Security.SecItemAdd,
            secItemUpdate: Security.SecItemUpdate,
            secItemCopyMatching: Security.SecItemCopyMatching,
            secItemDelete: Security.SecItemDelete
        )
    }
}
