//
//  TransactionHistoryProviderKey.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
@preconcurrency import TangemFoundation

struct TransactionHistoryProviderKey: Sendable, Hashable {
    let userWalletId: UserWalletId
    let address: String
}
