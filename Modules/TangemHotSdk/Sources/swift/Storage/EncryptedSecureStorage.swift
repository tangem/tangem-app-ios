//
//  EncryptedSecureStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

final class EncryptedSecureStorage {
    private let secureStorage: HotSecureStorage
    private let secureEnclaveService: HotSecureEnclaveService

    init(
        secureStorage: HotSecureStorage = SecureStorage(),
        secureEnclaveService: HotSecureEnclaveService = SecureEnclaveService()
    ) {
        self.secureStorage = secureStorage
        self.secureEnclaveService = secureEnclaveService
    }

    func storeData(
        _ data: Data,
        keyTag: String,
        secureEnclaveKeyTag: String,
        accessCode: String
    ) throws {
        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            data,
            keyTag: secureEnclaveKeyTag
        )

        let encryptedAesKey = try AESEncoder.encryptWithPassword(
            password: accessCode,
            content: secureEnclaveEncryptedKey
        )

        try secureStorage.store(encryptedAesKey, forKey: keyTag)
    }

    func getData(
        keyTag: String,
        secureEnclaveKeyTag: String,
        accessCode: String
    ) throws -> Data {
        guard let encryptedAesKey = try secureStorage.get(keyTag) else {
            throw PrivateInfoStorageError.noInfo(tag: keyTag)
        }

        let secureEnclaveEncryptedKey = try AESEncoder.decryptWithPassword(
            password: accessCode,
            encryptedData: encryptedAesKey
        )

        return try secureEnclaveService.decryptData(
            secureEnclaveEncryptedKey,
            keyTag: secureEnclaveKeyTag
        )
    }

    func deleteData(keyTag: String) throws {
        try secureStorage.delete(keyTag)
    }
}
