//
//  CommonSendSwapableTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import TangemExpress

protocol SendSwapableTokenFactory {
    func makeSwapableToken() -> SendSwapableToken
}

struct CommonSendSwapableTokenFactory: SendSwapableTokenFactory {
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

        let swapTokenFeeProvidersManagerProvider = WalletModelTokenFeeProvidersManagerProvider(
            walletModel: walletModel,
            supportingOptions: .swap
        )

        let transferTokenFeeProvidersManager = WalletModelTokenFeeProvidersManagerProvider(
            walletModel: walletModel,
            supportingOptions: .all
        ).makeTokenFeeProvidersManager()

        let transactionValidator = SendTransactionValidatorFactory(
            blockchain: walletModel.tokenItem.blockchain,
            transactionValidator: walletModel.transactionValidator
        ).makeValidator()

        let transactionCreator = BSDKTransactionCreator(
            transactionCreator: walletModel.transactionCreator
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

        let swapAvailabilityProvider = CommonSwapAvailabilityProvider(
            tokenItem: walletModel.tokenItem,
            userWalletConfig: userWalletInfo.config
        )

        let sendYieldModuleHelper = makeSendYieldModuleHelper()
        let supportedProvidersFilter = makeSupportedProvidersFilter()

        return CommonSendSwapableToken(
            sourceToken: sourceToken,
            isExemptFee: false,
            swapAvailabilityProvider: swapAvailabilityProvider,
            sendingRestrictionsProvider: sendingRestrictionsProvider,
            tokenFeeProvidersManagerProvider: swapTokenFeeProvidersManagerProvider,
            tokenFeeProvidersManager: transferTokenFeeProvidersManager,
            transactionValidator: transactionValidator,
            transactionCreator: transactionCreator,
            sendYieldModuleHelper: sendYieldModuleHelper,
            balanceProvider: balanceProvider,
            analyticsLogger: analyticsLogger,
            providerTransactionValidator: providerTransactionValidator,
            operationType: operationType,
            supportedProvidersFilter: supportedProvidersFilter
        )
    }
}

private extension CommonSendSwapableTokenFactory {
    func makeSupportedProvidersFilter() -> SupportedProvidersFilter {
        return switch operationType {
        case .swapAndSend where FeatureProvider.isAvailable(.exchangeOnlyWithinSingleAddress): .byDifferentAddressExchangeSupport
        case .swapAndSend: .cex
        case .swap: .swap
        case .onramp: .onramp
        }
    }

    func makeSendYieldModuleHelper() -> SendYieldModuleHelper? {
        guard walletModel.yieldModuleManager?.state?.state.isEffectivelyActive == true,
              let yieldContractAddress = walletModel.yieldModuleManager?.state?.state.activeInfo?.yieldContractAddress
        else {
            return nil
        }

        return CommonSendYieldModuleHelper(
            yieldContractAddress: yieldContractAddress,
            currency: walletModel.tokenItem.expressCurrency,
            swapExecutionRegistryProvider: walletModel.yieldModuleManager?.swapExecutionRegistryProvider,
            yieldModuleUpgradeHandler: makeYieldModuleUpgradeHandler()
        )
    }

    func makeYieldModuleUpgradeHandler() -> YieldModuleUpgradeHandler? {
        guard walletModel.yieldModuleManager?.state?.state.isEffectivelyActive == true,
              let versionChecker = walletModel.yieldModuleManager?.versionChecker,
              let yieldModuleAddress = walletModel.yieldModuleManager?.state?.state.activeInfo?.yieldContractAddress
        else {
            return nil
        }

        return CommonYieldModuleUpgradeHandler(
            versionChecker: versionChecker,
            yieldModuleAddress: yieldModuleAddress
        )
    }
}
