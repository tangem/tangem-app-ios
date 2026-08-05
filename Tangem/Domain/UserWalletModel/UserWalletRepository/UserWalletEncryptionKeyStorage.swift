//
//  UserWalletEncryptionKeyStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit
import LocalAuthentication
import TangemSdk
import TangemFoundation

class UserWalletEncryptionKeyStorage {
    private let secureStorage = SecureStorage()
    private let biometricsStorage = BiometricsStorage()

    func fetch(userWalletIds: [UserWalletId], context: LAContext) throws -> [UserWalletId: UserWalletEncryptionKey] {
        var keys: [UserWalletId: UserWalletEncryptionKey] = [:]

        for userWalletId in userWalletIds {
            let storageKey = encryptionKeyStorageKey(for: userWalletId)
            let encryptionKeyData = try biometricsStorage.get(storageKey, context: context)
            if let encryptionKeyData {
                keys[userWalletId] = UserWalletEncryptionKey(symmetricKey: SymmetricKey(data: encryptionKeyData))
            }
        }

        return keys
    }

    func add(_ userWalletId: UserWalletId, encryptionKey: UserWalletEncryptionKey) {
        guard AppSettings.shared.saveUserWallets, BiometricsUtil.isAvailable else {
            return
        }

        do {
            let encryptionKeyData = encryptionKey.symmetricKey.dataRepresentationWithHexConversion
            try biometricsStorage.store(encryptionKeyData, forKey: encryptionKeyStorageKey(for: userWalletId))
        } catch {
            AppLogger.error("Failed to add UserWallet ID to the list", error: error)
            Analytics.error(error: error)
            return
        }
    }

    func delete(_ userWalletId: UserWalletId) {
        do {
            try biometricsStorage.delete(encryptionKeyStorageKey(for: userWalletId))
        } catch {
            AppLogger.error("Failed to delete user wallet list encryption key", error: error)
            Analytics.error(error: error)
        }
    }

    func refreshEncryptionKey(_ key: UserWalletEncryptionKey, for userWalletId: UserWalletId) {
        guard AppSettings.shared.saveUserWallets, BiometricsUtil.isAvailable else {
            return
        }

        do {
            try biometricsStorage.delete(encryptionKeyStorageKey(for: userWalletId))
            let encryptionKeyData = key.symmetricKey.dataRepresentationWithHexConversion
            try biometricsStorage.store(encryptionKeyData, forKey: encryptionKeyStorageKey(for: userWalletId))
        } catch {
            AppLogger.error("Failed to refresh an encryption key", error: error)
            Analytics.error(error: error)
        }
    }

    func clear(userWalletIds: [UserWalletId]) {
        for userWalletId in userWalletIds {
            delete(userWalletId)
        }
    }

    /// Removes every stored encryption key. Matched by prefix because the wallet-id list
    /// doesn't survive an app reinstall, so the keys can't be enumerated by id.
    func clean(genericPasswordAccounts: [String]) {
        for account in genericPasswordAccounts where account.hasPrefix(Constants.encryptionKeyPrefix) {
            do {
                try biometricsStorage.delete(account)
            } catch {
                AppLogger.error("Failed to delete a user wallet encryption key", error: error)
            }
        }
    }

    // MARK: - Saving the list of UserWallet IDs

    private func encryptionKeyStorageKey(for userWalletId: UserWalletId) -> String {
        Constants.encryptionKeyPrefix + userWalletId.stringValue.lowercased()
    }
}

private extension UserWalletEncryptionKeyStorage {
    enum Constants {
        static let encryptionKeyPrefix = "user_wallet_encryption_key_"
    }
}
