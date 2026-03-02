//
//  CommonSendWithSwapToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

struct CommonSendWithSwapToken: SendWithSwapToken {
    let transferableToken: SendTransferableToken
    let swapableToken: SendSwapableToken

    // MARK: - SendTransferableToken proxy properties

    var transactionValidator: any BlockchainSdk.TransactionValidator { transferableToken.transactionValidator }
    var transactionCreator: any BlockchainSdk.TransactionCreator { transferableToken.transactionCreator }
    var tokenFeeProvidersManager: any TokenFeeProvidersManager { transferableToken.tokenFeeProvidersManager }

    // MARK: - SendSwapableToken proxy properties

    var isExemptFee: Bool { swapableToken.isExemptFee }
    var sendingRestrictionsProvider: any SendingRestrictionsProvider { swapableToken.sendingRestrictionsProvider }
    var receivingRestrictionsProvider: any ReceivingRestrictionsProvider { swapableToken.receivingRestrictionsProvider }
    var tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider { swapableToken.tokenFeeProvidersManagerProvider }
    var expressTransactionValidator: any ExpressTransactionValidator { swapableToken.expressTransactionValidator }

    var balanceProvider: any TangemExpress.BalanceProvider { swapableToken.balanceProvider }
    var analyticsLogger: any TangemExpress.AnalyticsLogger { swapableToken.analyticsLogger }
    var providerTransactionValidator: any TangemExpress.ExpressProviderTransactionValidator { swapableToken.providerTransactionValidator }
    var operationType: TangemExpress.ExpressOperationType { swapableToken.operationType }
    var supportedProvidersFilter: TangemExpress.SupportedProvidersFilter { swapableToken.supportedProvidersFilter }

    // MARK: - SendSourceToken proxy properties (from transferableToken)

    var userWalletInfo: UserWalletInfo { transferableToken.userWalletInfo }
    var id: WalletModelId { transferableToken.id }
    var header: TokenHeader { transferableToken.header }
    var feeTokenItem: TokenItem { transferableToken.feeTokenItem }
    var isFixedFee: Bool { transferableToken.isFixedFee }
    var isCustom: Bool { transferableToken.isCustom }
    var defaultAddressString: String { transferableToken.defaultAddressString }

    var availableBalanceProvider: any TokenBalanceProvider { transferableToken.availableBalanceProvider }
    var fiatAvailableBalanceProvider: any TokenBalanceProvider { transferableToken.fiatAvailableBalanceProvider }
    var allowanceService: (any AllowanceService)? { transferableToken.allowanceService }
    var withdrawalNotificationProvider: (any BlockchainSdk.WithdrawalNotificationProvider)? { transferableToken.withdrawalNotificationProvider }
    var emailDataCollectorBuilder: any EmailDataCollectorBuilder { transferableToken.emailDataCollectorBuilder }

    var transactionDispatcherProvider: any TransactionDispatcherProvider { transferableToken.transactionDispatcherProvider }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { transferableToken.accountModelAnalyticsProvider }

    var tokenItem: TokenItem { transferableToken.tokenItem }
    var fiatItem: FiatItem { transferableToken.fiatItem }
}
