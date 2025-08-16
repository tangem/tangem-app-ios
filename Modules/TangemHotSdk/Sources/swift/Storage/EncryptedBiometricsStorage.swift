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

/// A storage for securely storing and retrieving data using biometrics and Secure Enclave.
final class EncryptedBiometricsStorage {
    private let biometricsStorage: HotBiometricsStorage
    private let secureEnclaveBiometricsService: HotBiometricsSecureEnclaveService

    init(
        biometricsStorage: HotBiometricsStorage = BiometricsStorage(),
        secureEnclaveService: HotBiometricsSecureEnclaveService = BiometricsSecureEnclaveService()
    ) {
        self.biometricsStorage = biometricsStorage
        secureEnclaveBiometricsService = secureEnclaveService
    }

    func storeData(
        _ data: Data,
        keyTag: String,
        secureEnclaveKeyTag: String
    ) throws {
        let secureEnclaveEncryptedKey = try secureEnclaveBiometricsService.encryptData(
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

        return try secureEnclaveBiometricsService.decryptData(
            secureEnclaveEncryptedData,
            keyTag: secureEnclaveKeyTag,
            context: context
        )
    }

    func deleteData(keyTag: String) throws {
        try biometricsStorage.delete(keyTag)
    }
}
