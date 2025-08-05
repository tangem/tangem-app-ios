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
        secureEnclaveService: HotSecureEnclaveService = SecureEnclaveService()
    ) {
        self.secureStorage = secureStorage
        self.secureEnclaveService = secureEnclaveService
    }

    func storeEncryptionKey(_ aesEncryptionKey: Data, for walletID: UserWalletId, accessCode: String) throws {
        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            aesEncryptionKey,
            keyTag: walletID.encryptionKeySecureEnclaveTag
        )

        let encryptedAesKey = try AESEncoder.encryptWithPassword(
            password: accessCode,
            content: secureEnclaveEncryptedKey
        )

        try secureStorage.store(encryptedAesKey, forKey: walletID.encryptionKeyTag)
    }

    func getEncryptionKey(for walletID: UserWalletId, accessCode: String) throws -> Data {
        guard let encryptedAesKey = try secureStorage.get(walletID.encryptionKeyTag) else {
            throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
        }

        let secureEnclaveEncryptedKey = try AESEncoder.decryptWithPassword(
            password: accessCode,
            encryptedData: encryptedAesKey
        )

        return try secureEnclaveService.decryptData(
            secureEnclaveEncryptedKey,
            keyTag: walletID.encryptionKeySecureEnclaveTag
        )
    }

    func deleteEncryptionKey(for walletID: UserWalletId) throws {
        try secureStorage.delete(walletID.encryptionKeyTag)
    }
}
