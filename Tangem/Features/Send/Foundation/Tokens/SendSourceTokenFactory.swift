//
//  SendSourceTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

struct SendSourceTokenFactory {
    let userWalletInfo: UserWalletInfo
    let walletModel: any WalletModel
    let flowType: SendFlowType

    func makeSourceToken() -> SendSourceToken {
        let header = TokenHeaderProvider(
            userWalletName: userWalletInfo.name,
            account: walletModel.account
        ).makeHeader()

        let tokenIconInfo = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )

        let fiatItem = FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )

        let sendingRestrictionsProvider = CommonSendingRestrictionsProvider(walletModel: walletModel)
        let receivingRestrictionsProvider = CommonReceivingRestrictionsProvider(walletModel: walletModel)

        // The `tokenFeeProvidersManager` for send with all fee options
        let tokenFeeProvidersManager = CommonTokenFeeProvidersManagerProvider(walletModel: walletModel)
            .makeTokenFeeProvidersManager()

        // with `.swap` supportingOptions
        let tokenFeeProvidersManagerProvider = CommonTokenFeeProvidersManagerProvider(
            walletModel: walletModel,
            supportingOptions: .swap
        )

        let transactionDispatcherProvider = WalletModelTransactionDispatcherProvider(
            walletModel: walletModel,
            signer: userWalletInfo.signer
        )

        let allowanceService = AllowanceServiceFactory(
            walletModel: walletModel,
            transactionDispatcherProvider: transactionDispatcherProvider
        ).makeAllowanceService()

        let emailDataCollectorBuilder = CommonEmailDataCollectorBuilder(
            walletModel: walletModel,
            emailDataProvider: userWalletInfo.emailDataProvider
        )

        let balanceProvider = CommonExpressBalanceProvider(
            availableBalanceProvider: walletModel.availableBalanceProvider,
            feeProvider: walletModel
        )

        let analyticsLogger = CommonExpressInteractorAnalyticsLogger(
            tokenItem: walletModel.tokenItem,
            feeAnalyticsParameterBuilder: .init(isFixedFee: !walletModel.shouldShowFeeSelector)
        )

        let providerTransactionValidator = CommonExpressProviderTransactionValidator(
            tokenItem: walletModel.tokenItem,
            hardwareLimitationsUtil: HardwareLimitationsUtil(config: userWalletInfo.config)
        )

        let operationType: ExpressOperationType = switch flowType {
        case .send: .swapAndSend
        case .swap: .swap
        case .onramp: .onramp
        // Shouldn't use for `staking`
        case .staking: .swap
        }

        let supportedProvidersFilter: SupportedProvidersFilter = switch flowType {
        case .send where FeatureProvider.isAvailable(.exchangeOnlyWithinSingleAddress): .byDifferentAddressExchangeSupport
        case .send: .cex
        case .swap: .swap
        case .onramp: .onramp
        // Shouldn't use for `staking`
        case .staking: .byTypes([])
        }

        return CommonSendSourceToken(
            userWalletInfo: userWalletInfo,
            id: walletModel.id,
            header: header,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            isExemptFee: false,
            isFixedFee: !walletModel.shouldShowFeeSelector,
            tokenIconInfo: tokenIconInfo,
            fiatItem: fiatItem,
            isCustom: walletModel.isCustom,
            availableBalanceProvider: walletModel.availableBalanceProvider,
            fiatAvailableBalanceProvider: walletModel.fiatAvailableBalanceProvider,
            allowanceService: allowanceService,
            emailDataCollectorBuilder: emailDataCollectorBuilder,
            defaultAddressString: walletModel.defaultAddressString,
            transactionValidator: walletModel.transactionValidator,
            transactionCreator: walletModel.transactionCreator,
            withdrawalNotificationProvider: walletModel.withdrawalNotificationProvider,
            tokenFeeProvidersManager: tokenFeeProvidersManager,
            sendingRestrictionsProvider: sendingRestrictionsProvider,
            receivingRestrictionsProvider: receivingRestrictionsProvider,
            tokenFeeProvidersManagerProvider: tokenFeeProvidersManagerProvider,
            transactionDispatcherProvider: transactionDispatcherProvider,
            accountModelAnalyticsProvider: walletModel.account,
            balanceProvider: balanceProvider,
            analyticsLogger: analyticsLogger,
            operationType: operationType,
            supportedProvidersFilter: supportedProvidersFilter,
            providerTransactionValidator: providerTransactionValidator
        )
    }
}
