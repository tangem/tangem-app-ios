//
//  TangemPayDestinationWalletWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol ExpressInteractorTangemPayDestinationWallet: ExpressInteractorDestinationWallet {
    var balanceProvider: TokenBalanceProvider { get }
}

struct TangemPayDestinationWalletWrapper: ExpressInteractorTangemPayDestinationWallet {
    let id: WalletModelId
    let tokenItem: TokenItem
    let isCustom: Bool = false
    let balanceProvider: TokenBalanceProvider

    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    let address: String?

    init(tokenItem: TokenItem, address: String, balanceProvider: TokenBalanceProvider) {
        id = .init(tokenItem: tokenItem)
        self.tokenItem = tokenItem
        self.address = address
        self.balanceProvider = balanceProvider
    }
}
