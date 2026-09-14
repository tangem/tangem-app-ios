//
//  KeychainCollectiblesHotDelegateWalletIdStore.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemSdk

struct KeychainCollectiblesHotDelegateWalletIdStore: CollectiblesHotDelegateWalletIdStore {
    private let secureStorage = SecureStorage()

    func delegateWalletId(for userWalletId: UserWalletId) throws -> UserWalletId? {
        try secureStorage.get(account(for: userWalletId)).map(UserWalletId.init(value:))
    }

    func setDelegateWalletId(_ delegateWalletId: UserWalletId?, for userWalletId: UserWalletId) throws {
        let account = account(for: userWalletId)

        guard let delegateWalletId else {
            return try secureStorage.delete(account)
        }

        try secureStorage.store(delegateWalletId.value, forKey: account)
    }
}

// MARK: - Private implementation

private extension KeychainCollectiblesHotDelegateWalletIdStore {
    func account(for userWalletId: UserWalletId) -> String {
        Constants.accountPrefix + userWalletId.stringValue.lowercased()
    }

    enum Constants {
        static let accountPrefix = "collectibles_hot_delegate_wallet_id_"
    }
}
