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
        _ = try getEncryptionKey(for: walletID, auth: auth)

        return MobileWalletContext(walletID: walletID, authentication: auth)
    }

    func getPrivateInfoData(context: MobileWalletContext) throws -> Data {
        var aesEncryptionKey = try getEncryptionKey(for: context.walletID, auth: context.authentication)

        defer {
            secureErase(data: &aesEncryptionKey)
        }

        return try privateInfoStorage.getPrivateInfoData(for: context.walletID, aesEncryptionKey: aesEncryptionKey)
    }

    func updateAccessCode(
        _ newAccessCode: String,
        context: MobileWalletContext
    ) throws {
        let aesEncryptionKey = try getEncryptionKey(for: context.walletID, auth: context.authentication)

        try encryptedSecureStorage.storeData(
            aesEncryptionKey,
            keyTag: context.walletID.encryptionKeyTag,
            secureEnclaveKeyTag: context.walletID.encryptionKeySecureEnclaveTag,
            accessCode: newAccessCode
        )
    }

    public func enableBiometrics(
        context: MobileWalletContext
    ) throws {
        let aesEncryptionKey = try getEncryptionKey(for: context.walletID, auth: context.authentication)

        try encryptedBiometricsStorage.storeData(
            aesEncryptionKey,
            keyTag: context.walletID.encryptionKeyBiometricsTag,
            secureEnclaveKeyTag: context.walletID.encryptionKeyBiometricsSecureEnclaveTag,
        )
    }

    func delete(walletID: UserWalletId) throws {
        try privateInfoStorage.deletePrivateInfoData(for: walletID)

        try encryptedSecureStorage.deleteData(keyTag: walletID.encryptionKeyTag)

        try? encryptedBiometricsStorage.deleteData(keyTag: walletID.encryptionKeyBiometricsTag)
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
        static let privateInfoPrefix = "hotsdk_private_info_"
        static let privateInfoSecureEnclavePrefix = "hotsdk_private_info_secure_enclave_"
        static let encryptionKeyPrefix = "hotsdk_encryption_key_"
        static let encryptionKeySecureEnclavePrefix = "hotsdk_encryption_key_secure_enclave_"
        static let encryptionKeyBiometricsPrefix = "hotsdk_encryption_key_"
        static let encryptionKeyBiometricsSecureEnclavePrefix = "hotsdk_encryption_key_secure_enclave_"
        static let publicInfoPrefix = "hotsdk_public_info_"
        static let publicInfoSecureEnclavePrefix = "hotsdk_public_info_secure_enclave_"
        static let aesKeySize = 32
    }
}

extension UserWalletId {
    var privateInfoTag: String {
        PrivateInfoStorageManager.Constants.privateInfoPrefix + stringValue
    }

    var privateInfoSecureEnclaveTag: String {
        PrivateInfoStorageManager.Constants.privateInfoSecureEnclavePrefix + stringValue
    }

    var encryptionKeyTag: String {
        PrivateInfoStorageManager.Constants.encryptionKeyPrefix + stringValue
    }

    var encryptionKeySecureEnclaveTag: String {
        PrivateInfoStorageManager.Constants.encryptionKeySecureEnclavePrefix + stringValue
    }

    var encryptionKeyBiometricsTag: String {
        PrivateInfoStorageManager.Constants.encryptionKeyBiometricsPrefix + stringValue
    }

    var encryptionKeyBiometricsSecureEnclaveTag: String {
        PrivateInfoStorageManager.Constants.encryptionKeyBiometricsSecureEnclavePrefix + stringValue
    }

    var publicInfoTag: String {
        PrivateInfoStorageManager.Constants.publicInfoPrefix + stringValue
    }

    var publicInfoSecureEnclaveTag: String {
        PrivateInfoStorageManager.Constants.publicInfoSecureEnclavePrefix + stringValue
    }
}

/// Define errors for better error handling
enum PrivateInfoStorageError: Error {
    case noEncryptionType(walletID: UserWalletId)
    case invalidEncryptionType(walletID: UserWalletId)
    case noInfo(tag: String)
    case unknown
}

func secureErase(data: inout Data) {
    _ = data.withUnsafeMutableBytes { bytes in
        memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
    }
}
