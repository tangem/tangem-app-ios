//
//  EncryptedBiometricsStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import LocalAuthentication
import TangemFoundation

final class EncryptedBiometricsStorage {
    private let biometricsStorage: HotBiometricsStorage
    private let secureEnclaveService: HotBiometricsSecureEnclaveService

    init(
        biometricsStorage: HotBiometricsStorage = BiometricsStorage(),
        secureEnclaveService: HotBiometricsSecureEnclaveService = BiometricsSecureEnclaveService()
    ) {
        self.biometricsStorage = biometricsStorage
        self.secureEnclaveService = secureEnclaveService
    }

    func storeData(
        _ data: Data,
        keyTag: String,
        secureEnclaveKeyTag: String
    ) throws {
        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            data,
            keyTag: secureEnclaveKeyTag,
            context: nil
        )

        try biometricsStorage.store(secureEnclaveEncryptedKey, forKey: keyTag)
    }

    func getData(
        keyTag: String,
        secureEnclaveKeyTag: String,
        context: LAContext
    ) throws -> Data {
        guard let secureEnclaveEncryptedData = try biometricsStorage.get(
            keyTag,
            context: context
        ) else {
            throw PrivateInfoStorageError.noInfo(tag: keyTag)
        }

        return try secureEnclaveService.decryptData(
            secureEnclaveEncryptedData,
            keyTag: secureEnclaveKeyTag,
            context: context
        )
    }

    func deleteData(keyTag: String) throws {
        try biometricsStorage.delete(keyTag)
    }
}
