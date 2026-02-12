//
//  SendSourceToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import struct TangemUI.TokenIconInfo
import struct TangemAccounts.AccountIconView

struct SendSourceToken {
    let userWalletInfo: UserWalletInfo
    let header: SendTokenHeader
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let fiatItem: FiatItem
    let possibleToConvertToFiat: Bool

    let tokenFeeProvidersManager: TokenFeeProvidersManager
    let availableBalanceProvider: TokenBalanceProvider
    let fiatAvailableBalanceProvider: TokenBalanceProvider
    let transactionValidator: TransactionValidator
    let transactionCreator: TransactionCreator
    let transactionDispatcherProvider: any TransactionDispatcherProvider
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?
}

// MARK: - Equatable

extension SendSourceToken: Equatable {
    static func == (lhs: SendSourceToken, rhs: SendSourceToken) -> Bool {
        lhs.header == rhs.header && lhs.tokenItem == rhs.tokenItem
    }
}
