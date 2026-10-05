//
//  KeychainCollectiblesSessionKeyWalletIdStore.swift
//  TangemCollectibles
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
public import TangemFoundation
import TangemSdk

public struct KeychainCollectiblesSessionKeyWalletIdStore: CollectiblesSessionKeyWalletIdStore {
    private let secureStorage = SecureStorage()

    public init() {}

    public func sessionKeyWalletId(for userWalletId: UserWalletId) throws -> UserWalletId? {
        try secureStorage.get(account(for: userWalletId)).map(UserWalletId.init(value:))
    }

    public func setSessionKeyWalletId(_ sessionKeyWalletId: UserWalletId?, for userWalletId: UserWalletId) throws {
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
