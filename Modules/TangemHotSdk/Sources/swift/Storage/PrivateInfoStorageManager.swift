//
//  PrivateInfoStorageManager.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import LocalAuthentication

final class PrivateInfoStorageManager {
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
        var aesEncryptionKey = try CryptoUtils.generateRandomBytes(count: Constants.aesKeySize)
        defer { secureErase(data: &aesEncryptionKey) }
        
        try PrivateInfoStorage(
            secureStorage: secureStorage,
            secureEnclaveService: accessCodeSecureEnclaveService
        )
        .storePrivateInfoData(privateInfoData, for: walletID, aesEncryptionKey: aesEncryptionKey)
        
        try EncryptionKeyAccessCodeStorage(
            secureStorage: secureStorage,
            secureEnclaveService: accessCodeSecureEnclaveService
        )
        .storeEncryptionKeyUnsecured(encryptionKey: aesEncryptionKey, walletID: walletID)
    }

    func getPrivateInfoData(for walletID: HotWalletID, auth: AuthenticationUnlockData?) throws -> Data {
        var aesEncryptionKey: Data
        do {
            aesEncryptionKey = try encryptionKey(for: walletID, auth: auth)
        } catch {
            guard case .biometrics = auth else {
                throw error
            }
            aesEncryptionKey = try encryptionKey(for: walletID, auth: nil)
        }
        
        defer {
            secureErase(data: &aesEncryptionKey)
        }
        
        return try PrivateInfoStorage(
            secureStorage: secureStorage,
            secureEnclaveService: accessCodeSecureEnclaveService
        )
        .getPrivateInfoData(for: walletID, aesEncryptionKey: aesEncryptionKey)
    }

    func updateAccessCode(
        _ newAccessCode: String,
        oldAuth: AuthenticationUnlockData?,
        for walletID: HotWalletID
    ) throws {
        let aesEncryptionKey = try encryptionKey(for: walletID, auth: oldAuth)

        try EncryptionKeyAccessCodeStorage(
            secureStorage: secureStorage,
            secureEnclaveService: accessCodeSecureEnclaveService
        )
        .updateAccessCode(
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
        )
        .enableBiometrics(
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
        )
        .deleteEncryptionKey(for: hotWalletID)
        
        try? EncryptionKeyBiometricsStorage(
            biometricsStorage: biometricsStorage,
            secureEnclaveServiceType: biometricsSecureEnclaveServiceType
        )
        .deleteEncryptionKey(for: hotWalletID)
    }
}

/// - Encryption key storage
private extension PrivateInfoStorageManager {
    func encryptionKey(for walletID: HotWalletID, auth: AuthenticationUnlockData?) throws -> Data {
        switch auth {
        case .accessCode(let accessCode):
            try EncryptionKeyAccessCodeStorage(
                secureStorage: secureStorage,
                secureEnclaveService: accessCodeSecureEnclaveService
            )
            .encryptionKey(for: walletID, accessCode: accessCode)
        case .biometrics(let context):
            try EncryptionKeyBiometricsStorage(
                biometricsStorage: biometricsStorage,
                secureEnclaveServiceType: biometricsSecureEnclaveServiceType
            )
            .encryptionKey(for: walletID, context: context)
        case .none:
            try EncryptionKeyAccessCodeStorage(
                secureStorage: secureStorage,
                secureEnclaveService: accessCodeSecureEnclaveService
            )
            .encryptionKey(for: walletID, accessCode: nil)
        }
    }
}

extension PrivateInfoStorageManager {
    enum Constants {
        static let privateInfoPrefix = "hotsdk_private_info_"
        static let encryptionKeyPrefix = "hotsdk_encryption_key_"
        static let aesKeySize = 32
    }
}

extension HotWalletID {
    var storageKey: String { PrivateInfoStorageManager.Constants.privateInfoPrefix + value }
    var storageEncryptionKey: String { PrivateInfoStorageManager.Constants.encryptionKeyPrefix + value }
}

/// Define errors for better error handling
enum PrivateInfoStorageError: Error {
    case noEncryptionType(walletID: HotWalletID)
    case invalidEncryptionType(walletID: HotWalletID)
    case noPrivateInfo(walletID: HotWalletID)
    case unknown
}

func secureErase(data: inout Data) {
    _ = data.withUnsafeMutableBytes { bytes in
        memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
    }
}
