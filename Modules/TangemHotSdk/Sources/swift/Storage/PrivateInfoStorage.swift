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
    private let secureEnclaveService: HotSecureEnclaveService

    init(
        secureStorage: HotSecureStorage = SecureStorage(),
        secureEnclaveService: HotSecureEnclaveService = SecureEnclaveService(config: .default),
    ) {
        self.secureStorage = secureStorage
        self.secureEnclaveService = secureEnclaveService
    }

    func storePrivateInfoData(
        _ privateInfoData: Data,
        for walletID: HotWalletID,
        aesEncryptionKey: Data,
    ) throws {
        let aesEncryptedData = try AESEncoder.encryptAES(
            rawEncryptionKey: aesEncryptionKey,
            rawData: privateInfoData
        )
        
        let secureEnclaveEncryptedData = try secureEnclaveService.encryptData(
            aesEncryptedData,
            keyTag: walletID.storageKey
        )

        try secureStorage.store(secureEnclaveEncryptedData, forKey: walletID.storageKey)
    }

    func getPrivateInfoData(
        for walletID: HotWalletID,
        aesEncryptionKey: Data
    ) throws -> Data {
        guard let secureEnclaveEncryptedData = try secureStorage.get(walletID.storageKey) else {
            throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
        }
        
        let aesEncryptedData = try secureEnclaveService.decryptData(
            secureEnclaveEncryptedData,
            keyTag: walletID.storageKey
        )

        return try AESEncoder.decryptAES(
            rawEncryptionKey: aesEncryptionKey,
            encryptedData: aesEncryptedData
        )
    }

    func delete(hotWalletID: HotWalletID) throws {
        try secureStorage.delete(hotWalletID.storageKey)
    }
}
