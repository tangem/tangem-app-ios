//
//  SwapDestinationWalletWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation

struct SwapDestinationWalletWrapper: ExpressInteractorDestinationWallet {
    let id: WalletModelId
    let userWalletId: UserWalletId
    let tokenItem: TokenItem
    let isCustom: Bool = false
    let tokenHeader: ExpressInteractorTokenHeader?
    let accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?

    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    let address: String?
    let extraId: String?

    init(
        userWalletId: UserWalletId,
        tokenItem: TokenItem,
        address: String?,
        extraId: String?,
        tokenHeader: ExpressInteractorTokenHeader?,
        accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)?
    ) {
        id = .init(tokenItem: tokenItem)
        self.userWalletId = userWalletId
        self.tokenItem = tokenItem
        self.address = address
        self.extraId = extraId
        self.tokenHeader = tokenHeader
        self.accountModelAnalyticsProvider = accountModelAnalyticsProvider
    }
}
