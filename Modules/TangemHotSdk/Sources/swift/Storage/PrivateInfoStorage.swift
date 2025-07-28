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

final class PrivateInfoStorage {
    private let secureStorage: HotSecureStorage
    private let biometricsStorage: HotBiometricsStorage
    private let accessCodeSecureEnclaveService: HotSecureEnclaveService
    private let biometricsSecureEnclaveServiceType: HotSecureEnclaveService.Type

    init(
        secureStorage: HotSecureStorage = SecureStorage(),
        biometricsStorage: HotBiometricsStorage = BiometricsStorage(),
        accessCodeSecureEnclaveService: HotSecureEnclaveService = SecureEnclaveService(config: .default),
        biometricsSecureEnclaveServiceType: HotSecureEnclaveService.Type = SecureEnclaveService.self
    ) {
        self.secureStorage = secureStorage
        self.biometricsStorage = biometricsStorage
        self.accessCodeSecureEnclaveService = accessCodeSecureEnclaveService
        self.biometricsSecureEnclaveServiceType = biometricsSecureEnclaveServiceType
    }

    func storeUnsecured(
        privateInfoData: Data,
        walletID: HotWalletID,
    ) throws {
        var aesKey = try CryptoUtils.generateRandomBytes(count: Constants.aesKeySize)
        defer { secureErase(data: &aesKey) }
        
        try storeEntropy(entropyData: privateInfoData, aesEncryptionKey: aesKey, for: walletID)

        try EncryptionKeyAccessCodeStorage(
            secureStorage: secureStorage,
            secureEnclaveService: accessCodeSecureEnclaveService
        ).storeEncryptionKeyUnsecured(encryptionKey: aesKey, walletID: walletID)
    }

    func getPrivateInfoData(for walletID: HotWalletID, auth: AuthenticationUnlockData?) throws -> Data {
        guard let secureEnclaveEncryptedKey = try secureStorage.get(walletID.storageKey) else {
            throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
        }
        
        let aesEncryptedKey = try accessCodeSecureEnclaveService.decryptData(
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

        try EncryptionKeyAccessCodeStorage(
            secureStorage: secureStorage,
            secureEnclaveService: accessCodeSecureEnclaveService
        ).updateAccessCode(
            newAccessCode,
            aesEncryptionKey: aesEncryptionKey,
            for: walletID
        )
    }

    public func enableBiometrics(for walletID: HotWalletID, accessCode: String, context: LAContext) throws {
        let aesEncryptionKey = try encryptionKey(for: walletID, auth: .accessCode(accessCode))

        try EncryptionKeyBiometricsStorage(
            biometricsStorage: biometricsStorage,
            secureEnclaveServiceType: biometricsSecureEnclaveServiceType
        ).enableBiometrics(
            for: walletID,
            aesEncryptionKey: aesEncryptionKey,
            context: context
        )
    }

    func delete(hotWalletID: HotWalletID) throws {
        try secureStorage.delete(hotWalletID.storageKey)
        
        try EncryptionKeyAccessCodeStorage(
            secureStorage: secureStorage,
            secureEnclaveService: accessCodeSecureEnclaveService
        ).deleteEncryptionKey(for: hotWalletID)
        try? EncryptionKeyBiometricsStorage(
            biometricsStorage: biometricsStorage,
            secureEnclaveServiceType: biometricsSecureEnclaveServiceType
        ).deleteEncryptionKey(for: hotWalletID)
    }
}

/// - Entropy data storage
private extension PrivateInfoStorage {
    func storeEntropy(entropyData: Data, aesEncryptionKey: Data, for walletID: HotWalletID) throws {
        let aesEncryptedKey = try AESEncoder.encryptAES(
            rawEncryptionKey: aesEncryptionKey,
            rawData: entropyData
        )
        
        let secureEnclaveEncrypted = try accessCodeSecureEnclaveService.encryptData(
            aesEncryptedKey,
            keyTag: walletID.storageKey
        )

        try secureStorage.store(secureEnclaveEncrypted, forKey: walletID.storageKey)
    }
}

/// - Encryption key storage
private extension PrivateInfoStorage {
    func encryptionKey(for walletID: HotWalletID, auth: AuthenticationUnlockData?) throws -> Data {
        switch auth {
        case .accessCode(let accessCode):
            try EncryptionKeyAccessCodeStorage(
                secureStorage: secureStorage,
                secureEnclaveService: accessCodeSecureEnclaveService
            ).encryptionKey(for: walletID, accessCode: accessCode)
        case .biometrics(let context):
            try EncryptionKeyBiometricsStorage(
                biometricsStorage: biometricsStorage,
                secureEnclaveServiceType: biometricsSecureEnclaveServiceType
            ).encryptionKey(for: walletID, context: context)
        case .none:
            try EncryptionKeyAccessCodeStorage(
                secureStorage: secureStorage,
                secureEnclaveService: accessCodeSecureEnclaveService
            ).encryptionKey(for: walletID, accessCode: nil)
        }
    }
}

extension PrivateInfoStorage {
    enum Constants {
        static let privateInfoPrefix = "hotsdk_private_info_"
        static let encryptionKeyPrefix = "hotsdk_encryption_key_"
        static let sharedBiometricsEncryptionKey = "hotsdk_shared_biometrics_encryption_key"
        static let aesKeySize = 32
    }
}
