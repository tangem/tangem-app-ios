//
//  PolymarketAccountId.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

struct PolymarketAccountId: Hashable {
    let userWalletId: UserWalletId
}

// MARK: - AccountModelPersistentIdentifierConvertible

extension PolymarketAccountId: AccountModelPersistentIdentifierConvertible {
    func toPersistentIdentifier() -> String {
        "Polymarket/\(userWalletId.stringValue)"
    }
}
