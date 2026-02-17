////
////  SwapSourceTokenFactory.swift
////  TangemApp
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2026 Tangem AG. All rights reserved.
////
//
// import BlockchainSdk
// import TangemUI
// import TangemExpress
//
// struct SwapSourceTokenFactory {
//    let userWalletInfo: UserWalletInfo
//    let walletModel: any WalletModel
//
//    func makeSourceToken(tokenHeaderProvider: SendGenericTokenHeaderProvider) -> SwapSourceToken {
//        let header = tokenHeaderProvider.makeSendTokenHeader()
//        let tokenIconInfo = TokenIconInfoBuilder().build(
//            from: walletModel.tokenItem,
//            isCustom: walletModel.isCustom
//        )
//
//        let fiatItem = FiatItem(
//            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
//            currencyCode: AppSettings.shared.selectedCurrencyCode,
//            fractionDigits: 2
//        )
//
//        let possibleToConvertToFiat = walletModel.fiatAvailableBalanceProvider.balanceType.value != .none
//
//        let tokenFeeProvidersManagerProvider = CommonTokenFeeProvidersManagerProvider(walletModel: walletModel)
//        let transactionDispatcherProvider = WalletModelTransactionDispatcherProvider(
//            walletModel: walletModel,
//            signer: userWalletInfo.signer
//        )
//
//        let allowanceService = AllowanceServiceFactory(
//            walletModel: walletModel,
//            transactionDispatcherProvider: transactionDispatcherProvider
//        ).makeAllowanceService()
//
//        let balanceProvider = CommonExpressBalanceProvider(
//            availableBalanceProvider: walletModel.availableBalanceProvider,
//            feeProvider: walletModel
//        )
//
//        let analyticsLogger = CommonExpressInteractorAnalyticsLogger(
//            tokenItem: walletModel.tokenItem,
//            feeAnalyticsParameterBuilder: .init(isFixedFee: !walletModel.shouldShowFeeSelector)
//        )
//
//        return CommonSwapSourceToken(
//            userWalletInfo: userWalletInfo,
//            id: walletModel.id,
//            header: header,
//            tokenItem: walletModel.tokenItem,
//            feeTokenItem: walletModel.feeTokenItem,
//            tokenIconInfo: tokenIconInfo,
//            fiatItem: fiatItem,
//            isCustom: walletModel.isCustom,
//            possibleToConvertToFiat: possibleToConvertToFiat,
//            availableBalanceProvider: walletModel.availableBalanceProvider,
//            fiatAvailableBalanceProvider: walletModel.fiatAvailableBalanceProvider,
//            defaultAddressString: walletModel.defaultAddressString,
//            transactionValidator: walletModel.transactionValidator,
//            transactionCreator: walletModel.transactionCreator,
//            withdrawalNotificationProvider: walletModel.withdrawalNotificationProvider,
//            tokenFeeProvidersManager: tokenFeeProvidersManagerProvider.makeTokenFeeProvidersManager(), analyticsLogger: analyticsLogger,
//            operationType: .swap,
//            supportedProvidersFilter: .swap,
//            allowanceService: allowanceService,
//            balanceProvider: balanceProvider,
//            tokenFeeProvidersManagerProvider: tokenFeeProvidersManagerProvider,
//            transactionDispatcherProvider: transactionDispatcherProvider,
//            accountModelAnalyticsProvider: walletModel.account
//        )
//    }
// }
