//
//  EncryptionKeyBiometricsStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import LocalAuthentication
import TangemFoundation

final class EncryptionKeyBiometricsStorage {
    private let biometricsStorage: HotBiometricsStorage
    private let secureEnclaveServiceType: HotSecureEnclaveService.Type

    init(
        biometricsStorage: HotBiometricsStorage = BiometricsStorage(),
        secureEnclaveServiceType: HotSecureEnclaveService.Type = SecureEnclaveService.self
    ) {
        self.biometricsStorage = biometricsStorage
        self.secureEnclaveServiceType = secureEnclaveServiceType
    }

    func storeEncryptionKey(_ aesEncryptionKey: Data, for walletID: UserWalletId, context: LAContext) throws {
        let secureEnclaveService = secureEnclaveServiceType.init(config: .biometrics(context))

        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            aesEncryptionKey,
            keyTag: walletID.encryptionKeyBiometricsSecureEnclaveTag
        )

        try biometricsStorage.store(secureEnclaveEncryptedKey, forKey: walletID.encryptionKeyBiometricsTag)
    }

    func getEncryptionKey(for walletID: UserWalletId, context: LAContext) throws -> Data {
        guard let secureEnclaveEncryptedData = try biometricsStorage.get(
            walletID.encryptionKeyBiometricsTag,
            context: context
        ) else {
            throw PrivateInfoStorageError.noPrivateInfo(walletID: walletID)
        }

        let secureEnclaveService = secureEnclaveServiceType.init(config: .biometrics(context))

        return try secureEnclaveService.decryptData(
            secureEnclaveEncryptedData,
            keyTag: walletID.encryptionKeyBiometricsSecureEnclaveTag
        )
    }

    func deleteEncryptionKey(for walletID: UserWalletId) throws {
        try biometricsStorage.delete(walletID.encryptionKeyBiometricsTag)
    }
}

private extension EncryptionKeyBiometricsStorage {
    enum Constants {
        static let aesKeySize = 32
    }
}
