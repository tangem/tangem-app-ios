//
//  SendSourceToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress
import struct TangemUI.TokenIconInfo
import struct TangemAccounts.AccountIconView

struct SendSourceToken {
    // Wallet info. Signer, userWalletId, etc.

    let userWalletInfo: UserWalletInfo

    // Token info. Basically for UI

    let header: SendTokenHeader
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let fiatItem: FiatItem
    let possibleToConvertToFiat: Bool

    let availableBalanceProvider: TokenBalanceProvider
    let fiatAvailableBalanceProvider: TokenBalanceProvider

    let defaultAddressString: String

    // Only for send

    let transactionValidator: TransactionValidator
    let transactionCreator: TransactionCreator
    let withdrawalNotificationProvider: WithdrawalNotificationProvider?
    let tokenFeeProvidersManager: TokenFeeProvidersManager

    // Common providers

    let tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider
    let transactionDispatcherProvider: any TransactionDispatcherProvider
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?
}

// MARK: - Equatable

extension SendSourceToken: Equatable {
    static func == (lhs: SendSourceToken, rhs: SendSourceToken) -> Bool {
        lhs.header == rhs.header && lhs.tokenItem == rhs.tokenItem
    }
}
