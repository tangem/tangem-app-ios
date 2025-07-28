//
//  PrivateInfoStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import LocalAuthentication

final class BothPrivateInfoStorage {
    private let secureStorage: HotSecureStorage
    private let biometricsStorage: HotBiometricsStorage
    private let secureEnclaveService: HotSecureEnclaveService

    init(
        secureStorage: HotSecureStorage = SecureStorage(),
        biometricsStorage: HotBiometricsStorage = BiometricsStorage(),
        secureEnclaveService: HotSecureEnclaveService = SecureEnclaveService(config: .default)
    ) {
        self.secureStorage = secureStorage
        self.biometricsStorage = biometricsStorage
        self.secureEnclaveService = secureEnclaveService
    }

    func storeUnsecured(
        privateInfoData: Data,
        walletID: HotWalletID,
    ) throws {
        var aesKey = try CryptoUtils.generateRandomBytes(count: Constants.aesKeySize)
        defer { secureErase(data: &aesKey) }
        
        try storeEntropy(entropyData: privateInfoData, aesEncryptionKey: aesKey, for: walletID)

        try storeEncryptionKeyUnsecured(encryptionKey: aesKey,
            walletID: walletID
        )
    }

    func getPrivateInfoData(for walletID: HotWalletID, auth: AuthenticationUnlockData?) throws -> Data {
        guard let secureEnclaveEncryptedKey = try secureStorage.get(walletID.storageKey) else {
            throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
        }
        
        let aesEncryptedKey = try secureEnclaveService.decryptData(
            secureEnclaveEncryptedKey,
            keyTag: walletID.storageKey
        )

        do {
            var encryptionKey = try encryptionKey(for: walletID, auth: auth)
            defer { secureErase(data: &encryptionKey) }

            return try AESEncoder.decryptAES(
                rawEncryptionKey: encryptionKey,
                encryptedData: aesEncryptedKey
            )
        } catch {
            // unlocking with biometrics must also unlock non-secured wallets
            guard case .biometrics = auth else {
                throw error
            }

            return try getPrivateInfoData(for: walletID, auth: nil)
        }
    }

    func updateAccessCode(_ newAccessCode: String, oldAuth: AuthenticationUnlockData?, for walletID: HotWalletID) throws {
        let aesEncryptionKey = try encryptionKey(for: walletID, auth: oldAuth)

        try storeEncryptionKeyWithAccessCode(aesEncryptionKey: aesEncryptionKey, accessCode: newAccessCode, walletID: walletID)
    }

    public func enableBiometrics(for walletID: HotWalletID, accessCode: String, context: LAContext) throws {
        let aesEncryptionKey = try encryptionKey(for: walletID, auth: .accessCode(accessCode))

        try storeEncryptionKeyWithBiometrics(aesEncryptionKey: aesEncryptionKey, context: context, walletID: walletID)
    }

    func delete(hotWalletID: HotWalletID) throws {
        try secureStorage.delete(hotWalletID.storageKey)

        try? biometricsStorage.delete(hotWalletID.storageEncryptionKey)
        try secureStorage.delete(hotWalletID.storageEncryptionKey)
    }
}

/// - Entropy data storage
private extension BothPrivateInfoStorage {
    func storeEntropy(entropyData: Data, aesEncryptionKey: Data, for walletID: HotWalletID) throws {
        let aesEncryptedKey = try AESEncoder.encryptAES(
            rawEncryptionKey: aesEncryptionKey,
            rawData: entropyData
        )
        
        let secureEnclaveEncrypted = try secureEnclaveService.encryptData(
            aesEncryptedKey,
            keyTag: walletID.storageKey
        )

        try secureStorage.store(secureEnclaveEncrypted, forKey: walletID.storageKey)
    }
}

/// - Encryption key storage
private extension BothPrivateInfoStorage {
    func storeEncryptionKeyUnsecured(
        encryptionKey: Data,
        walletID: HotWalletID,
    ) throws {
        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            encryptionKey,
            keyTag: walletID.storageEncryptionKey
        )

        try secureStorage.store(secureEnclaveEncryptedKey, forKey: walletID.storageEncryptionKey)
    }

    func storeEncryptionKeyWithAccessCode(
        aesEncryptionKey: Data,
        accessCode: String,
        walletID: HotWalletID,
    ) throws {
        let encryptedAesKey = try AESEncoder.encryptWithPassword(
            password: accessCode,
            content: aesEncryptionKey
        )

        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            encryptedAesKey,
            keyTag: walletID.storageEncryptionKey
        )

        try secureStorage.store(secureEnclaveEncryptedKey, forKey: walletID.storageEncryptionKey)
    }

    func storeEncryptionKeyWithBiometrics(
        aesEncryptionKey: Data,
        context: LAContext,
        walletID: HotWalletID
    ) throws {
        let biometricsKey = try sharedBiometricsEncryptionKey(context: context)

        let aesEncryptedKey = try AESEncoder.encryptAES(
            rawEncryptionKey: biometricsKey,
            rawData: aesEncryptionKey
        )

        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            aesEncryptedKey,
            keyTag: walletID.storageEncryptionKey
        )

        try biometricsStorage.store(secureEnclaveEncryptedKey, forKey: walletID.storageEncryptionKey)
    }

    func encryptionKey(for walletID: HotWalletID, auth: AuthenticationUnlockData?) throws -> Data {
        let savedKeyData: Data?

        switch auth {
        case .none, .accessCode:
            savedKeyData = try secureStorage.get(walletID.storageEncryptionKey)
        case .biometrics(let context):
            savedKeyData = try biometricsStorage.get(walletID.storageEncryptionKey, context: context)
        }

        guard let savedKeyData else {
            throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
        }

        let encryptedAesKey = try secureEnclaveService.decryptData(savedKeyData, keyTag: walletID.storageEncryptionKey)

        if case .accessCode(let accessCode) = auth {
            return try AESEncoder.decryptWithPassword(password: accessCode, encryptedData: encryptedAesKey)
        } else if case .biometrics(let context) = auth {
            let biometricsKey = try sharedBiometricsEncryptionKey(context: context)
            return try AESEncoder.decryptAES(rawEncryptionKey: biometricsKey, encryptedData: encryptedAesKey)
        }

        return encryptedAesKey
    }

    func sharedBiometricsEncryptionKey(context: LAContext) throws -> Data {
        if let keyData = try? biometricsStorage.get(Constants.sharedBiometricsEncryptionKey, context: context) {
            return try secureEnclaveService.decryptData(keyData, keyTag: Constants.sharedBiometricsEncryptionKey)
        }

        let aesEncryptionKey = try CryptoUtils.generateRandomBytes(count: Constants.aesKeySize)

        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            aesEncryptionKey,
            keyTag: Constants.sharedBiometricsEncryptionKey
        )

        try biometricsStorage.store(secureEnclaveEncryptedKey, forKey: Constants.sharedBiometricsEncryptionKey)

        return aesEncryptionKey
    }
}

extension BothPrivateInfoStorage {
    enum Constants {
        static let privateInfoPrefix = "hotsdk_private_info_"
        static let encryptionKeyPrefix = "hotsdk_encryption_key_"
        static let sharedBiometricsEncryptionKey = "hotsdk_shared_biometrics_encryption_key"
        static let aesKeySize = 32
    }
}


func secureErase(data: inout Data) {
    _ = data.withUnsafeMutableBytes { bytes in
        memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
    }
}

extension HotWalletID {
    var storageKey: String { BothPrivateInfoStorage.Constants.privateInfoPrefix + value }
    var storageEncryptionKey: String { BothPrivateInfoStorage.Constants.encryptionKeyPrefix + value }
}

/// Define errors for better error handling
enum PrivateInfoStorageError: Error {
    case noEncryptionType(walletID: HotWalletID)
    case invalidEncryptionType(walletID: HotWalletID)
    case noPrivateInfo(walletID: HotWalletID)
    case unknown
}
