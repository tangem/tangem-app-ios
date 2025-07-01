//
//  SendSourceToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import struct TangemUI.TokenIconInfo

struct SendSourceToken {
    let wallet: String
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let fiatItem: FiatItem

    let availableBalanceProvider: TokenBalanceProvider
    let fiatAvailableBalanceProvider: TokenBalanceProvider
    let transactionValidator: TransactionValidator
    let transactionCreator: TransactionCreator
    let transactionDispatcher: TransactionDispatcher
}

// MARK: - Equatable

extension SendSourceToken: Equatable {
    static func == (lhs: SendSourceToken, rhs: SendSourceToken) -> Bool {
        lhs.wallet == rhs.wallet && lhs.tokenItem == rhs.tokenItem
    }
}
