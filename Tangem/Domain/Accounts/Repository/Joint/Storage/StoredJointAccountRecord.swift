//
//  StoredJointAccountRecord.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Anything the wallet keeps per joint account, found by the identifier the account is known by.
protocol StoredJointAccountRecord {
    var cryptoAccountId: String { get }
}

extension StoredJointAccount: StoredJointAccountRecord {}

extension StoredJointAccountInvites: StoredJointAccountRecord {}

extension Collection where Element: StoredJointAccountRecord {
    /// - Note: Matched without regard to case, which is the one rule every reader of these records shares: the
    /// endpoint spells the identifier its own way and the app spells it another.
    func first(by cryptoAccountId: String) -> Element? {
        first { $0.cryptoAccountId.caseInsensitiveEquals(to: cryptoAccountId) }
    }

    func firstIndex(by cryptoAccountId: String) -> Index? {
        firstIndex { $0.cryptoAccountId.caseInsensitiveEquals(to: cryptoAccountId) }
    }
}
