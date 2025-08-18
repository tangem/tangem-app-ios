//
//  PublicInfoStorageManager.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import LocalAuthentication

/// Storage for UserWalletEncryptionKey data
final class PublicInfoStorageManager {
    private let encryptedSecureStorage: EncryptedSecureStorage

    init(encryptedSecureStorage: EncryptedSecureStorage) {
        self.encryptedSecureStorage = encryptedSecureStorage
    }

    func storeData(_ data: Data, walletID: UserWalletId, accessCode: String?) throws {
        try encryptedSecureStorage.storeData(
            data,
            keyTag: walletID.publicInfoTag,
            secureEnclaveKeyTag: walletID.publicInfoSecureEnclaveTag,
            accessCode: accessCode
        )
    }

    func data(for walletID: UserWalletId, accessCode: String?) throws -> Data {
        try encryptedSecureStorage.getData(
            keyTag: walletID.publicInfoTag,
            secureEnclaveKeyTag: walletID.publicInfoSecureEnclaveTag,
            accessCode: accessCode
        )
    }

    func deletePublicData(walletID: UserWalletId) throws {
        try encryptedSecureStorage.deleteData(keyTag: walletID.publicInfoTag)
    }
}
