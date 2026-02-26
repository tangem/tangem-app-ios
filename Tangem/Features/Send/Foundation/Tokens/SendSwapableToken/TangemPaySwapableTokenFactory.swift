//
//  TangemPaySwapableTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

/// Maybe put in init `TangemPayAccount` ?
struct TangemPaySwapableTokenFactory {
    let userWalletInfo: UserWalletInfo
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let defaultAddressString: String
    let availableBalanceProvider: any TokenBalanceProvider
    let fiatAvailableBalanceProvider: any TokenBalanceProvider
    let cexTransactionDispatcher: any TransactionDispatcher
    let transactionValidator: any ExpressTransactionValidator
    let operationType: ExpressOperationType

    func makeSwapableToken() -> SendSwapableToken {
        let sourceTokenFactory = TangemPaySourceTokenFactory(
            userWalletInfo: userWalletInfo,
            tokenItem: tokenItem,
            feeTokenItem: feeTokenItem,
            defaultAddressString: defaultAddressString,
            availableBalanceProvider: availableBalanceProvider,
            fiatAvailableBalanceProvider: fiatAvailableBalanceProvider,
            cexTransactionDispatcher: cexTransactionDispatcher
        )
        let sourceToken = sourceTokenFactory.makeSourceToken()

        let sendingRestrictionsProvider = TangemPaySendingRestrictionsProvider()
        let receivingRestrictionsProvider = TangemPayReceivingRestrictionsProvider()

        let tokenFeeProvidersManagerProvider = TangemPayTokenFeeProvidersManagerProvider(
            feeTokenItem: feeTokenItem,
            availableTokenBalanceProvider: availableBalanceProvider
        )

        let expressTransactionValidator = transactionValidator

        let balanceProvider = TangemPayExpressBalanceProvider(
            availableBalanceProvider: availableBalanceProvider
        )

        let analyticsLogger = CommonExpressInteractorAnalyticsLogger(
            tokenItem: tokenItem,
            feeAnalyticsParameterBuilder: .init(isFixedFee: false)
        )

        let providerTransactionValidator = TangemPayExpressProviderTransactionValidator()

        let supportedProvidersFilter: SupportedProvidersFilter = switch operationType {
        case .swapAndSend where FeatureProvider.isAvailable(.exchangeOnlyWithinSingleAddress): .byDifferentAddressExchangeSupport
        case .swapAndSend: .cex
        case .swap: .cex
        case .onramp: .cex
        }

        return CommonSendSwapableToken(
            sourceToken: sourceToken,
            isExemptFee: true,
            sendingRestrictionsProvider: sendingRestrictionsProvider,
            receivingRestrictionsProvider: receivingRestrictionsProvider,
            tokenFeeProvidersManagerProvider: tokenFeeProvidersManagerProvider,
            expressTransactionValidator: expressTransactionValidator,
            balanceProvider: balanceProvider,
            analyticsLogger: analyticsLogger,
            providerTransactionValidator: providerTransactionValidator,
            operationType: operationType,
            supportedProvidersFilter: supportedProvidersFilter
        )
    }
}
