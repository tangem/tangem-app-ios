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

protocol SendSourceToken: SendReceiveToken, ExpressSourceWallet {
    var userWalletInfo: UserWalletInfo { get }

    var id: WalletModelId { get }
    var header: TokenHeader { get }
    var feeTokenItem: TokenItem { get }
    var isExemptFee: Bool { get }
    var isFixedFee: Bool { get }
    var isCustom: Bool { get }
    var possibleToConvertToFiat: Bool { get }
    var defaultAddressString: String { get }

    var availableBalanceProvider: TokenBalanceProvider { get }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { get }
    var allowanceService: (any AllowanceService)? { get }
    var emailDataCollectorBuilder: EmailDataCollectorBuilder { get }

    var transactionValidator: TransactionValidator { get }
    var transactionCreator: TransactionCreator { get }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { get }
    var tokenFeeProvidersManager: TokenFeeProvidersManager { get }

    var sendingRestrictionsProvider: any SendingRestrictionsProvider { get }
    var receivingRestrictionsProvider: any ReceivingRestrictionsProvider { get }

    var tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider { get }
    var transactionDispatcherProvider: any TransactionDispatcherProvider { get }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { get }
}

// MARK: ExpressSourceWallet + SendSourceToken

extension ExpressSourceWallet where Self: SendSourceToken {
    var address: String? { defaultAddressString }
    var extraId: String? { .none }
    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    var coinCurrency: ExpressWalletCurrency { feeTokenItem.expressCurrency }
    var feeCurrency: ExpressWalletCurrency { feeTokenItem.expressCurrency }
    var allowanceProvider: (any ExpressAllowanceProvider)? { allowanceService }
    var expressFeeProviderFactory: ExpressFeeProviderFactory { tokenFeeProvidersManagerProvider }
}

struct CommonSendSourceToken: SendSourceToken {
    // Wallet info. Signer, userWalletId, etc.

    let userWalletInfo: UserWalletInfo

    // Token info. Basically for UI

    let id: WalletModelId
    let header: TokenHeader
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let isExemptFee: Bool
    let isFixedFee: Bool
    let tokenIconInfo: TokenIconInfo
    let fiatItem: FiatItem
    let isCustom: Bool
    let possibleToConvertToFiat: Bool

    let availableBalanceProvider: TokenBalanceProvider
    let fiatAvailableBalanceProvider: TokenBalanceProvider
    let allowanceService: (any AllowanceService)?
    let emailDataCollectorBuilder: any EmailDataCollectorBuilder

    let defaultAddressString: String

    // Only for send

    let transactionValidator: TransactionValidator
    let transactionCreator: TransactionCreator
    let withdrawalNotificationProvider: WithdrawalNotificationProvider?
    let tokenFeeProvidersManager: TokenFeeProvidersManager

    // Common providers

    let sendingRestrictionsProvider: any SendingRestrictionsProvider
    let receivingRestrictionsProvider: any ReceivingRestrictionsProvider

    let tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider
    let transactionDispatcherProvider: any TransactionDispatcherProvider
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?

    // Express

    let balanceProvider: any BalanceProvider
    let analyticsLogger: any AnalyticsLogger
    let operationType: ExpressOperationType
    let supportedProvidersFilter: SupportedProvidersFilter
    let providerTransactionValidator: any ExpressProviderTransactionValidator
}

// MARK: - Equatable

extension CommonSendSourceToken: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.userWalletInfo.id == rhs.userWalletInfo.id && lhs.tokenItem == rhs.tokenItem
    }
}
