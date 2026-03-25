//
//  SendReceiveTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CommonSendReceiveTokenFactory {
    let tokenItem: TokenItem

    func makeSendReceiveToken(destination: SendReceiveTokenDestination? = nil) -> SendReceiveToken {
        let fiatItem = FiatItem(
            iconURL: IconURLBuilder().fiatIconURL(currencyCode: AppSettings.shared.selectedCurrencyCode),
            currencyCode: AppSettings.shared.selectedCurrencyCode,
            fractionDigits: 2
        )

        return CommonSendReceiveToken(
            tokenItem: tokenItem,
            isCustom: false,
            fiatItem: fiatItem,
            destination: destination,
        )
    }
}
