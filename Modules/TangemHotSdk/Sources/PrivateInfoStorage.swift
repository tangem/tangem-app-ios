//
//  PrivateInfoStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

final class PrivateInfoStorage {
    private let secureStorage: SecureStorage
    private let biometricsStorage: BiometricsStorage

    init(
        secureStorage: SecureStorage = SecureStorage(),
        biometricsStorage: BiometricsStorage = BiometricsStorage()
    ) {
        self.secureStorage = secureStorage
        self.biometricsStorage = biometricsStorage
    }

    func store(walletAuthInfo: HotWalletAuthInfo, privateInfo: PrivateInfo) throws {
        var aesKey = try CryptoUtils.generateRandomBytes(count: Constants.aesKeySize)

        defer { secureErase(data: &aesKey) }

        let encrypted = try AESEncoder.encryptAES(
            rawEncryptionKey: aesKey,
            rawData: privateInfo.encode()
        )

        switch walletAuthInfo.auth {
        case .none:
            try secureStorage.store(aesKey, forKey: walletAuthInfo.walletID.storageEncryptionKey)
        case .password(let value):
            let aesEncrypted = try AESEncoder.encryptWithPassword(
                password: value,
                content: aesKey
            )
            try secureStorage.store(aesEncrypted, forKey: walletAuthInfo.walletID.storageEncryptionKey)
        case .biometrics:
            try biometricsStorage.store(aesKey, forKey: walletAuthInfo.walletID.storageEncryptionKey)
        }

        try secureStorage.store(encrypted, forKey: walletAuthInfo.walletID.storageKey)

        try secureStorage.store(
            authTypeData(for: walletAuthInfo.auth),
            forKey: walletAuthInfo.walletID.storageEncryptionTypeKey
        )
    }

    func changeStore(walletAuthInfo: HotWalletAuthInfo, newHotAuth: HotAuth?) async throws {
        guard walletAuthInfo.auth != newHotAuth else { return }

        guard let currentType = try secureStorage.get(walletAuthInfo.walletID.storageEncryptionTypeKey) else {
            throw PrivateInfoStorageError.noEncryptionType(walletID: walletAuthInfo.walletID)
        }
        guard currentType == authTypeData(for: walletAuthInfo.auth) else {
            throw PrivateInfoStorageError.invalidEncryptionType(walletID: walletAuthInfo.walletID)
        }

        let storageEncryptionKey = walletAuthInfo.walletID.storageEncryptionKey

        var aesKey: Data
        switch walletAuthInfo.auth {
        case .none:
            guard let key = try secureStorage.get(storageEncryptionKey) else {
                throw PrivateInfoStorageError.noEncryptionKey(walletID: walletAuthInfo.walletID)
            }
            aesKey = key
        case .password(let value):
            guard let aesKeyEncrypted = try secureStorage.get(storageEncryptionKey) else {
                throw PrivateInfoStorageError.noEncryptionKey(walletID: walletAuthInfo.walletID)
            }
            aesKey = try AESEncoder.decryptWithPassword(
                password: value,
                encryptedData: aesKeyEncrypted
            )
        case .biometrics:
            guard let key = try biometricsStorage.get(storageEncryptionKey) else {
                throw PrivateInfoStorageError.noPrivateInfo(walletID: walletAuthInfo.walletID)
            }
            aesKey = key
        }

        defer { secureErase(data: &aesKey) }

        guard aesKey.count == Constants.aesKeySize else {
            throw PrivateInfoStorageError.invalidAesKeySize(walletID: walletAuthInfo.walletID, size: aesKey.count)
        }
        switch newHotAuth {
        case .none:
            try secureStorage.store(
                aesKey,
                forKey: walletAuthInfo.walletID.storageEncryptionKey
            )
        case .password(let value):
            let aesEncrypted = try AESEncoder.encryptWithPassword(
                password: value,
                content: aesKey
            )
            try secureStorage.store(aesEncrypted, forKey: storageEncryptionKey)
        case .biometrics:
            if walletAuthInfo.auth == .none {
                try secureStorage.delete(walletAuthInfo.walletID.storageEncryptionKey)
            }
            try biometricsStorage.store(aesKey, forKey: storageEncryptionKey)
        }

        let authType = authTypeData(for: newHotAuth)
        try secureStorage.store(authType, forKey: walletAuthInfo.walletID.storageEncryptionTypeKey)
    }

    func delete(hotWalletID: HotWalletID) throws {
        let storageKey = Constants.privateInfoPrefix + hotWalletID.value
        try biometricsStorage.delete(storageKey)
        try secureStorage.delete(storageKey)
        try secureStorage.delete(hotWalletID.storageEncryptionKey)
        try secureStorage.delete(Constants.encryptionTypePrefix + hotWalletID.value)
    }

    func getContainer(walletAuthInfo: HotWalletAuthInfo) throws -> PrivateInfoContainer {
        guard let encryptionType = try secureStorage.get(walletAuthInfo.walletID.storageEncryptionTypeKey) else {
            throw PrivateInfoStorageError.noEncryptionType(walletID: walletAuthInfo.walletID)
        }

        guard encryptionType == authTypeData(for: walletAuthInfo.auth) else {
            throw PrivateInfoStorageError.invalidEncryptionType(walletID: walletAuthInfo.walletID)
        }

        return PrivateInfoContainer(
            getPrivateInfo: { [weak self] in
                guard let self else {
                    throw PrivateInfoStorageError.unknown
                }

                guard let encryptedData = try secureStorage.get(walletAuthInfo.walletID.storageKey) else {
                    throw PrivateInfoStorageError.noPrivateInfo(walletID: walletAuthInfo.walletID)
                }
                var aesKey: Data

                switch walletAuthInfo.auth {
                case .none:
                    guard let key = try secureStorage.get(walletAuthInfo.walletID.storageEncryptionKey) else {
                        throw PrivateInfoStorageError.noEncryptionKey(walletID: walletAuthInfo.walletID)
                    }
                    aesKey = key
                case .password(let value):
                    guard let aesKeyEncrypted = try secureStorage.get(
                        walletAuthInfo.walletID.storageEncryptionKey
                    ) else {
                        throw PrivateInfoStorageError.noEncryptionKey(walletID: walletAuthInfo.walletID)
                    }
                    aesKey = try AESEncoder.decryptWithPassword(
                        password: value,
                        encryptedData: aesKeyEncrypted
                    )
                case .biometrics:
                    guard let key = try biometricsStorage.get(walletAuthInfo.walletID.storageEncryptionKey) else {
                        throw PrivateInfoStorageError.noPrivateInfo(walletID: walletAuthInfo.walletID)
                    }
                    aesKey = key
                }
                defer { secureErase(data: &aesKey) }

                return try AESEncoder.decryptAES(
                    rawEncryptionKey: aesKey,
                    encryptedData: encryptedData
                )
            })
    }
}

func secureErase(data: inout Data) {
    data.withUnsafeMutableBytes { bytes in
        memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
    }
}

private extension HotWalletID {
    var storageKey: String { PrivateInfoStorage.Constants.privateInfoPrefix + value }
    var storageEncryptionKey: String { PrivateInfoStorage.Constants.encryptionKeyPrefix + value }
    var storageEncryptionTypeKey: String { PrivateInfoStorage.Constants.encryptionTypePrefix + value }
}

private extension PrivateInfoStorage {
    func authTypeData(for authType: HotAuth?) -> Data {
        let string = switch authType {
        case .biometrics: "biometrics"
        case .password: "password"
        case .none: "no_auth"
        }

        return string.data(using: .utf8)!
    }
}

/// Define errors for better error handling
enum PrivateInfoStorageError: Error {
    case noEncryptionType(walletID: HotWalletID)
    case invalidEncryptionType(walletID: HotWalletID)
    case noEncryptionKey(walletID: HotWalletID)
    case noPrivateInfo(walletID: HotWalletID)
    case invalidAesKeySize(walletID: HotWalletID, size: Int)
    case unknown
}

extension PrivateInfoStorage {
    enum Constants {
        static let privateInfoPrefix = "hotsdk_private_info_"
        static let encryptionKeyPrefix = "hotsdk_encryption_key_"
        static let encryptionTypePrefix = "hotsdk_encryption_type_"
        static let aesKeySize = 32
    }
}
