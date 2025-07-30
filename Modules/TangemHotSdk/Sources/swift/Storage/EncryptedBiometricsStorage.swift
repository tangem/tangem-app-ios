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
    private let secureEnclaveServiceType: HotSecureEnclaveService.Type

    init(
        biometricsStorage: HotBiometricsStorage = BiometricsStorage(),
        secureEnclaveServiceType: HotSecureEnclaveService.Type = SecureEnclaveService.self
    ) {
        self.biometricsStorage = biometricsStorage
        self.secureEnclaveServiceType = secureEnclaveServiceType
    }

    func storeData(
        _ data: Data,
        keyTag: String,
        secureEnclaveKeyTag: String,
        context: LAContext
    ) throws {
        let secureEnclaveService = secureEnclaveServiceType.init(config: .biometrics(context))

        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            data,
            keyTag: secureEnclaveKeyTag
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

        let secureEnclaveService = secureEnclaveServiceType.init(config: .biometrics(context))

        return try secureEnclaveService.decryptData(
            secureEnclaveEncryptedData,
            keyTag: secureEnclaveKeyTag
        )
    }

    func deleteData(keyTag: String) throws {
        try biometricsStorage.delete(keyTag)
    }
}
