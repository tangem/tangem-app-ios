//
//  PrivateInfoAccessCodeStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import LocalAuthentication

final class EncryptionKeyAccessCodeStorage {
    private let secureStorage: HotSecureStorage
    private let secureEnclaveService: HotSecureEnclaveService

    init(
        secureStorage: HotSecureStorage = SecureStorage(),
        secureEnclaveService: HotSecureEnclaveService = SecureEnclaveService(config: .default)
    ) {
        self.secureStorage = secureStorage
        self.secureEnclaveService = secureEnclaveService
    }
    
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

    func updateAccessCode(_ newAccessCode: String, aesEncryptionKey: Data, for walletID: HotWalletID) throws {
        let encryptedAesKey = try AESEncoder.encryptWithPassword(
            password: newAccessCode,
            content: aesEncryptionKey
        )

        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            encryptedAesKey,
            keyTag: walletID.storageEncryptionKey
        )

        try secureStorage.store(secureEnclaveEncryptedKey, forKey: walletID.storageEncryptionKey)
    }
    
    func encryptionKey(for walletID: HotWalletID, accessCode: String?) throws -> Data {
        guard let savedKeyData = try secureStorage.get(walletID.storageEncryptionKey) else {
            throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
        }

        let maybeEncryptedAesKey = try secureEnclaveService.decryptData(savedKeyData, keyTag: walletID.storageEncryptionKey)
        
        if let accessCode {
            return try AESEncoder.decryptWithPassword(password: accessCode, encryptedData: maybeEncryptedAesKey)
        }
        
        return maybeEncryptedAesKey
    }

    func deleteEncryptionKey(for hotWalletID: HotWalletID) throws {
        try secureStorage.delete(hotWalletID.storageEncryptionKey)
    }
}
