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
import TangemFoundation

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
        for walletID: UserWalletId,
        aesEncryptionKey: Data,
    ) throws {
        let aesEncryptedData = try AESEncoder.encryptAES(
            rawEncryptionKey: aesEncryptionKey,
            rawData: privateInfoData
        )

        let secureEnclaveEncryptedData = try secureEnclaveService.encryptData(
            aesEncryptedData,
            keyTag: walletID.privateInfoTag
        )

        try secureStorage.store(secureEnclaveEncryptedData, forKey: walletID.privateInfoTag)
    }

    func getPrivateInfoData(
        for walletID: UserWalletId,
        aesEncryptionKey: Data
    ) throws -> Data {
        guard let secureEnclaveEncryptedData = try secureStorage.get(walletID.privateInfoTag) else {
            throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
        }

        let aesEncryptedData = try secureEnclaveService.decryptData(
            secureEnclaveEncryptedData,
            keyTag: walletID.privateInfoTag
        )

        return try AESEncoder.decryptAES(
            rawEncryptionKey: aesEncryptionKey,
            encryptedData: aesEncryptedData
        )
    }

    func deletePrivateInfoData(for walletID: UserWalletId) throws {
        try secureStorage.delete(walletID.privateInfoTag)
    }
}
