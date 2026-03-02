//
//  CommonSendSwapableToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

struct CommonSendSwapableToken: SendSwapableToken {
    let sourceToken: SendSourceToken
    let isExemptFee: Bool

    let sendingRestrictionsProvider: any SendingRestrictionsProvider
    let receivingRestrictionsProvider: any ReceivingRestrictionsProvider
    let tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider
    let expressTransactionValidator: any ExpressTransactionValidator

    let balanceProvider: any TangemExpress.BalanceProvider
    let analyticsLogger: any TangemExpress.AnalyticsLogger
    let providerTransactionValidator: any TangemExpress.ExpressProviderTransactionValidator
    let operationType: TangemExpress.ExpressOperationType
    let supportedProvidersFilter: TangemExpress.SupportedProvidersFilter

    // MARK: - SendSourceToken proxy properties

    var userWalletInfo: UserWalletInfo { sourceToken.userWalletInfo }
    var id: WalletModelId { sourceToken.id }
    var header: TokenHeader { sourceToken.header }
    var feeTokenItem: TokenItem { sourceToken.feeTokenItem }
    var isFixedFee: Bool { sourceToken.isFixedFee }
    var isCustom: Bool { sourceToken.isCustom }
    var defaultAddressString: String { sourceToken.defaultAddressString }

    var availableBalanceProvider: any TokenBalanceProvider { sourceToken.availableBalanceProvider }
    var fiatAvailableBalanceProvider: any TokenBalanceProvider { sourceToken.fiatAvailableBalanceProvider }
    var allowanceService: (any AllowanceService)? { sourceToken.allowanceService }
    var withdrawalNotificationProvider: (any BlockchainSdk.WithdrawalNotificationProvider)? { sourceToken.withdrawalNotificationProvider }
    var emailDataCollectorBuilder: any EmailDataCollectorBuilder { sourceToken.emailDataCollectorBuilder }

    var transactionDispatcherProvider: any TransactionDispatcherProvider { sourceToken.transactionDispatcherProvider }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { sourceToken.accountModelAnalyticsProvider }

    var tokenItem: TokenItem { sourceToken.tokenItem }
    var fiatItem: FiatItem { sourceToken.fiatItem }

    // Note: The following properties are provided by the extension in SendSwapableToken:
    // - address, extraId, currency, coinCurrency, feeCurrency
    // - allowanceProvider, expressFeeProviderFactory
    // These are automatically implemented using the proxied properties above
}
