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
    private let secureEnclaveService: SecureEnclaveService

    init(
        secureStorage: SecureStorage = SecureStorage(),
        biometricsStorage: BiometricsStorage = BiometricsStorage(),
        secureEnclaveService: SecureEnclaveService = SecureEnclaveService(config: .default)
    ) {
        self.secureStorage = secureStorage
        self.biometricsStorage = biometricsStorage
        self.secureEnclaveService = secureEnclaveService
    }
    
    func store(
        privateInfoData: Data,
        for walletID: HotWalletID,
        auth: Authentication?,
        encryptionKey: Data? = nil
    ) throws {
        var aesKey = try encryptionKey ?? CryptoUtils.generateRandomBytes(count: Constants.aesKeySize)

        defer { secureErase(data: &aesKey) }
        
        // store encrypted entropy
        let encrypted = try AESEncoder.encryptAES(
            rawEncryptionKey: aesKey,
            rawData: privateInfoData
        )
        
        try secureStorage.store(encrypted, forKey: walletID.storageKey)
        
        // store encryption key
        let encryptedAesKey: Data
        if let passcode = auth?.passcode {
            encryptedAesKey = try AESEncoder.encryptWithPassword(
                password: passcode,
                content: aesKey
            )
        } else {
            encryptedAesKey = aesKey
        }
        
        let keyToStore = try secureEnclaveService.encryptData(
            encryptedAesKey,
            keyTag: walletID.storageEncryptionKey
        )
        
        try secureStorage.store(keyToStore, forKey: walletID.storageEncryptionKey)
        
        if auth?.biometrics == true {
            try biometricsStorage.store(keyToStore, forKey: walletID.storageEncryptionKey)
        }
    }
    
    func getPrivateInfoData(for walletID: HotWalletID, auth: AuthenticationUnlockData?) throws -> Data {
        guard let encryptedData = try secureStorage.get(walletID.storageKey) else {
            throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
        }
        
        var encryptionKey = try encryptionKey(for: walletID, auth: auth)
        
        defer { secureErase(data: &encryptionKey) }
        
        return try AESEncoder.decryptAES(
            rawEncryptionKey: encryptionKey,
            encryptedData: encryptedData
        )
    }
    
    private func encryptionKey(for walletID: HotWalletID, auth: AuthenticationUnlockData?) throws -> Data {
        let encryptionKey = walletID.storageEncryptionKey
        
        switch auth {
        case .none:
            guard let key = try secureStorage.get(encryptionKey) else {
                throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
            }
            return try secureEnclaveService.decryptData(key, keyTag: walletID.storageEncryptionKey)
        case .passcode(let value):
            guard let key = try secureStorage.get(encryptionKey) else {
                throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
            }
            let decryptedKey = try secureEnclaveService.decryptData(key, keyTag: walletID.storageEncryptionKey)
            
            return try AESEncoder.decryptWithPassword(
                password: value,
                encryptedData: decryptedKey
            )
        case .biometrics(let context):
            guard let key = try biometricsStorage.get(encryptionKey, context: context) else {
                throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
            }
            return try secureEnclaveService.decryptData(key, keyTag: walletID.storageEncryptionKey)
        }
    }
    
    func updateStore(walletID: HotWalletID, oldAuth: AuthenticationUnlockData?, newAuth: Authentication?) throws {
        let privateInfoData = try getPrivateInfoData(for: walletID, auth: oldAuth)
        
        try store(privateInfoData: privateInfoData, for: walletID, auth: newAuth)
    }
    
    func delete(hotWalletID: HotWalletID) throws {
        let storageKey = Constants.privateInfoPrefix + hotWalletID.value
        try biometricsStorage.delete(storageKey)
        try secureStorage.delete(storageKey)
        try secureStorage.delete(hotWalletID.storageEncryptionKey)
        try secureStorage.delete(Constants.encryptionTypePrefix + hotWalletID.value)
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
    var storageEncryptionTypeKey: String { PrivateInfoStorage.Constants.encryptionTypePrefix + value }
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
        static let encryptionTypePrefix = "hotsdk_encryption_type_"
        static let aesKeySize = 32
    }
}
