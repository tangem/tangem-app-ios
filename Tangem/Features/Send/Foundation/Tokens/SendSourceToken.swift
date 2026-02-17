//
//  SendSourceToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress
import TangemFoundation
import struct TangemUI.TokenIconInfo
import struct TangemAccounts.AccountIconView

protocol SendSourceToken: SendReceiveToken {
    var userWalletInfo: UserWalletInfo { get }

    var id: WalletModelId { get }
    var header: SendTokenHeader { get }
    var tokenHeader: ExpressInteractorTokenHeader? { get }
    var feeTokenItem: TokenItem { get }
    var isCustom: Bool { get }
    var possibleToConvertToFiat: Bool { get }
    var defaultAddressString: String { get }

    var availableBalanceProvider: TokenBalanceProvider { get }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { get }

    var transactionValidator: TransactionValidator { get }
    var transactionCreator: TransactionCreator { get }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { get }
    var tokenFeeProvidersManager: TokenFeeProvidersManager { get }

    var tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider { get }
    var transactionDispatcherProvider: any TransactionDispatcherProvider { get }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { get }
}

struct CommonSendSourceToken: SendSourceToken {
    // Wallet info. Signer, userWalletId, etc.

    let userWalletInfo: UserWalletInfo

    // Token info. Basically for UI

    let id: WalletModelId
    let header: SendTokenHeader
    let tokenHeader: ExpressInteractorTokenHeader?
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let tokenIconInfo: TokenIconInfo
    let fiatItem: FiatItem
    let isCustom: Bool
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

extension CommonSendSourceToken: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.userWalletInfo.id == rhs.userWalletInfo.id && lhs.tokenItem == rhs.tokenItem
    }
}
