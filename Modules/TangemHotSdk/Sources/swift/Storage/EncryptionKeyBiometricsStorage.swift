//
//  PrivateInfoBiometricsStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import LocalAuthentication

final class EncryptionKeyBiometricsStorage {
    private let biometricsStorage: HotBiometricsStorage
    private let secureEnclaveServiceType: HotSecureEnclaveService.Type
    
    init(
        biometricsStorage: HotBiometricsStorage = BiometricsStorage(),
        secureEnclaveServiceType: HotSecureEnclaveService.Type = SecureEnclaveService.self
    ) {
        self.biometricsStorage = biometricsStorage
        self.secureEnclaveServiceType = secureEnclaveServiceType
    }
    
    public func enableBiometrics(for walletID: HotWalletID, aesEncryptionKey: Data, context: LAContext) throws {
        let biometricsKey = try sharedBiometricsEncryptionKey(context: context)
        
        let aesEncryptedKey = try AESEncoder.encryptAES(
            rawEncryptionKey: biometricsKey,
            rawData: aesEncryptionKey
        )
        
        let secureEnclaveService = secureEnclaveServiceType.init(config: .biometrics(context))
        
        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            aesEncryptedKey,
            keyTag: walletID.storageEncryptionKey
        )
        
        try biometricsStorage.store(secureEnclaveEncryptedKey, forKey: walletID.storageEncryptionKey)
    }
    
    func encryptionKey(for walletID: HotWalletID, context: LAContext) throws -> Data {
        guard let secureEnclaveEncryptedData = try biometricsStorage.get(
            walletID.storageEncryptionKey,
            context: context
        ) else {
            throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
        }
        
        let secureEnclaveService = secureEnclaveServiceType.init(config: .biometrics(context))

        let encryptedAesKey = try secureEnclaveService.decryptData(
            secureEnclaveEncryptedData,
            keyTag: walletID.storageEncryptionKey
        )

        let biometricsKey = try sharedBiometricsEncryptionKey(context: context)
        
        return try AESEncoder.decryptAES(rawEncryptionKey: biometricsKey, encryptedData: encryptedAesKey)
    }
    
    func deleteEncryptionKey(for hotWalletID: HotWalletID) throws {
        try biometricsStorage.delete(hotWalletID.storageEncryptionKey)
    }
}

private extension EncryptionKeyBiometricsStorage {
    func sharedBiometricsEncryptionKey(context: LAContext) throws -> Data {
        let secureEnclaveService = secureEnclaveServiceType.init(config: .biometrics(context))
        
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


private extension EncryptionKeyBiometricsStorage {
    enum Constants {
        static let sharedBiometricsEncryptionKey = "hotsdk_shared_biometrics_encryption_key"
        static let aesKeySize = 32
    }
}
