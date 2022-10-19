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

    init() {

    }

    func fetch(completion: @escaping (Result<[Data: SymmetricKey], Error>) -> Void) {
        do {
            let userWalletIds = try userWalletIds()

            let reason = "biometry_touch_id_reason".localized
            BiometricsUtil.requestAccess(localizedReason: reason) { [weak self] result in
                guard let self = self else { return }

                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let context):
                    var keys: [Data: SymmetricKey] = [:]

                    for userWalletId in userWalletIds {
                        let storageKey = self.encryptionKeyStorageKey(for: userWalletId)
                        let userWalletEncryptionKeyResult = self.biometricsStorage.get(storageKey, context: context)

                        switch userWalletEncryptionKeyResult {
                        case .failure(let error):
                            print("Failed to get encryption key for UserWallet", error)
                            completion(.failure(error))
                            return
                        case .success(let encryptionKeyData):
                            if let encryptionKeyData = encryptionKeyData {
                                keys[userWalletId] = SymmetricKey(data: encryptionKeyData)
                            }
                        }
                    }

                    completion(.success(keys))
                }
            }
        } catch let error {
            completion(.failure(error))
        }
    }

    func add(_ userWallet: UserWallet) {
        guard let userWalletEncryptionKey = userWallet.encryptionKey else {
            print("Failed to get encryption key for UserWallet")
            return
        }

        do {
            let userWalletIds = try userWalletIds()
            if userWalletIds.contains(userWallet.userWalletId) {
                return
            }

            try addUserWalletId(userWallet)
        } catch {
            print("Failed to add UserWallet ID to the list: \(error)")
            return
        }

        let encryptionKeyData = userWalletEncryptionKey.dataRepresentationWithHexConversion
        let result = biometricsStorage.store(encryptionKeyData, forKey: encryptionKeyStorageKey(for: userWallet))
        if case .failure(let error) = result {
            print("Failed to store UserWallet encryption key: \(error)")
            return
        }
    }

    func delete(_ userWallet: UserWallet) {
        do {
            try deleteUserWalletId(userWallet)

            if AppSettings.shared.saveAccessCodes {
                try biometricsStorage.delete(encryptionKeyStorageKey(for: userWallet))

                let accessCodeRepository = AccessCodeRepository()
                let result = accessCodeRepository.deleteAccessCode(for: Array(userWallet.associatedCardIds))
                if case let .failure(error) = result {
                    print("Failed to delete access code: \(error)")
                }
            }
        } catch {
            print("Failed to delete user wallet list encryption key: \(error)")
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
            print("Failed to clear user wallet encryption keys: \(error)")
        }
    }

    // MARK: - Saving the list of UserWallet IDs

    private func encryptionKeyStorageKey(for userWallet: UserWallet) -> String {
        encryptionKeyStorageKey(for: userWallet.userWalletId)
    }

    private func encryptionKeyStorageKey(for userWalletId: Data) -> String {
        "user_wallet_encryption_key_\(userWalletId.hex)"
    }

    private func addUserWalletId(_ userWallet: UserWallet) throws {
        var ids = try userWalletIds()
        ids.insert(userWallet.userWalletId)
        try saveUserWalletIds(ids)
    }

    private func deleteUserWalletId(_ userWallet: UserWallet) throws {
        var ids = try userWalletIds()
        ids.remove(userWallet.userWalletId)
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
