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
import TangemFoundation

/// Handles the storage of entropy / passphrase data and encryption keys for mobile wallets.
final class PrivateInfoStorageManager {
    private let privateInfoStorage: PrivateInfoStorage
    private let encryptedSecureStorage: EncryptedSecureStorage
    private let encryptedBiometricsStorage: EncryptedBiometricsStorage

    init(
        privateInfoStorage: PrivateInfoStorage,
        encryptedSecureStorage: EncryptedSecureStorage,
        encryptedBiometricsStorage: EncryptedBiometricsStorage
    ) {
        self.privateInfoStorage = privateInfoStorage
        self.encryptedSecureStorage = encryptedSecureStorage
        self.encryptedBiometricsStorage = encryptedBiometricsStorage
    }

    func storeUnsecured(
        privateInfoData: Data,
        walletID: UserWalletId,
    ) throws {
        var aesEncryptionKey = try CryptoUtils.generateRandomBytes(count: Constants.aesKeySize)
        defer { secureErase(data: &aesEncryptionKey) }

        try privateInfoStorage.storePrivateInfoData(privateInfoData, for: walletID, aesEncryptionKey: aesEncryptionKey)

        try encryptedSecureStorage.storeData(
            aesEncryptionKey,
            keyTag: walletID.encryptionKeyTag,
            secureEnclaveKeyTag: walletID.encryptionKeySecureEnclaveTag,
            accessCode: nil
        )
    }

    func validate(auth: AuthenticationUnlockData, for walletID: UserWalletId) throws -> MobileWalletContext {
        var aesEncryptionKey = try getEncryptionKey(for: walletID, auth: auth)
        defer { secureErase(data: &aesEncryptionKey) }

        return MobileWalletContext(walletID: walletID, authentication: auth)
    }

    func hasPrivateInfoData(for walletID: UserWalletId) -> Bool {
        privateInfoStorage.hasPrivateInfoData(for: walletID)
    }

    func getPrivateInfoData(context: MobileWalletContext) throws -> Data {
        var aesEncryptionKey = try getEncryptionKey(for: context.walletID, auth: context.authentication)
        defer { secureErase(data: &aesEncryptionKey) }

        return try privateInfoStorage.getPrivateInfoData(for: context.walletID, aesEncryptionKey: aesEncryptionKey)
    }

    func updateAccessCode(
        _ newAccessCode: String,
        enableBiometrics: Bool = false,
        context: MobileWalletContext
    ) throws {
        var aesEncryptionKey = try getEncryptionKey(for: context.walletID, auth: context.authentication)
        defer { secureErase(data: &aesEncryptionKey) }

        try encryptedSecureStorage.storeData(
            aesEncryptionKey,
            keyTag: context.walletID.encryptionKeyTag,
            secureEnclaveKeyTag: context.walletID.encryptionKeySecureEnclaveTag,
            accessCode: newAccessCode
        )

        // errors are ignored here, as biometrics storage is optional
        try? encryptedBiometricsStorage.deleteData(
            keyTag: context.walletID.encryptionKeyBiometricsTag,
            secureEnclaveKeyTag: context.walletID.encryptionKeyBiometricsSecureEnclaveTag
        )

        if enableBiometrics {
            try encryptedBiometricsStorage.storeData(
                aesEncryptionKey,
                keyTag: context.walletID.encryptionKeyBiometricsTag,
                secureEnclaveKeyTag: context.walletID.encryptionKeyBiometricsSecureEnclaveTag
            )
        }
    }

    func enableBiometrics(
        context: MobileWalletContext
    ) throws {
        var aesEncryptionKey = try getEncryptionKey(for: context.walletID, auth: context.authentication)
        defer { secureErase(data: &aesEncryptionKey) }

        try encryptedBiometricsStorage.storeData(
            aesEncryptionKey,
            keyTag: context.walletID.encryptionKeyBiometricsTag,
            secureEnclaveKeyTag: context.walletID.encryptionKeyBiometricsSecureEnclaveTag
        )
    }

    func isBiometricsEnabled(walletID: UserWalletId) -> Bool {
        encryptedBiometricsStorage.hasData(keyTag: walletID.encryptionKeyBiometricsTag)
    }

    func clearBiometrics(walletIDs: [UserWalletId]) {
        walletIDs.forEach { walletID in
            // errors are ignored here, as biometrics storage is optional
            try? encryptedBiometricsStorage.deleteData(
                keyTag: walletID.encryptionKeyBiometricsTag,
                secureEnclaveKeyTag: walletID.encryptionKeyBiometricsSecureEnclaveTag
            )
        }
    }

    func delete(walletID: UserWalletId) throws {
        var errors = [Error]()

        do {
            try privateInfoStorage.deletePrivateInfoData(for: walletID)
        } catch {
            errors.append(error)
        }

        do {
            try encryptedSecureStorage.deleteData(
                keyTag: walletID.encryptionKeyTag,
                secureEnclaveKeyTag: walletID.encryptionKeySecureEnclaveTag
            )
        } catch {
            errors.append(error)
        }

        // biometrics storage is optional, so we don't throw an error if it fails to delete
        try? encryptedBiometricsStorage.deleteData(
            keyTag: walletID.encryptionKeyBiometricsTag,
            secureEnclaveKeyTag: walletID.encryptionKeyBiometricsSecureEnclaveTag
        )

        if !errors.isEmpty {
            throw CompoundMobileWalletError(underlying: errors)
        }
    }
}

/// - Encryption key storage
private extension PrivateInfoStorageManager {
    func getEncryptionKey(for walletID: UserWalletId, auth: AuthenticationUnlockData) throws -> Data {
        switch auth {
        case .accessCode(let accessCode):
            try encryptedSecureStorage.getData(
                keyTag: walletID.encryptionKeyTag,
                secureEnclaveKeyTag: walletID.encryptionKeySecureEnclaveTag,
                accessCode: accessCode
            )
        case .biometrics(let context):
            try encryptedBiometricsStorage.getData(
                keyTag: walletID.encryptionKeyBiometricsTag,
                secureEnclaveKeyTag: walletID.encryptionKeyBiometricsSecureEnclaveTag,
                context: context
            )
        case .none:
            try encryptedSecureStorage.getData(
                keyTag: walletID.encryptionKeyTag,
                secureEnclaveKeyTag: walletID.encryptionKeySecureEnclaveTag,
                accessCode: nil
            )
        }
    }
}

extension PrivateInfoStorageManager {
    enum Constants {
        static let aesKeySize = 32
    }
}

/// Define errors for better error handling
enum PrivateInfoStorageError: Error {
    case noEncryptionType(walletID: UserWalletId)
    case invalidEncryptionType(walletID: UserWalletId)
    case noInfo(tag: String)
    case unknown
}
