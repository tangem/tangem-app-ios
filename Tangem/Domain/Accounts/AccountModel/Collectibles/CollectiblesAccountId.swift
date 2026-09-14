//
//  CollectiblesAccountId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Local identity — a wallet holds at most one collectibles account. Becomes the record's own identity
/// once the backend serves one.
struct CollectiblesAccountId: Hashable {
    let userWalletId: UserWalletId
}

// MARK: - AccountModelPersistentIdentifierConvertible

extension CollectiblesAccountId: AccountModelPersistentIdentifierConvertible {
    func toPersistentIdentifier() -> String {
        "Collectibles/\(userWalletId.stringValue)"
    }
}
