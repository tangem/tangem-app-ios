//
//  SwapDestinationWalletWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct SwapDestinationWalletWrapper: ExpressInteractorDestinationWallet {
    let id: WalletModelId
    let tokenItem: TokenItem
    let isCustom: Bool = false
    let tokenHeader: ExpressInteractorTokenHeader?
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?

    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    let address: String?

    init(
        tokenItem: TokenItem,
        address: String?,
        tokenHeader: ExpressInteractorTokenHeader?,
        accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?
    ) {
        id = .init(tokenItem: tokenItem)
        self.tokenItem = tokenItem
        self.address = address
        self.tokenHeader = tokenHeader
        self.accountModelAnalyticsProvider = accountModelAnalyticsProvider
    }
}
