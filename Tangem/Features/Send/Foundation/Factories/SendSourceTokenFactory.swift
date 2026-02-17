//
//  SendSourceTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct SendSourceTokenFactory {
    let userWalletInfo: UserWalletInfo
    let walletModel: any WalletModel

    func makeSourceToken(tokenHeaderProvider: SendGenericTokenHeaderProvider) -> SendSourceToken {
        let header = tokenHeaderProvider.makeSendTokenHeader()
        let tokenIconInfo = TokenIconInfoBuilder().build(
            from: walletModel.tokenItem,
            isCustom: walletModel.isCustom
        )

        let fiatItem = FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )

        let possibleToConvertToFiat = walletModel.fiatAvailableBalanceProvider.balanceType.value != .none

        let tokenFeeProvidersManagerProvider = CommonTokenFeeProvidersManagerProvider(walletModel: walletModel)
        let transactionDispatcherProvider = WalletModelTransactionDispatcherProvider(
            walletModel: walletModel,
            signer: userWalletInfo.signer
        )

        return CommonSendSourceToken(
            userWalletInfo: userWalletInfo,
            id: walletModel.id,
            header: header,
            tokenItem: walletModel.tokenItem,
            feeTokenItem: walletModel.feeTokenItem,
            isCustom: walletModel.isCustom,
            tokenIconInfo: tokenIconInfo,
            fiatItem: fiatItem,
            possibleToConvertToFiat: possibleToConvertToFiat,
            availableBalanceProvider: walletModel.availableBalanceProvider,
            fiatAvailableBalanceProvider: walletModel.fiatAvailableBalanceProvider,
            defaultAddressString: walletModel.defaultAddressString,
            transactionValidator: walletModel.transactionValidator,
            transactionCreator: walletModel.transactionCreator,
            withdrawalNotificationProvider: walletModel.withdrawalNotificationProvider,
            tokenFeeProvidersManager: tokenFeeProvidersManagerProvider.makeTokenFeeProvidersManager(),
            tokenFeeProvidersManagerProvider: tokenFeeProvidersManagerProvider,
            transactionDispatcherProvider: transactionDispatcherProvider,
            accountModelAnalyticsProvider: walletModel.account
        )
    }
}
