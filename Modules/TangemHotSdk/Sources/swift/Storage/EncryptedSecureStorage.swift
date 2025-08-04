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
        secureEnclaveService: HotSecureEnclaveService = SecureEnclaveService(config: .default)
    ) {
        self.secureStorage = secureStorage
        self.secureEnclaveService = secureEnclaveService
    }

    func storeData(
        _ data: Data,
        keyTag: String,
        secureEnclaveKeyTag: String,
        accessCode: String?
    ) throws {
        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            data,
            keyTag: secureEnclaveKeyTag
        )

        let encryptedAesKey = switch accessCode {
        case .some(let code):
            try AESEncoder.encryptWithPassword(
                password: code,
                content: secureEnclaveEncryptedKey
            )
        case .none:
            secureEnclaveEncryptedKey
        }

        try secureStorage.store(encryptedAesKey, forKey: keyTag)
    }

    func getData(
        keyTag: String,
        secureEnclaveKeyTag: String,
        accessCode: String?
    ) throws -> Data {
        guard let encryptedAesKey = try secureStorage.get(keyTag) else {
            throw PrivateInfoStorageError.noInfo(tag: keyTag)
        }

        let secureEnclaveEncryptedKey = switch accessCode {
        case .some(let code):
            try AESEncoder.decryptWithPassword(
                password: code,
                encryptedData: encryptedAesKey
            )
        case .none:
            encryptedAesKey
        }

        return try secureEnclaveService.decryptData(
            secureEnclaveEncryptedKey,
            keyTag: secureEnclaveKeyTag
        )
    }

    func deleteData(keyTag: String) throws {
        try secureStorage.delete(keyTag)
    }
}
