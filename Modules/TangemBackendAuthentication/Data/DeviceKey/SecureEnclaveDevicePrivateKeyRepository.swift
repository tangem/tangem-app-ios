//
//  SecureEnclaveDevicePrivateKeyRepository.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private import CryptoKit
private import Foundation
private import Security

/// Loads the device's Secure Enclave-backed private key from the Keychain,
/// or generates and persists a new one if none exists yet.
struct SecureEnclaveDevicePrivateKeyRepository: DevicePrivateKeyRepository {
    private let keychainService: String
    private let keychainAccount: String

    init(keychainService: String, keychainAccount: String) {
        precondition(SecureEnclave.isAvailable)

        self.keychainService = keychainService
        self.keychainAccount = keychainAccount
    }

    /// - Warning: Avoid calling from the main thread directly.
    var privateKey: SecureEnclaveDevicePrivateKey {
        get throws(DevicePrivateKeyRepositoryError) {
            let privateKey: SecureEnclave.P256.Signing.PrivateKey

            if let existingKey = try loadFromKeychain() {
                privateKey = existingKey
            } else {
                privateKey = try generateAndStoreInKeychain()
            }

            return SecureEnclaveDevicePrivateKey(key: privateKey)
        }
    }

    func removePrivateKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecUseDataProtectionKeychain as String: true,
        ]

        _ = SecItemDelete(query as CFDictionary)
    }

    private func loadFromKeychain() throws(DevicePrivateKeyRepositoryError) -> SecureEnclave.P256.Signing.PrivateKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecUseDataProtectionKeychain as String: true,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess:
            guard let data = result as? Data else {
                throw DevicePrivateKeyRepositoryError.keychainItemCorrupted
            }

            do {
                return try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: data)
            } catch {
                throw DevicePrivateKeyRepositoryError.keyRestorationFailed(underlying: error)
            }

        case errSecItemNotFound:
            return nil

        default:
            throw DevicePrivateKeyRepositoryError.keychainQueryFailed(status: status)
        }
    }

    private func generateAndStoreInKeychain() throws(DevicePrivateKeyRepositoryError) -> SecureEnclave.P256.Signing.PrivateKey {
        let privateKey = try Self.generateKey()
        try storeKeyInKeychain(privateKey)

        return privateKey
    }

    private static func generateKey() throws(DevicePrivateKeyRepositoryError) -> SecureEnclave.P256.Signing.PrivateKey {
        var accessControlError: Unmanaged<CFError>?

        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .privateKeyUsage,
            &accessControlError
        ) else {
            let error = accessControlError?.takeRetainedValue()
            throw DevicePrivateKeyRepositoryError.keyGenerationFailed(underlying: error)
        }

        let privateKey: SecureEnclave.P256.Signing.PrivateKey

        do {
            privateKey = try SecureEnclave.P256.Signing.PrivateKey(accessControl: accessControl)
        } catch {
            throw DevicePrivateKeyRepositoryError.keyGenerationFailed(underlying: error)
        }

        return privateKey
    }

    private func storeKeyInKeychain(_ privateKey: SecureEnclave.P256.Signing.PrivateKey) throws(DevicePrivateKeyRepositoryError) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: privateKey.dataRepresentation,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecUseDataProtectionKeychain as String: true,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw DevicePrivateKeyRepositoryError.keychainSaveFailed(status: status)
        }
    }
}
