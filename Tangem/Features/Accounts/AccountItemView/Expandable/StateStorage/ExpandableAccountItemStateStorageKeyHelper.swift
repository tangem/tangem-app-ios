//
//  ExpandableAccountItemStateStorageKeyHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum ExpandableAccountItemStateStorageKeyHelper {
    static func makeStorageKey(accountId: some AccountModelPersistentIdentifierConvertible, userWalletId: UserWalletId) -> String {
        return makeStorageKeyPrefix(userWalletId: userWalletId)
            + Constants.storageKeySeparator
            + makeStorageKeySuffix(accountId: accountId)
    }

    static func makeStorageKeyPrefix(userWalletId: UserWalletId) -> String {
        return userWalletId.stringValue
    }

    private static func makeStorageKeySuffix(accountId: some AccountModelPersistentIdentifierConvertible) -> String {
        return "\(accountId.toPersistentIdentifier())"
    }
}

// MARK: - Constants

private extension ExpandableAccountItemStateStorageKeyHelper {
    enum Constants {
        static let storageKeySeparator: String = "_"
    }
}
