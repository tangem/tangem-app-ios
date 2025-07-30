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
    private let encryptionKeySecureStorage: EncryptionKeySecureStorage
    private let encryptionKeyBiometricsStorage: EncryptionKeyBiometricsStorage

    init(
        privateInfoStorage: PrivateInfoStorage,
        encryptionKeySecureStorage: EncryptionKeySecureStorage,
        encryptionKeyBiometricsStorage: EncryptionKeyBiometricsStorage
    ) {
        self.privateInfoStorage = privateInfoStorage
        self.encryptionKeySecureStorage = encryptionKeySecureStorage
        self.encryptionKeyBiometricsStorage = encryptionKeyBiometricsStorage
    }

    func storeUnsecured(
        privateInfoData: Data,
        walletID: UserWalletId,
    ) throws {
        var aesEncryptionKey = try CryptoUtils.generateRandomBytes(count: Constants.aesKeySize)
        defer { secureErase(data: &aesEncryptionKey) }

        try privateInfoStorage.storePrivateInfoData(privateInfoData, for: walletID, aesEncryptionKey: aesEncryptionKey)

        try encryptionKeySecureStorage.storeEncryptionKey(
            aesEncryptionKey,
            for: walletID,
            accessCode: Constants.defaultAccessCode
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

        try encryptionKeySecureStorage.storeEncryptionKey(
            aesEncryptionKey,
            for: context.walletID,
            accessCode: newAccessCode
        )
    }

    public func enableBiometrics(
        context: MobileWalletContext,
        laContext: LAContext
    ) throws {
        let aesEncryptionKey = try getEncryptionKey(for: context.walletID, auth: context.authentication)

        try encryptionKeyBiometricsStorage.storeEncryptionKey(
            aesEncryptionKey,
            for: context.walletID,
            context: laContext
        )
    }

    func delete(hotWalletID: UserWalletId) throws {
        try privateInfoStorage.deletePrivateInfoData(for: hotWalletID)

        try encryptionKeySecureStorage.deleteEncryptionKey(for: hotWalletID)

        try? encryptionKeyBiometricsStorage.deleteEncryptionKey(for: hotWalletID)
    }
}

/// - Encryption key storage
private extension PrivateInfoStorageManager {
    func getEncryptionKey(for walletID: UserWalletId, auth: AuthenticationUnlockData) throws -> Data {
        switch auth {
        case .accessCode(let accessCode):
            try encryptionKeySecureStorage.getEncryptionKey(for: walletID, accessCode: accessCode)
        case .biometrics(let context):
            try encryptionKeyBiometricsStorage.getEncryptionKey(for: walletID, context: context)
        case .none:
            try encryptionKeySecureStorage.getEncryptionKey(for: walletID, accessCode: Constants.defaultAccessCode)
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
        static let defaultAccessCode = "0000"
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
    case noPrivateInfo(tag: String)
    case unknown
}

func secureErase(data: inout Data) {
    _ = data.withUnsafeMutableBytes { bytes in
        memset_s(bytes.baseAddress, bytes.count, 0, bytes.count)
    }
}
