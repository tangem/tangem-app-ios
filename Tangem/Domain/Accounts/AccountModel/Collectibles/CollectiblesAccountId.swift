//
//  CollectiblesAccountId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// One collectibles account per wallet, so the wallet is the identity — and stays it once the backend serves
/// a record, since swapping in a backend id would move the persistence key.
struct CollectiblesAccountId: Hashable {
    let userWalletId: UserWalletId
}

// MARK: - AccountModelPersistentIdentifierConvertible

extension CollectiblesAccountId: AccountModelPersistentIdentifierConvertible {
    func toPersistentIdentifier() -> String {
        "Collectibles/\(userWalletId.stringValue)"
    }
}
