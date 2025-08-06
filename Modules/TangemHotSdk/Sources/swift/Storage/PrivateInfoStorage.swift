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
        secureEnclaveService: HotSecureEnclaveService = SecureEnclaveService()
    ) {
        self.secureStorage = secureStorage
        self.secureEnclaveService = secureEnclaveService
    }

    func storePrivateInfoData(
        _ privateInfoData: Data,
        for walletID: UserWalletId,
        aesEncryptionKey: Data,
    ) throws {
        let secureEnclaveEncryptedData = try secureEnclaveService.encryptData(
            privateInfoData,
            keyTag: walletID.privateInfoSecureEnclaveTag
        )

        let aesEncryptedData = try AESEncoder.encryptAES(
            rawEncryptionKey: aesEncryptionKey,
            rawData: secureEnclaveEncryptedData
        )

        try secureStorage.store(aesEncryptedData, forKey: walletID.privateInfoTag)
    }

    func hasPrivateInfoData(for walletID: UserWalletId) -> Bool {
        (try? secureStorage.get(walletID.privateInfoTag)) != nil
    }

    func getPrivateInfoData(
        for walletID: UserWalletId,
        aesEncryptionKey: Data
    ) throws -> Data {
        guard let aesEncryptedData = try secureStorage.get(walletID.privateInfoTag) else {
            throw PrivateInfoStorageError.noInfo(tag: walletID.stringValue)
        }

        let secureEnclaveEncryptedData = try AESEncoder.decryptAES(
            rawEncryptionKey: aesEncryptionKey,
            encryptedData: aesEncryptedData
        )

        return try secureEnclaveService.decryptData(
            secureEnclaveEncryptedData,
            keyTag: walletID.privateInfoSecureEnclaveTag
        )
    }

    func deletePrivateInfoData(for walletID: UserWalletId) throws {
        try secureStorage.delete(walletID.privateInfoTag)
    }
}
