//
//  EncryptionKeySecureStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

final class EncryptionKeySecureStorage {
    private let secureStorage: HotSecureStorage
    private let secureEnclaveService: HotSecureEnclaveService

    init(
        secureStorage: HotSecureStorage = SecureStorage(),
        secureEnclaveService: HotSecureEnclaveService = SecureEnclaveService(config: .default)
    ) {
        self.secureStorage = secureStorage
        self.secureEnclaveService = secureEnclaveService
    }

    func storeEncryptionKey(_ aesEncryptionKey: Data, for walletID: UserWalletId, accessCode: String) throws {
        let encryptedAesKey = try AESEncoder.encryptWithPassword(
            password: accessCode,
            content: aesEncryptionKey
        )

        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            encryptedAesKey,
            keyTag: walletID.privateInfoEncryptionKeyTag
        )

        try secureStorage.store(secureEnclaveEncryptedKey, forKey: walletID.privateInfoEncryptionKeyTag)
    }

    func getEncryptionKey(for walletID: UserWalletId, accessCode: String) throws -> Data {
        guard let secureEnclaveEncryptedKey = try secureStorage.get(walletID.privateInfoEncryptionKeyTag) else {
            throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
        }

        let encryptedAesKey = try secureEnclaveService.decryptData(
            secureEnclaveEncryptedKey,
            keyTag: walletID.privateInfoEncryptionKeyTag
        )

        return try AESEncoder.decryptWithPassword(password: accessCode, encryptedData: encryptedAesKey)
    }

    func deleteEncryptionKey(for walletID: UserWalletId) throws {
        try secureStorage.delete(walletID.privateInfoEncryptionKeyTag)
    }
}
