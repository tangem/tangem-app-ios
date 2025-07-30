//
//  File.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

final class PublicInfoStorage {
    private let storage: EncryptedStorage

    init(
        secureStorage: HotSecureStorage = SecureStorage(),
        secureEnclaveService: HotSecureEnclaveService = SecureEnclaveService(config: .default),
    ) {
        storage = EncryptedStorage(
            secureStorage: secureStorage,
            secureEnclaveService: secureEnclaveService
        )
    }

    func storePublicInfoData(
        _ publicInfoData: Data,
        for walletID: UserWalletId,
        aesEncryptionKey: Data,
    ) throws {
        try storage.storeData(
            publicInfoData,
            storageKeyTag: walletID.publicInfoTag,
            secureEnclaveKeyTag: walletID.publicInfoSecureEnclaveTag,
            aesEncryptionKey: aesEncryptionKey
        )
    }

    func getPublicInfoData(
        for walletID: UserWalletId,
        aesEncryptionKey: Data
    ) throws -> Data {
        try storage.getData(storageKeyTag: walletID.privateInfoTag, secureEnclaveKeyTag: walletID.privateInfoSecureEnclaveTag, aesEncryptionKey: aesEncryptionKey)
    }

    func deletePublicData(for walletID: UserWalletId) throws {
        try storage.deleteData(storageKeyTag: walletID.privateInfoTag)
    }
}
