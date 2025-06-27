//
//  SwapManagerDestinationWallet.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemExpress

struct SwapManagerDestinationWallet: ExpressInteractorDestinationWallet {
    let id: WalletModelId
    let isCustom: Bool
    let currency: TangemExpress.ExpressWalletCurrency
    let tokenItem: TokenItem
    let address: String?

    init(tokenItem: TokenItem, address: String?) {
        id = .init(tokenItem: tokenItem)
        isCustom = false
        currency = tokenItem.expressCurrency

        self.tokenItem = tokenItem
        self.address = address
    }
}
