//
//  CommonCryptoAccountsETagStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

// [REDACTED_TODO_COMMENT]
final class CommonCryptoAccountsETagStorage {
    /// - Note: Despite the name, this inner storage is not limited to BlockchainSDK. It's just a convenient UserDefaults wrapper.
    private let innerStorage: UserDefaultsBlockchainDataStorage

    init(suiteName: String? = nil) {
        innerStorage = UserDefaultsBlockchainDataStorage(suiteName: suiteName)
    }

    private func makeKey(for userWalletId: UserWalletId) -> String {
        "CryptoAccountsETagStorage_\(userWalletId.stringValue)"
    }
}

// MARK: - CryptoAccountsETagStorage protocol conformance

extension CommonCryptoAccountsETagStorage: CryptoAccountsETagStorage {
    func loadETag(for userWalletId: UserWalletId) async -> String? {
        let key = makeKey(for: userWalletId)
        let eTag: String? = await innerStorage.get(key: key)

        return eTag
    }

    func saveETag(_ eTag: String, for userWalletId: UserWalletId) async {
        let key = makeKey(for: userWalletId)
        await innerStorage.store(key: key, value: eTag)
    }

    func clearETag(for userWalletId: UserWalletId) async {
        let key = makeKey(for: userWalletId)
        let value: String? = nil
        await innerStorage.store(key: key, value: value)
    }
}
