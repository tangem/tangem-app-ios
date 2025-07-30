//
//  PrivateInfoStorage 2.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

final class EncryptedStorage {
    private let secureStorage: HotSecureStorage
    private let secureEnclaveService: HotSecureEnclaveService

    init(
        secureStorage: HotSecureStorage = SecureStorage(),
        secureEnclaveService: HotSecureEnclaveService = SecureEnclaveService(config: .default),
    ) {
        self.secureStorage = secureStorage
        self.secureEnclaveService = secureEnclaveService
    }

    func storeData(
        _ data: Data,
        storageKeyTag: String,
        secureEnclaveKeyTag: String,
        aesEncryptionKey: Data,
    ) throws {
        let secureEnclaveEncryptedData = try secureEnclaveService.encryptData(
            data,
            keyTag: secureEnclaveKeyTag
        )

        let aesEncryptedData = try AESEncoder.encryptAES(
            rawEncryptionKey: aesEncryptionKey,
            rawData: secureEnclaveEncryptedData
        )

        try secureStorage.store(aesEncryptedData, forKey: storageKeyTag)
    }

    func getData(
        storageKeyTag: String,
        secureEnclaveKeyTag: String,
        aesEncryptionKey: Data
    ) throws -> Data {
        guard let aesEncryptedData = try secureStorage.get(storageKeyTag) else {
            throw PrivateInfoStorageError.noPrivateInfo(tag: storageKeyTag)
        }

        let secureEnclaveEncryptedData = try AESEncoder.decryptAES(
            rawEncryptionKey: aesEncryptionKey,
            encryptedData: aesEncryptedData
        )

        return try secureEnclaveService.decryptData(
            secureEnclaveEncryptedData,
            keyTag: secureEnclaveKeyTag
        )
    }

    func deleteData(storageKeyTag: String) throws {
        try secureStorage.delete(storageKeyTag)
    }
}
