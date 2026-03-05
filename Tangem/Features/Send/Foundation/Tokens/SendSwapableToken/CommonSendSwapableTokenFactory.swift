//
//  CommonSendSwapableTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

struct CommonSendSwapableTokenFactory {
    let userWalletInfo: UserWalletInfo
    let walletModel: any WalletModel
    let operationType: ExpressOperationType

    func makeSwapableToken() -> SendSwapableToken {
        let sourceTokenFactory = CommonSendSourceTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel
        )
        let sourceToken = sourceTokenFactory.makeSourceToken()

        let sendingRestrictionsProvider = WalletModelSendingRestrictionsProvider(walletModel: walletModel)
        let receivingRestrictionsProvider = WalletModelReceivingRestrictionsProvider(walletModel: walletModel)

        // with `.swap` supportingOptions
        let tokenFeeProvidersManagerProvider = CommonTokenFeeProvidersManagerProvider(
            walletModel: walletModel,
            supportingOptions: .swap
        )

        let expressTransactionValidator = BSDKExpressTransactionValidator(
            transactionValidator: walletModel.transactionValidator
        )

        let balanceProvider = CommonExpressBalanceProvider(
            availableBalanceProvider: walletModel.availableBalanceProvider,
            feeBalanceProvider: walletModel.feeTokenItemBalanceProvider
        )

        let analyticsLogger = CommonExpressAnalyticsLogger(tokenItem: walletModel.tokenItem)

        let providerTransactionValidator = CommonExpressProviderTransactionValidator(
            tokenItem: walletModel.tokenItem,
            hardwareLimitationsUtil: HardwareLimitationsUtil(config: userWalletInfo.config)
        )

        let supportedProvidersFilter: SupportedProvidersFilter = switch operationType {
        case .swapAndSend where FeatureProvider.isAvailable(.exchangeOnlyWithinSingleAddress): .byDifferentAddressExchangeSupport
        case .swapAndSend: .cex
        case .swap: .swap
        case .onramp: .onramp
        }

        return CommonSendSwapableToken(
            sourceToken: sourceToken,
            isExemptFee: false,
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
