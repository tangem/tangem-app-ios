//
//  KeychainCollectiblesSessionKeyWalletIdStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemSdk

struct KeychainCollectiblesSessionKeyWalletIdStore: CollectiblesSessionKeyWalletIdStore {
    private let secureStorage = SecureStorage()

    func sessionKeyWalletId(for userWalletId: UserWalletId) throws -> UserWalletId? {
        try secureStorage.get(account(for: userWalletId)).map(UserWalletId.init(value:))
    }

    func setSessionKeyWalletId(_ sessionKeyWalletId: UserWalletId?, for userWalletId: UserWalletId) throws {
        let account = account(for: userWalletId)

        guard let sessionKeyWalletId else {
            return try secureStorage.delete(account)
        }

        try secureStorage.store(sessionKeyWalletId.value, forKey: account)
    }
}

// MARK: - Private implementation

private extension KeychainCollectiblesSessionKeyWalletIdStore {
    func account(for userWalletId: UserWalletId) -> String {
        Constants.accountPrefix + userWalletId.stringValue.lowercased()
    }

    enum Constants {
        static let accountPrefix = "collectibles_session_key_wallet_id_"
    }
}
