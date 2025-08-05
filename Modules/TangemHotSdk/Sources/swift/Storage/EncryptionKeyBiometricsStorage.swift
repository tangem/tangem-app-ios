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
    private let secureEnclaveService: HotBiometricsSecureEnclaveService

    init(
        biometricsStorage: HotBiometricsStorage = BiometricsStorage(),
        secureEnclaveService: HotBiometricsSecureEnclaveService = BiometricsSecureEnclaveService()
    ) {
        self.biometricsStorage = biometricsStorage
        self.secureEnclaveService = secureEnclaveService
    }

    func storeEncryptionKey(_ aesEncryptionKey: Data, for walletID: UserWalletId) throws {
        let secureEnclaveEncryptedKey = try secureEnclaveService.encryptData(
            aesEncryptionKey,
            keyTag: walletID.encryptionKeyBiometricsSecureEnclaveTag,
            context: nil
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

        return try secureEnclaveService.decryptData(
            secureEnclaveEncryptedData,
            keyTag: walletID.encryptionKeyBiometricsSecureEnclaveTag,
            context: context
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
