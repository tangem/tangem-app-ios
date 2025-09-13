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
    private let suiteName: String?
    private var userDefaults: UserDefaults { UserDefaults(suiteName: suiteName?.nilIfEmpty) ?? .standard }

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private func makeKey(for userWalletId: UserWalletId) -> String {
        "CryptoAccountsETagStorage_\(userWalletId.stringValue)"
    }
}

// MARK: - CryptoAccountsETagStorage protocol conformance

extension CommonCryptoAccountsETagStorage: CryptoAccountsETagStorage {
    func loadETag(for userWalletId: UserWalletId) -> String? {
        let key = makeKey(for: userWalletId)
        return userDefaults.string(forKey: key)
    }

    func saveETag(_ eTag: String, for userWalletId: UserWalletId) {
        let key = makeKey(for: userWalletId)
        userDefaults.set(eTag, forKey: key)
    }
}
