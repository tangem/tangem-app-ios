//
//  CommonSendTransferableTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CommonSendTransferableTokenFactory {
    let userWalletInfo: UserWalletInfo
    let walletModel: any WalletModel

    func makeTransferableToken(
        balanceType: SendSourceTokenFactoryBalanceType = .available,
        supportingFeeOptions: TokenFeeProviderSupportingOptions = .all
    ) -> SendTransferableToken {
        let sourceTokenFactory = CommonSendSourceTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel
        )
        let sourceToken = sourceTokenFactory.makeSourceToken(balanceType: balanceType)

        let fiatItem = FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )

        // The `tokenFeeProvidersManager` for send with all fee options
        let tokenFeeProvidersManager = CommonTokenFeeProvidersManagerProvider(
            walletModel: walletModel,
            supportingOptions: supportingFeeOptions
        ).makeTokenFeeProvidersManager()

        return CommonSendTransferableToken(
            transactionValidator: BSDKTransactionValidator(transactionValidator: walletModel.transactionValidator),
            transactionCreator: BSDKTransactionCreator(transactionCreator: walletModel.transactionCreator),
            tokenFeeProvidersManager: tokenFeeProvidersManager,
            sourceToken: sourceToken,
            tokenItem: walletModel.tokenItem,
            fiatItem: fiatItem,
            currency: walletModel.tokenItem.expressCurrency,
            coinCurrency: walletModel.feeTokenItem.expressCurrency,
            address: walletModel.defaultAddressString,
            extraId: nil
        )
    }
}
