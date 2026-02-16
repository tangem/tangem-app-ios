//
//  SwapSourceToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemUI
import TangemExpress

protocol SwapSourceToken: SendSourceToken, ExpressSourceWallet {
    var isExemptFee: Bool { get }
    var sendingRestrictions: SendingRestrictions? { get }
    var amountToCreateAccount: Decimal { get }
    var allowanceService: (any AllowanceService)? { get }
}

struct CommonSwapSourceToken: SwapSourceToken {
    // Wallet info. Signer, userWalletId, etc.

    let userWalletInfo: UserWalletInfo

    // Token info. Basically for UI

    let id: WalletModelId
    let header: SendTokenHeader
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

    // Only for swap

    var isExemptFee: Bool { false }
    var sendingRestrictions: SendingRestrictions? { .none }
    var amountToCreateAccount: Decimal { 0 }

    let analyticsLogger: any ExpressAnalyticsLogger
    let operationType: ExpressOperationType
    let supportedProvidersFilter: SupportedProvidersFilter
    let allowanceService: (any AllowanceService)?
    let balanceProvider: any ExpressBalanceProvider

    // Common providers

    let tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider
    let transactionDispatcherProvider: any TransactionDispatcherProvider
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?
}

// MARK: - Equatable

extension CommonSwapSourceToken: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.userWalletInfo.id == rhs.userWalletInfo.id && lhs.tokenItem == rhs.tokenItem
    }
}

// MARK: ExpressSourceWallet + ExpressInteractorSourceWallet

extension ExpressSourceWallet where Self: SwapSourceToken {
    var address: String? { defaultAddressString }
    // No extraId on Tangem's wallets
    var extraId: String? { .none }
    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    var coinCurrency: ExpressWalletCurrency { feeTokenItem.expressCurrency }
    var feeCurrency: ExpressWalletCurrency { feeTokenItem.expressCurrency }
    var allowanceProvider: (any ExpressAllowanceProvider)? { allowanceService }
    var expressFeeProviderFactory: ExpressFeeProviderFactory { tokenFeeProvidersManagerProvider }
}
