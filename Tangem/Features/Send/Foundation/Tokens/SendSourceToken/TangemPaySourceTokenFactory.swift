//
//  TangemPaySourceTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress
import BlockchainSdk
import TangemStaking
import TangemFoundation

struct TangemPaySourceTokenFactory {
    let userWalletInfo: UserWalletInfo
    let account: (any TangemPayAccountModel)?
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let defaultAddressString: String
    let availableBalanceProvider: any TokenBalanceProvider
    let fiatAvailableBalanceProvider: any TokenBalanceProvider
    let cexTransactionDispatcher: any TransactionDispatcher

    func makeSourceToken() -> SendSourceToken {
        let header = TokenHeaderProvider(
            userWalletName: userWalletInfo.name,
            account: account
        )
        .makeHeader()
        let fiatItem = FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )

        let transactionDispatcherProvider = TangemPayTransactionDispatcherProvider(
            cexTransactionDispatcher: cexTransactionDispatcher
        )

        let emailDataCollectorBuilder = TangemPayEmailDataCollectorBuilder()

        return CommonSendSourceToken(
            userWalletInfo: userWalletInfo,
            id: .init(tokenItem: tokenItem),
            header: header,
            feeTokenItem: feeTokenItem,
            isFixedFee: false,
            isCustom: false,
            defaultAddressString: defaultAddressString,
            availableBalanceProvider: availableBalanceProvider,
            fiatAvailableBalanceProvider: fiatAvailableBalanceProvider,
            allowanceService: nil,
            withdrawalNotificationProvider: nil,
            emailDataCollectorBuilder: emailDataCollectorBuilder,
            transactionDispatcherProvider: transactionDispatcherProvider,
            accountModelAnalyticsProvider: nil,
            tokenItem: tokenItem,
            fiatItem: fiatItem,
            address: defaultAddressString,
            extraId: nil
        )
    }
}
