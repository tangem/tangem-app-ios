//
//  WalletInfoEncryptionStorage.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

class WalletInfoEncryptionStorage {
    private let secureStorage: SecureStorage

    init(secureStorage: SecureStorage) {
        self.secureStorage = secureStorage
    }

    func store(walletID: HotWalletID, password: String, data: Data) throws {
        let encryptedWithPassword = try AESEncoder.encryptWithPassword(
            password: password,
            content: data
        )
        try secureStorage.store(
            encryptedWithPassword,
            forKey: Constants.encryptionKeyAliasPrefix + walletID.value
        )
    }

    func get(walletID: HotWalletID, password: String) throws -> Data? {
        guard let encryptedData = try secureStorage.get(
            Constants.encryptionKeyAliasPrefix + walletID.value
        ) else { return nil }

        return try AESEncoder.decryptWithPassword(
            password: password,
            encryptedData: encryptedData
        )
    }
}

private extension WalletInfoEncryptionStorage {
    enum Constants {
        static let encryptionKeyAliasPrefix = "encryption_key_"
    }
}
