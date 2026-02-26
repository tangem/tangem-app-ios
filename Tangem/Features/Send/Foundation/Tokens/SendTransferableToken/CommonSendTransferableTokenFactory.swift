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

    func makeTransferableToken() -> SendTransferableToken {
        let sourceTokenFactory = CommonSendSourceTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel
        )
        let sourceToken = sourceTokenFactory.makeSourceToken()

        let fiatItem = FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )

        // The `tokenFeeProvidersManager` for send with all fee options
        let tokenFeeProvidersManager = CommonTokenFeeProvidersManagerProvider(walletModel: walletModel)
            .makeTokenFeeProvidersManager()

        return CommonSendTransferableToken(
            transactionValidator: walletModel.transactionValidator,
            transactionCreator: walletModel.transactionCreator,
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
