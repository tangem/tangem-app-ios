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

        // store encrypted entropy
        let encrypted = try AESEncoder.encryptAES(
            rawEncryptionKey: aesKey,
            rawData: privateInfoData
        )

        try secureStorage.store(encrypted, forKey: walletID.storageKey)

        try storeEncryptionKeyUnsecured(
            encryptionKey: aesKey,
            walletID: walletID
        )
    }

    func getPrivateInfoData(for walletID: HotWalletID, auth: AuthenticationUnlockData?) throws -> Data {
        guard let encryptedData = try secureStorage.get(walletID.storageKey) else {
            throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
        }

        do {
            var encryptionKey = try encryptionKey(for: walletID, auth: auth)
            defer { secureErase(data: &encryptionKey) }

            return try AESEncoder.decryptAES(
                rawEncryptionKey: encryptionKey,
                encryptedData: encryptedData
            )
        } catch {
            // unlocking with biometrics must also unlock non-secured wallets
            guard case .biometrics = auth else {
                throw error
            }

            return try getPrivateInfoData(for: walletID, auth: nil)
        }
    }

    func updatePasscode(_ newPasscode: String, oldAuth: AuthenticationUnlockData?, for walletID: HotWalletID) throws {
        let encryptionKey = try encryptionKey(for: walletID, auth: oldAuth)

        try storeEncryptionKeyWithPasscode(encryptionKey: encryptionKey, passcode: newPasscode, walletID: walletID)
    }

    public func enableBiometrics(for walletID: HotWalletID, passcode: String, context: LAContext) throws {
        let encryptionKey = try encryptionKey(for: walletID, auth: .passcode(passcode))

        try storeEncryptionKeyWithBiometrics(encryptionKey: encryptionKey, context: context, walletID: walletID)
    }

    func delete(hotWalletID: HotWalletID) throws {
        try secureStorage.delete(hotWalletID.storageKey)

        try? biometricsStorage.delete(hotWalletID.storageEncryptionKey)
        try secureStorage.delete(hotWalletID.storageEncryptionKey)
    }
}

/// - Encryption key storage
private extension PrivateInfoStorage {
    private func storeEncryptionKeyUnsecured(
        encryptionKey: Data,
        walletID: HotWalletID,
    ) throws {
        let keyToStore = try secureEnclaveService.encryptData(
            encryptionKey,
            keyTag: walletID.storageEncryptionKey
        )

        try secureStorage.store(keyToStore, forKey: walletID.storageEncryptionKey)
    }

    private func storeEncryptionKeyWithPasscode(
        encryptionKey: Data,
        passcode: String,
        walletID: HotWalletID,
    ) throws {
        let encryptedAesKey = try AESEncoder.encryptWithPassword(
            password: passcode,
            content: encryptionKey
        )

        let keyToStore = try secureEnclaveService.encryptData(
            encryptedAesKey,
            keyTag: walletID.storageEncryptionKey
        )

        try secureStorage.store(keyToStore, forKey: walletID.storageEncryptionKey)
    }

    private func storeEncryptionKeyWithBiometrics(
        encryptionKey: Data,
        context: LAContext,
        walletID: HotWalletID
    ) throws {
        let biometricsKey = try sharedBiometricsEncryptionKey(context: context)

        let encryptedKey = try AESEncoder.encryptAES(
            rawEncryptionKey: biometricsKey,
            rawData: encryptionKey
        )

        let keyToStore = try secureEnclaveService.encryptData(
            encryptedKey,
            keyTag: walletID.storageEncryptionKey
        )

        try biometricsStorage.store(keyToStore, forKey: walletID.storageEncryptionKey)
    }

    private func encryptionKey(for walletID: HotWalletID, auth: AuthenticationUnlockData?) throws -> Data {
        let savedKeyData: Data?

        switch auth {
        case .none, .passcode:
            savedKeyData = try secureStorage.get(walletID.storageEncryptionKey)
        case .biometrics(let context):
            savedKeyData = try biometricsStorage.get(walletID.storageEncryptionKey, context: context)
        }

        guard let savedKeyData else {
            throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
        }

        let encryptedAesKey = try secureEnclaveService.decryptData(savedKeyData, keyTag: walletID.storageEncryptionKey)

        if case .passcode(let passcode) = auth {
            return try AESEncoder.decryptWithPassword(password: passcode, encryptedData: encryptedAesKey)
        } else if case .biometrics(let context) = auth {
            let biometricsKey = try sharedBiometricsEncryptionKey(context: context)
            return try AESEncoder.decryptAES(rawEncryptionKey: biometricsKey, encryptedData: encryptedAesKey)
        }

        return encryptedAesKey
    }

    private func sharedBiometricsEncryptionKey(context: LAContext) throws -> Data {
        if let keyData = try? biometricsStorage.get(Constants.sharedBiometricsEncryptionKey, context: context) {
            return try secureEnclaveService.decryptData(keyData, keyTag: Constants.sharedBiometricsEncryptionKey)
        }

        let aesKey = try CryptoUtils.generateRandomBytes(count: Constants.aesKeySize)

        let keyToStore = try secureEnclaveService.encryptData(
            aesKey,
            keyTag: Constants.sharedBiometricsEncryptionKey
        )

        try biometricsStorage.store(keyToStore, forKey: Constants.sharedBiometricsEncryptionKey)

        return keyToStore
    }
}

func secureErase(data: inout Data) {
    _ = data.withUnsafeMutableBytes { bytes in
        memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
    }
}

private extension HotWalletID {
    var storageKey: String { PrivateInfoStorage.Constants.privateInfoPrefix + value }
    var storageEncryptionKey: String { PrivateInfoStorage.Constants.encryptionKeyPrefix + value }
}

/// Define errors for better error handling
enum PrivateInfoStorageError: Error {
    case noEncryptionType(walletID: HotWalletID)
    case invalidEncryptionType(walletID: HotWalletID)
    case noPrivateInfo(walletID: HotWalletID)
    case unknown
}

extension PrivateInfoStorage {
    enum Constants {
        static let privateInfoPrefix = "hotsdk_private_info_"
        static let encryptionKeyPrefix = "hotsdk_encryption_key_"
        static let sharedBiometricsEncryptionKey = "hotsdk_shared_biometrics_encryption_key"
        static let aesKeySize = 32
    }
}
