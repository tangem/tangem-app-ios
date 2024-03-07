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

class UserWalletEncryptionKeyStorage {
    private let secureStorage = SecureStorage()
    private let biometricsStorage = BiometricsStorage()
    private let userWalletIdsStorageKey = "user_wallet_ids"

    func fetch(completion: @escaping (Result<[Data: SymmetricKey], Error>) -> Void) {
        do {
            let userWalletIds = try userWalletIds()

            let reason = Localization.biometryTouchIdReason
            BiometricsUtil.requestAccess(localizedReason: reason) { [weak self] result in
                guard let self else { return }

                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let context):
                    do {
                        var keys: [Data: SymmetricKey] = [:]

                        for userWalletId in userWalletIds {
                            let storageKey = encryptionKeyStorageKey(for: userWalletId)
                            let encryptionKeyData = try biometricsStorage.get(storageKey, context: context)
                            if let encryptionKeyData = encryptionKeyData {
                                keys[userWalletId] = SymmetricKey(data: encryptionKeyData)
                            }
                        }

                        completion(.success(keys))
                    } catch {
                        AppLog.shared.error(error)
                        completion(.failure(error))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func add(_ userWallet: StoredUserWallet) {
        let cardInfo = userWallet.cardInfo()

        guard let encryptionKey = UserWalletEncryptionKeyFactory().encryptionKey(from: cardInfo) else {
            AppLog.shared.debug("Failed to get encryption key for UserWallet")
            return
        }

        do {
            let userWalletIds = try userWalletIds()
            if userWalletIds.contains(userWallet.userWalletId) {
                return
            }

            try addUserWalletId(userWallet)

            let encryptionKeyData = encryptionKey.symmetricKey.dataRepresentationWithHexConversion
            try biometricsStorage.store(encryptionKeyData, forKey: encryptionKeyStorageKey(for: UserWalletId(value: userWallet.userWalletId)))
        } catch {
            AppLog.shared.debug("Failed to add UserWallet ID to the list")
            AppLog.shared.error(error)
            return
        }
    }

    func delete(_ userWallet: StoredUserWallet) {
        do {
            try deleteUserWalletId(UserWalletId(value: userWallet.userWalletId))

            try biometricsStorage.delete(encryptionKeyStorageKey(for: userWallet.userWalletId))

            if AppSettings.shared.saveAccessCodes {
                let accessCodeRepository = AccessCodeRepository()
                try accessCodeRepository.deleteAccessCode(for: Array(userWallet.associatedCardIds))
            }
        } catch {
            AppLog.shared.debug("Failed to delete user wallet list encryption key")
            AppLog.shared.error(error)
        }
    }

    func refreshEncryptionKey(_ key: SymmetricKey, for userWalletId: Data) {
        do {
            try biometricsStorage.delete(encryptionKeyStorageKey(for: userWalletId))
            let encryptionKeyData = key.dataRepresentationWithHexConversion
            try biometricsStorage.store(encryptionKeyData, forKey: encryptionKeyStorageKey(for: userWalletId))
        } catch {
            AppLog.shared.debug("Failed to refresh an encryption key")
            AppLog.shared.error(error)
        }
    }

    func clear() {
        do {
            let userWalletIds = try userWalletIds()
            try saveUserWalletIds([])
            for userWalletId in userWalletIds {
                try biometricsStorage.delete(encryptionKeyStorageKey(for: userWalletId))
            }
        } catch {
            AppLog.shared.debug("Failed to clear user wallet encryption keys")
            AppLog.shared.error(error)
        }
    }

    // MARK: - Saving the list of UserWallet IDs

    private func encryptionKeyStorageKey(for userWalletId: UserWalletId) -> String {
        encryptionKeyStorageKey(for: userWalletId.value)
    }

    private func encryptionKeyStorageKey(for userWalletId: Data) -> String {
        "user_wallet_encryption_key_\(userWalletId.hexString.lowercased())"
    }

    private func addUserWalletId(_ userWallet: StoredUserWallet) throws {
        var ids = try userWalletIds()
        ids.insert(userWallet.userWalletId)
        try saveUserWalletIds(ids)
    }

    private func deleteUserWalletId(_ userWalletId: UserWalletId) throws {
        var ids = try userWalletIds()
        ids.remove(userWalletId.value)
        try saveUserWalletIds(ids)
    }

    private func userWalletIds() throws -> Set<Data> {
        guard let data = try secureStorage.get(userWalletIdsStorageKey) else {
            return []
        }
        return try JSONDecoder().decode(Set<Data>.self, from: data)
    }

    private func saveUserWalletIds(_ userWalletIds: Set<Data>) throws {
        if userWalletIds.isEmpty {
            try secureStorage.delete(userWalletIdsStorageKey)
        } else {
            let data = try JSONEncoder().encode(userWalletIds)
            try secureStorage.store(data, forKey: userWalletIdsStorageKey)
        }
    }
}
